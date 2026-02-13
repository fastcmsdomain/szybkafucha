---
name: platform-compliance
description: >
  This skill should be used when creating or modifying screen files in the Flutter mobile app
  (mobile/lib/features/*/screens/). It ensures UI follows iOS Human Interface Guidelines and
  Android Material Design 3 standards for touch targets, typography, accessibility, navigation,
  and spacing. Apply this skill when building new screens or modifying existing UI layouts.
version: 1.0.0
---

# Platform Compliance

When creating or modifying screen files in `mobile/lib/features/*/screens/`, ensure the UI meets iOS HIG and Material Design 3 standards.

## Touch Targets

**Minimum sizes:**
- iOS HIG: 44x44 points
- Material Design: 48x48 dp
- Flutter default: Most Material widgets meet this automatically

**Rules:**
- Never make interactive elements smaller than 44x44
- `IconButton` default size is 48x48 (acceptable)
- Custom `GestureDetector` or `InkWell` wrappers must enforce minimum 44x44
- Add padding to small icons to meet minimum tap area
- If using `SizedBox` to constrain interactive elements, ensure dimensions >= 44

## Typography

**Minimum text sizes per guidelines:**
- Body text: 16pt minimum (both iOS HIG and Material)
- Captions/labels: 11pt minimum (acceptable for secondary info)
- Headings: Use theme hierarchy (h1 > h2 > h3 > h4 > h5 > h6)

**Rules:**
- Always use theme text styles: `Theme.of(context).textTheme.bodyLarge`
- Never hardcode `fontSize:` below 11
- Ensure text can scale with system text size settings (don't disable text scaling)
- Use `AppTypography` or theme text styles, not raw `TextStyle()`

## Accessibility

**Every interactive element needs a screen reader label:**

```dart
// IconButton — use tooltip
IconButton(
  icon: Icon(Icons.close),
  tooltip: 'Zamknij',  // Required for accessibility
  onPressed: () {},
)

// GestureDetector — wrap in Semantics
Semantics(
  label: 'Otwórz szczegóły zadania',
  button: true,
  child: GestureDetector(
    onTap: () {},
    child: TaskCard(...),
  ),
)

// Images — use semanticLabel
Image.asset(
  'assets/logo.png',
  semanticLabel: 'Logo Szybka Fucha',
)
```

**Additional accessibility requirements:**
- Don't use color as the only indicator (add text/icon alongside)
- Ensure sufficient contrast (4.5:1 for text, 3:1 for large text)
- Support focus navigation for tablet/desktop
- Provide `Semantics` with `excludeSemantics: true` for purely decorative elements

## Navigation Patterns

**Bottom Navigation:**
- Use 3-5 tabs (current app uses this correctly)
- Tab icons must have labels
- Active tab must be clearly distinguishable

**Screen Navigation:**
- Support back swipe gesture on iOS (Go Router does this by default)
- Always provide a back button in AppBar for non-root screens
- Use `context.pop()` for back navigation, not `context.go()` to parent

**Dialogs and Bottom Sheets:**
- Bottom sheets for actions and selections (Material pattern)
- Alert dialogs for confirmations
- Always provide a way to dismiss (tap outside, close button, swipe down)

## Spacing and Layout

**8dp Grid System (Material Design):**
Use `AppSpacing` constants which follow the 8dp grid:

| Use case | Value | AppSpacing constant |
|----------|-------|-------------------|
| Tight spacing | 4dp | `AppSpacing.paddingXS` |
| Small spacing | 8dp | `AppSpacing.paddingSM` |
| Medium spacing | 16dp | `AppSpacing.paddingMD` |
| Large spacing | 24dp | `AppSpacing.paddingLG` |
| Extra large | 32dp | `AppSpacing.paddingXL` |

**Rules:**
- Never use arbitrary spacing values (5, 7, 9, 10, 15, etc.)
- All padding, margin, and gaps should use `AppSpacing` constants
- Consistent spacing within similar sections of the same screen

## Colors

**Use semantic colors from `AppColors`:**
- Primary actions: `AppColors.primary`
- Success states: `AppColors.success`
- Error/destructive: `AppColors.error`
- Warning: `AppColors.warning`
- Info: `AppColors.info`
- Text: `AppColors.gray900` (primary), `AppColors.gray700` (secondary)
- Backgrounds: `AppColors.white`, `AppColors.gray100`

**Never hardcode colors:**
```dart
// BAD
Container(color: Color(0xFFE94560))
Text('Error', style: TextStyle(color: Colors.red))

// GOOD
Container(color: AppColors.primary)
Text('Error', style: TextStyle(color: AppColors.error))
```

## Dark Mode Awareness

While dark mode is not yet implemented, write code that will be easy to adapt:
- Use `Theme.of(context).colorScheme` for surface/background colors when possible
- Avoid hardcoded `Colors.white` for backgrounds
- Use semantic color names (`onSurface`, `surface`) instead of absolute colors
- When dark mode is implemented, these patterns will automatically adapt
