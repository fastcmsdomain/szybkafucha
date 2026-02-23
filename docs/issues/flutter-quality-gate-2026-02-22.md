# Flutter Quality Gate – Run Note

**Date:** 2026-02-22  
**Script:** `./mobile/scripts/flutter_quality_gate.sh`

## Summary

The quality gate was run from the repo root. **No Dart files were checked** and **no quality findings** were recorded because of environment/scope limitations.

## What was run

1. **Default run** (scope: changed)  
   - Command: `./mobile/scripts/flutter_quality_gate.sh`  
   - Result: *No Dart files selected for quality gate.*  
   - Reason: With `--scope changed`, the script only considers modified/untracked files under `mobile/lib`. There were no such files in this run.

2. **Full codebase run** (scope: all)  
   - Command: `./mobile/scripts/flutter_quality_gate.sh --scope all`  
   - Result: Script failed before running checks.  
   - Error: `rg: command not found` (line 87).  
   - Reason: The script uses **ripgrep** (`rg`) to collect Dart files. `rg` was not available in the environment where the script was executed.

## Requirements

- **ripgrep** is required for the script to discover files.  
  Install: `brew install ripgrep` (macOS) or equivalent on your OS.

## Recommendations

1. Install ripgrep so the script can run in your environment.
2. Run the gate locally with full scope to get real findings:
   - `./mobile/scripts/flutter_quality_gate.sh --scope all`
3. When the script reports **violations** or **flutter analyze** fails, add a new note under `docs/issues/` (e.g. `flutter-quality-gate-findings-YYYY-MM-DD.md`) listing:
   - Custom check violations (naming, theme tokens, etc.)
   - Custom warnings (e.g. large `build()` methods)
   - Any `flutter analyze` errors/warnings

## Script reference

- Path: `mobile/scripts/flutter_quality_gate.sh`
- Checks: filename snake_case, no hardcoded `Color(...)`/`Colors.*`/`GoogleFonts.*` outside theme, `build()` size ~100 lines, then `flutter analyze` on selected files.
- Options: `--scope changed|last-commit|all`, `--skip-analyze`, optional file/dir paths.
