---
description: Check accessibility compliance (WCAG 2.1 AA, iOS HIG, Material Design)
allowed-tools: Grep, Glob, Read
---

# Accessibility Audit

Scan the Flutter codebase for accessibility issues based on WCAG 2.1 Level AA, Apple HIG, and Material Design guidelines.

Reference: `tasks/development-guidelines-ios-android-flutter (1).md`

## Steps

### 1. Semantics Labels

**Find interactive widgets without Semantics:**
Search for interactive widgets in `mobile/lib/` that lack `Semantics` wrapper or `semanticLabel` property:

- `IconButton(` — check if it has `tooltip:` or is wrapped in `Semantics`
- `GestureDetector(` — check if wrapped in `Semantics` with `label:`
- `InkWell(` — check if has `Semantics` wrapper
- `FloatingActionButton(` — check if has `tooltip:`

**Custom sf_ widgets:**
Check `mobile/lib/core/widgets/sf_button.dart` and other sf_ widgets for built-in Semantics support.

### 2. Touch Target Sizes

**Minimum touch targets: 44x44pt (iOS) / 48x48dp (Android)**

Search for hardcoded small sizes on interactive elements:
- Grep for `SizedBox(` with `width:` or `height:` values below 44 near interactive widgets
- Grep for `IconButton(` with `iconSize:` below 24 (renders with padding to ~44)
- Grep for `constraints:` with `maxHeight` or `maxWidth` below 44
- Check custom button widgets for minimum size enforcement

### 3. Color Contrast

**Minimum contrast ratio: 4.5:1 (WCAG AA)**

Flag potential contrast issues:
- Grep for `AppColors.gray400` or `AppColors.gray300` used as text color (light grays on white may fail contrast)
- Grep for `opacity:` or `withOpacity(` or `withValues(alpha:` on text colors (reduces contrast)
- Check that error/success/warning colors have sufficient contrast against their backgrounds

### 4. Color-Only Indicators

**Don't use color as the only way to convey information:**

Search for patterns where color alone indicates state:
- Grep for `color:` changes in conditional expressions without corresponding text/icon changes
- Check status badges (`sf_status_badge.dart`) — do they include text labels alongside colors?
- Check form validation — are errors shown with text, not just red borders?

### 5. Image Accessibility

**All images need descriptions:**
- Grep for `Image.asset(` or `Image.network(` or `CachedNetworkImage(` — check for `semanticLabel:` parameter
- Grep for `Icon(` — check for `semanticLabel:` parameter
- Grep for `DecorationImage(` — these need a `Semantics` wrapper

### 6. Text Scaling

**Support Dynamic Type / Text Scaling:**
- Check if `MediaQuery.textScaleFactor` or `MediaQuery.textScaler` is used anywhere
- Grep for `maxLines:` with `overflow: TextOverflow.ellipsis` — acceptable pattern
- Check that text containers can expand (no fixed heights cutting off scaled text)
- Verify fonts use `sp`-equivalent sizing (Flutter handles this by default, but check for `textScaleFactor: 1.0` which disables scaling)

### 7. Dark Mode Support

**Check dark mode readiness:**
- Read `mobile/lib/core/theme/app_theme.dart` — is there a dark theme defined?
- Check if `ThemeMode` is configurable in `MaterialApp`
- Grep for hardcoded `Colors.white` or `Colors.black` instead of `Theme.of(context)` colors
- Grep for hardcoded `Color(0xFF` values that won't adapt to dark mode

### 8. Screen Reader Navigation

**Check logical navigation order:**
- Grep for `Semantics(` with `sortKey:` (explicit ordering)
- Check if `ExcludeSemantics(` or `BlockSemantics(` is used appropriately (not hiding important content)
- Verify that decorative elements are excluded from semantics tree

### 9. Report Summary

```
## Accessibility Audit Results

### CRITICAL (blocks users with disabilities)
- [missing Semantics on interactive elements]
- [touch targets below 44pt]

### WARNING (degrades accessibility)
- [color-only indicators]
- [images without semantic labels]
- [potential contrast issues]

### INFO (improvements)
- [dark mode not implemented]
- [text scaling considerations]

### Compliance Status
- WCAG 2.1 AA: [PARTIAL/PASS]
- iOS HIG Accessibility: [PARTIAL/PASS]
- Material Design Accessibility: [PARTIAL/PASS]

### Stats
- Interactive elements checked: X
- Elements with Semantics: X / Y (Z%)
- Touch target violations: X
```
