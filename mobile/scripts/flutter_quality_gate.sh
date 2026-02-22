#!/usr/bin/env bash

set -euo pipefail

print_usage() {
  cat <<'EOF'
Usage:
  mobile/scripts/flutter_quality_gate.sh [--scope changed|last-commit|all] [--skip-analyze] [paths...]

Examples:
  mobile/scripts/flutter_quality_gate.sh
  mobile/scripts/flutter_quality_gate.sh --scope last-commit
  mobile/scripts/flutter_quality_gate.sh --skip-analyze
  mobile/scripts/flutter_quality_gate.sh lib/features/profile/screens/notifications_preferences_screen.dart
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MOBILE_DIR/.." && pwd)"

if [[ ! -f "$MOBILE_DIR/pubspec.yaml" ]]; then
  die "Could not locate mobile/pubspec.yaml"
fi

scope="changed"
skip_analyze=0
declare -a input_paths=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      [[ $# -gt 1 ]] || die "--scope requires a value"
      scope="$2"
      shift 2
      ;;
    --skip-analyze)
      skip_analyze=1
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      input_paths+=("$1")
      shift
      ;;
  esac
done

case "$scope" in
  changed|last-commit|all) ;;
  *) die "Unsupported scope '$scope'. Use: changed | last-commit | all" ;;
esac

if [[ $skip_analyze -eq 0 ]] && ! command -v flutter >/dev/null 2>&1; then
  die "flutter is not installed or not in PATH"
fi

collect_files_from_paths() {
  local base="$1"
  shift
  local p
  for p in "$@"; do
    if [[ -d "$base/$p" ]]; then
      rg --files "$base/$p" -g "*.dart" || true
    elif [[ -f "$base/$p" && "$p" == *.dart ]]; then
      echo "$base/$p"
    fi
  done
}

declare -a absolute_files=()

if [[ ${#input_paths[@]} -gt 0 ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    absolute_files+=("$line")
  done < <(collect_files_from_paths "$REPO_ROOT" "${input_paths[@]}")
else
  case "$scope" in
    all)
      while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        absolute_files+=("$line")
      done < <(cd "$MOBILE_DIR" && rg --files lib -g "*.dart")
      # Prefix full path for all files
      absolute_files=("${absolute_files[@]/#/$MOBILE_DIR/}")
      ;;
    last-commit)
      while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        absolute_files+=("$line")
      done < <(
        git -C "$REPO_ROOT" log -1 --name-only --pretty=format: \
          | rg '^mobile/lib/.*\.dart$' \
          | sed "s#^mobile/#$MOBILE_DIR/#"
      )
      ;;
    changed)
      while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        absolute_files+=("$line")
      done < <(
        {
          git -C "$REPO_ROOT" diff --name-only --diff-filter=ACMRTUXB HEAD -- mobile/lib '*.dart'
          git -C "$REPO_ROOT" ls-files --others --exclude-standard -- mobile/lib '*.dart'
        } | sort -u | sed "s#^mobile/#$MOBILE_DIR/#"
      )
      ;;
  esac
fi

if [[ ${#absolute_files[@]} -eq 0 ]]; then
  echo "No Dart files selected for quality gate."
  exit 0
fi

declare -a files=()
for abs in "${absolute_files[@]}"; do
  [[ -f "$abs" ]] || continue
  rel="${abs#"$MOBILE_DIR/"}"
  [[ "$rel" == lib/* ]] || continue
  files+=("$rel")
done

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No matching files under mobile/lib selected for quality gate."
  exit 0
fi

echo "Flutter Quality Gate"
echo "Scope: $scope"
echo "Files (${#files[@]}):"
for f in "${files[@]}"; do
  echo "  - $f"
done
echo

declare -a violations=()
declare -a warnings=()

add_violation() {
  violations+=("$1")
}

add_warning() {
  warnings+=("$1")
}

is_theme_file() {
  [[ "$1" == lib/core/theme/* ]]
}

check_naming() {
  local file="$1"
  local base
  base="$(basename "$file")"
  if [[ ! "$base" =~ ^[a-z0-9_]+\.dart$ ]]; then
    add_violation "$file: filename should be snake_case"
  fi
}

check_theme_tokens() {
  local file="$1"
  if is_theme_file "$file"; then
    return
  fi

  while IFS= read -r line; do
    add_violation "$line: avoid hardcoded Color(...) - use AppColors/theme token"
  done < <(rg -n "\\bColor\\(" "$MOBILE_DIR/$file" || true)

  while IFS= read -r line; do
    add_violation "$line: avoid Colors.* - use AppColors/theme token"
  done < <(rg -n "\\bColors\\." "$MOBILE_DIR/$file" || true)

  while IFS= read -r line; do
    add_violation "$line: avoid direct GoogleFonts usage outside theme layer"
  done < <(rg -n "GoogleFonts\\." "$MOBILE_DIR/$file" || true)
}

check_build_size() {
  local file="$1"
  local result
  result="$(
    awk '
      /Widget[[:space:]]+build[[:space:]]*\(/ {
        tracking=1
        seenBrace=0
        brace=0
        start=NR
      }
      tracking {
        line=$0
        opens=gsub(/{/, "{", line)
        closes=gsub(/}/, "}", line)
        if (opens > 0) seenBrace=1
        if (seenBrace) {
          brace += opens - closes
          if (brace == 0) {
            len=NR-start+1
            if (len > 100) {
              printf "%d:%d:%d\n", start, NR, len
            }
            tracking=0
            seenBrace=0
            brace=0
          }
        }
      }
    ' "$MOBILE_DIR/$file"
  )"

  if [[ -n "$result" ]]; then
    while IFS= read -r match; do
      add_warning "$file:$match build() exceeds ~100 lines; extract sub-widgets/helpers"
    done <<< "$result"
  fi
}

for file in "${files[@]}"; do
  check_naming "$file"
  check_theme_tokens "$file"
  check_build_size "$file"
done

analyze_exit=0
if [[ $skip_analyze -eq 0 ]]; then
  echo "Running flutter analyze..."
  analyze_output_file="$(mktemp)"
  (
    cd "$MOBILE_DIR"
    flutter analyze "${files[@]}"
  ) >"$analyze_output_file" 2>&1 || analyze_exit=$?
  cat "$analyze_output_file"
  rm -f "$analyze_output_file"
else
  echo "Skipping flutter analyze (--skip-analyze)."
fi

echo
echo "Quality Gate Summary"
if [[ ${#violations[@]} -gt 0 ]]; then
  echo "Custom checks: FAIL (${#violations[@]} issues)"
  for v in "${violations[@]}"; do
    echo "  - $v"
  done
else
  echo "Custom checks: PASS"
fi

if [[ ${#warnings[@]} -gt 0 ]]; then
  echo "Custom warnings: ${#warnings[@]}"
  for w in "${warnings[@]}"; do
    echo "  - $w"
  done
fi

if [[ $skip_analyze -eq 1 ]]; then
  echo "flutter analyze: SKIPPED"
elif [[ $analyze_exit -eq 0 ]]; then
  echo "flutter analyze: PASS"
else
  echo "flutter analyze: FAIL"
fi

if [[ ${#violations[@]} -gt 0 || $analyze_exit -ne 0 ]]; then
  exit 1
fi

echo "Overall: PASS"
