---
description: Run Flutter static analysis + enhanced code quality checks
allowed-tools: Bash(flutter analyze:*), Bash(wc:*), Grep, Glob, Read
---

# Flutter Analyze + Code Quality

Run comprehensive static analysis on the Flutter mobile app. This goes beyond `flutter analyze` to check naming conventions, widget organization, and code complexity.

## Steps

### 1. Run Flutter Analyze

Run `flutter analyze` in the `mobile/` directory:

```
cd mobile && flutter analyze
```

Report any errors, warnings, or info messages.

### 2. Check Naming Conventions

**File names must be snake_case:**
Use Glob to find all `.dart` files in `mobile/lib/`. Flag any files that contain uppercase letters or hyphens in their filename (excluding path separators).

**Class names must be UpperCamelCase:**
Use Grep to search for `class\s+[a-z]` in `.dart` files - these are classes starting with lowercase.

### 3. Check Widget Organization

**Large files (>300 lines):**
Use Bash with `wc -l` to find `.dart` files exceeding 300 lines. These are candidates for splitting into smaller widgets.

**Business logic in build() methods:**
Use Grep to search for these patterns inside `build()` methods in `.dart` files:
- `setState(` — should be in separate methods, not inline
- `await ` inside build — async work should not happen in build
- `http` or `api` calls inside build methods

### 4. Check const Constructor Usage

Use Grep to find widget classes that extend `StatelessWidget` but don't have a `const` constructor. Search for:
- Pattern: `class \w+ extends StatelessWidget` — find all stateless widgets
- Then check if the corresponding constructor has `const` keyword

### 5. Check Theme Token Usage

Search for hardcoded values that should use theme tokens:
- Grep for `Color(0x` or `Colors.` (should use `AppColors.` instead)
- Grep for `FontWeight.` without `AppTypography` or theme reference nearby
- Grep for `EdgeInsets.all(` with raw numbers (should use `AppSpacing.`)
- Grep for `BorderRadius.circular(` with raw numbers (should use `AppRadius.`)

**Exclude** `core/theme/` directory from these checks (that's where tokens are defined).

### 6. Report Summary

Produce a clear summary organized by severity:

```
## Flutter Analyze Results
[flutter analyze output]

## Code Quality Findings

### CRITICAL (must fix)
- [naming violations, build() logic issues]

### WARNING (should fix)
- [large files, missing const constructors]

### INFO (consider)
- [hardcoded values that could use theme tokens]

### Stats
- Total .dart files scanned: X
- Files with issues: X
- Clean files: X
```
