---
description: Run all audits (analyze, performance, accessibility, security, platform) and produce unified report
allowed-tools: Bash(flutter analyze:*), Bash(wc:*), Grep, Glob, Read
---

# Full Audit — All Checks

Run all audit commands in sequence and produce a unified summary report. This is the comprehensive quality gate for the Flutter mobile app.

## Steps

Execute each audit category below, collecting findings into a unified report.

### Phase 1: Static Analysis

Run `flutter analyze` in the `mobile/` directory and report errors/warnings.

### Phase 2: Performance Audit

Check for performance anti-patterns:
1. `ListView(` without `.builder` — Grep for `ListView(` with `children:` in `mobile/lib/`
2. `Container(` that should be `SizedBox` — Grep for Container with only width/height
3. `Opacity(` widget — Grep for `Opacity(` (triggers saveLayer)
4. `IntrinsicHeight`/`IntrinsicWidth` in scrollable contexts
5. `Image.network(` without caching — should use `CachedNetworkImage`
6. Missing `const` on literal widgets — `Text('...')`, `SizedBox(...)`, `Icon(Icons....)` without const

### Phase 3: Accessibility Audit

Check accessibility compliance:
1. `IconButton(` without `tooltip:` — Grep in `mobile/lib/`
2. `GestureDetector(` or `InkWell(` without `Semantics` wrapper
3. Hardcoded sizes below 44 on interactive elements
4. Images without `semanticLabel:`
5. Dark mode status — read `app_theme.dart`

### Phase 4: Security Audit

Scan for security issues:
1. Hardcoded secrets — Grep for `apiKey =`, `token =`, `password =`, `secret =`, `sk_live_`, `sk_test_`, `AIza` in `mobile/lib/`
2. Insecure HTTP URLs — Grep for `http://` (excluding localhost/10.0.2.2/127.0.0.1)
3. `print(` or `debugPrint(` statements — count in `mobile/lib/` (excluding test)
4. Sensitive data in SharedPreferences — check what's stored
5. `.gitignore` coverage — check for `.env`, keystores, credentials

### Phase 5: Platform Compliance

Check iOS HIG and Material Design:
1. Material 3 enabled — read `app_theme.dart` for `useMaterial3: true`
2. Deprecated Material 2 widgets — Grep for `RaisedButton`, `FlatButton`, `OutlineButton`
3. Font sizes — verify body text >= 16pt in theme
4. 8dp grid compliance — check spacing values in `app_spacing.dart`
5. Navigation pattern — check bottom nav tab count (3-5 required)
6. Platform-adaptive widgets — Grep for `Platform.isIOS`, `.adaptive`

### Phase 6: Unified Report

Compile all findings into this format:

```
# Full Audit Report — Szybka Fucha Mobile
Date: [current date]

## Summary Dashboard
| Category        | Critical | Warning | Info | Score |
|----------------|----------|---------|------|-------|
| Static Analysis | X        | X       | X    | X/10  |
| Performance     | X        | X       | X    | X/10  |
| Accessibility   | X        | X       | X    | X/10  |
| Security        | X        | X       | X    | X/10  |
| Platform        | X        | X       | X    | X/10  |
| **TOTAL**       | **X**    | **X**   | **X**| **X/50** |

## Critical Issues (must fix)
1. [issue] — [file:line] — [fix suggestion]
2. ...

## Warnings (should fix)
1. [issue] — [file:line] — [fix suggestion]
2. ...

## Info (consider)
1. [issue] — [file:line] — [suggestion]
2. ...

## Top 5 Priority Fixes
1. [most impactful fix]
2. ...

## Scores Explanation
- 10/10: No issues
- 8-9/10: Minor improvements possible
- 5-7/10: Several issues need attention
- <5/10: Significant work needed
```
