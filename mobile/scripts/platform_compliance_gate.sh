#!/usr/bin/env bash

set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage:
  mobile/scripts/platform_compliance_gate.sh [--scope changed|last-commit|all] [--skip-analyze] [paths...]

Default scope checks changed screen files under mobile/lib/features/*/screens/*.dart.

Examples:
  mobile/scripts/platform_compliance_gate.sh
  mobile/scripts/platform_compliance_gate.sh --scope last-commit
  mobile/scripts/platform_compliance_gate.sh --scope all
  mobile/scripts/platform_compliance_gate.sh --skip-analyze
  mobile/scripts/platform_compliance_gate.sh mobile/lib/features/profile/screens
USAGE
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

is_less_than() {
  awk -v a="$1" -v b="$2" 'BEGIN { exit !((a + 0) < (b + 0)) }'
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
      done < <(rg --files "$MOBILE_DIR/lib/features" -g "**/screens/*.dart")
      ;;
    last-commit)
      while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        absolute_files+=("$line")
      done < <(
        git -C "$REPO_ROOT" log -1 --name-only --pretty=format: \
          | rg '^mobile/lib/features/.*/screens/.*\.dart$' \
          | sed "s#^mobile/#$MOBILE_DIR/#"
      )
      ;;
    changed)
      while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        absolute_files+=("$line")
      done < <(
        {
          git -C "$REPO_ROOT" diff --name-only --diff-filter=ACMRTUXB HEAD -- mobile/lib/features
          git -C "$REPO_ROOT" ls-files --others --exclude-standard -- mobile/lib/features
        } | rg '^mobile/lib/features/.*/screens/.*\.dart$' \
          | sort -u \
          | sed "s#^mobile/#$MOBILE_DIR/#"
      )
      ;;
  esac
fi

if [[ ${#absolute_files[@]} -eq 0 ]]; then
  echo "No Dart files selected for platform compliance check."
  exit 0
fi

declare -a deduped_absolute_files=()
while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  deduped_absolute_files+=("$line")
done < <(printf "%s\n" "${absolute_files[@]}" | sort -u)
absolute_files=("${deduped_absolute_files[@]}")

declare -a files=()
for abs in "${absolute_files[@]}"; do
  [[ -f "$abs" ]] || continue
  rel="${abs#"$MOBILE_DIR/"}"
  [[ "$rel" == lib/* ]] || continue
  files+=("$rel")
done

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No matching files under mobile/lib selected for platform compliance check."
  exit 0
fi

echo "Platform Compliance Gate"
echo "Scope: $scope"
echo "Files (${#files[@]}):"
for f in "${files[@]}"; do
  echo "  - $f"
done
echo

declare -a errors=()
declare -a warnings=()

add_error() {
  errors+=("$1")
}

add_warning() {
  warnings+=("$1")
}

is_theme_file() {
  [[ "$1" == lib/core/theme/* ]]
}

check_colors() {
  local file="$1"
  is_theme_file "$file" && return

  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    add_error "$file:$hit hardcoded Color(...) is not allowed; use AppColors/theme token"
  done < <(rg -n "\\bColor\\(" "$MOBILE_DIR/$file" || true)

  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    add_error "$file:$hit Colors.* is not allowed; use AppColors/theme token"
  done < <(rg -n "\\bColors\\." "$MOBILE_DIR/$file" || true)
}

check_typography() {
  local file="$1"
  is_theme_file "$file" && return

  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    local line_no text value
    line_no="${hit%%:*}"
    text="${hit#*:}"
    value="$(printf '%s\n' "$text" | sed -E 's/.*fontSize:[[:space:]]*([0-9]+(\.[0-9]+)?).*/\1/')"

    if [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      if is_less_than "$value" 11; then
        add_error "$file:$line_no fontSize $value is below 11 (minimum accessibility floor)"
      elif is_less_than "$value" 16; then
        add_warning "$file:$line_no fontSize $value is below 16; ensure this is only secondary/caption text"
      fi
    fi
  done < <(rg -n "fontSize:[[:space:]]*[0-9]+(\\.[0-9]+)?" "$MOBILE_DIR/$file" || true)

  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    add_warning "$file:$hit direct TextStyle() found; prefer Theme.of(context).textTheme or AppTypography"
  done < <(rg -n "\\bTextStyle\\(" "$MOBILE_DIR/$file" || true)
}

check_spacing() {
  local file="$1"

  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    local line_no text
    line_no="${hit%%:*}"
    text="${hit#*:}"
    if [[ "$text" == *"AppSpacing."* ]]; then
      continue
    fi
    if printf '%s\n' "$text" | rg -q '(^|[^[:alnum:]_])[0-9]+(\.[0-9]+)?([^[:alnum:]_]|$)'; then
      add_warning "$file:$line_no raw EdgeInsets number found; use AppSpacing tokens"
    fi
  done < <(rg -n "EdgeInsets\\.(all|symmetric|only)\\(" "$MOBILE_DIR/$file" || true)

  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    add_warning "$file:$hit raw SizedBox dimension found; prefer AppSpacing for layout gaps"
  done < <(rg -n "SizedBox\\((height|width):[[:space:]]*[0-9]+(\\.[0-9]+)?" "$MOBILE_DIR/$file" || true)
}

check_iconbutton_tooltip() {
  local file="$1"
  local missing

  missing="$(
    awk '
      function count_char(str, ch,    i, c) {
        c = 0
        for (i = 1; i <= length(str); i++) {
          if (substr(str, i, 1) == ch) {
            c++
          }
        }
        return c
      }

      {
        if (!in_block && $0 ~ /IconButton[[:space:]]*\(/) {
          in_block = 1
          depth = 0
          start = NR
          block = $0
          depth += count_char($0, "(") - count_char($0, ")")

          if (depth <= 0) {
            if (block !~ /tooltip[[:space:]]*:/) {
              print start
            }
            in_block = 0
            block = ""
          }
          next
        }

        if (in_block) {
          block = block "\n" $0
          depth += count_char($0, "(") - count_char($0, ")")

          if (depth <= 0) {
            if (block !~ /tooltip[[:space:]]*:/) {
              print start
            }
            in_block = 0
            block = ""
          }
        }
      }
    ' "$MOBILE_DIR/$file"
  )"

  while IFS= read -r line_no; do
    [[ -n "$line_no" ]] || continue
    add_error "$file:$line_no IconButton without tooltip; add tooltip for accessibility"
  done <<< "$missing"
}

check_semantics_for_custom_taps() {
  local file="$1"

  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    local line_no start context
    line_no="${hit%%:*}"
    start=$((line_no - 3))
    if [[ $start -lt 1 ]]; then
      start=1
    fi

    context="$(sed -n "${start},${line_no}p" "$MOBILE_DIR/$file")"
    if ! printf '%s\n' "$context" | rg -q "Semantics\\("; then
      add_warning "$file:$line_no custom tap handler (GestureDetector/InkWell) without nearby Semantics wrapper"
    fi
  done < <(rg -n "\\b(GestureDetector|InkWell)\\(" "$MOBILE_DIR/$file" || true)
}

check_touch_target_hints() {
  local file="$1"

  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    local line_no text value
    line_no="${hit%%:*}"
    text="${hit#*:}"
    value="$(printf '%s\n' "$text" | sed -E 's/.*(height|width):[[:space:]]*([0-9]+(\.[0-9]+)?).*/\2/')"

    if [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]] && is_less_than "$value" 44; then
      add_warning "$file:$line_no dimension $value is below 44; verify interactive targets meet iOS/Android minimum"
    fi
  done < <(rg -n "SizedBox\\([^)]*(height|width):[[:space:]]*[0-9]+(\\.[0-9]+)?" "$MOBILE_DIR/$file" || true)
}

check_project_level_rules() {
  local theme_file="$MOBILE_DIR/lib/core/theme/app_theme.dart"

  if [[ ! -f "$theme_file" ]]; then
    add_error "lib/core/theme/app_theme.dart missing"
  else
    if ! rg -q "useMaterial3:[[:space:]]*true" "$theme_file"; then
      add_error "lib/core/theme/app_theme.dart useMaterial3 is not set to true"
    fi

    if ! rg -q "ColorScheme\\.fromSeed" "$theme_file"; then
      add_warning "lib/core/theme/app_theme.dart does not use ColorScheme.fromSeed()"
    fi
  fi

  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    add_error "$hit legacy Material 2 API found; migrate to Material 3 equivalent"
  done < <(rg -n "\\b(RaisedButton|FlatButton|OutlineButton|ButtonTheme|accentColor)\\b" "$MOBILE_DIR/lib" || true)
}

check_project_level_rules

for file in "${files[@]}"; do
  check_colors "$file"
  check_typography "$file"
  check_spacing "$file"
  check_iconbutton_tooltip "$file"
  check_semantics_for_custom_taps "$file"
  check_touch_target_hints "$file"
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
echo "Platform Compliance Summary"
if [[ ${#errors[@]} -gt 0 ]]; then
  echo "Errors: ${#errors[@]}"
  for item in "${errors[@]}"; do
    echo "  - $item"
  done
else
  echo "Errors: 0"
fi

if [[ ${#warnings[@]} -gt 0 ]]; then
  echo "Warnings: ${#warnings[@]}"
  for item in "${warnings[@]}"; do
    echo "  - $item"
  done
else
  echo "Warnings: 0"
fi

if [[ $skip_analyze -eq 1 ]]; then
  echo "flutter analyze: SKIPPED"
elif [[ $analyze_exit -eq 0 ]]; then
  echo "flutter analyze: PASS"
else
  echo "flutter analyze: FAIL"
fi

if [[ ${#errors[@]} -gt 0 || $analyze_exit -ne 0 ]]; then
  echo "Overall: FAIL"
  exit 1
fi

echo "Overall: PASS"
