---
description: Check iOS HIG and Android Material Design compliance
allowed-tools: Grep, Glob, Read
---

# Platform Guidelines Audit

Check the Flutter codebase for compliance with Apple Human Interface Guidelines (HIG) and Google Material Design 3 guidelines.

Reference: `tasks/development-guidelines-ios-android-flutter (1).md`

## Steps

### 1. Material Design 3 Compliance

**Verify Material 3 is enabled:**
- Read `mobile/lib/core/theme/app_theme.dart` — check for `useMaterial3: true`
- Verify `ColorScheme.fromSeed()` is used (Material 3 color system)
- Check that Material 3 components are used (not legacy Material 2)

**Material component usage:**
- Grep for deprecated Material 2 patterns:
  - `RaisedButton` → should be `ElevatedButton`
  - `FlatButton` → should be `TextButton`
  - `OutlineButton` → should be `OutlinedButton`
  - `ButtonTheme` → should be `ElevatedButtonTheme` etc.
  - `accentColor` → should be `colorScheme.secondary`

### 2. Typography Standards

**Minimum text sizes (both iOS HIG and Material):**

Grep for font sizes below minimums in `mobile/lib/`:
- `fontSize: ` with values below 11 (absolute minimum)
- Body text below 16 (iOS HIG and Material recommend 16pt/sp minimum for body)
- Check `app_typography.dart` — verify body text starts at 16

**Note**: `bodySmall` at 12 and `labelSmall` at 11 are acceptable for captions/labels per both guidelines. Flag only if these small sizes are used for primary content.

### 3. Touch Target Sizes

**iOS HIG: minimum 44x44 points**
**Material Design: minimum 48x48 dp**

Search for undersized touch targets:
- Grep for `SizedBox(` near `IconButton`, `GestureDetector`, `InkWell` with dimensions below 44
- Grep for `height: ` and `width: ` with values 20-43 on interactive elements
- Check `sf_button.dart` — verify small variant meets minimum
- Check custom interactive widgets for minimum size

### 4. Navigation Patterns

**iOS HIG patterns:**
- Tab Bar for 3-5 main sections
- Back swipe gesture support (Go Router handles this by default)
- Navigation Bar with back button

**Material Design patterns:**
- Bottom Navigation Bar (3-5 destinations)
- FAB for primary action
- Top App Bar

**Check:**
- Read `mobile/lib/core/widgets/sf_bottom_nav.dart` — how many tabs? (should be 3-5)
- Read `mobile/lib/core/router/app_router.dart` — verify navigation hierarchy
- Grep for `WillPopScope` or `PopScope` — verify back navigation handling
- Check if swipe-to-go-back works (Go Router provides this on iOS by default)

### 5. Spacing and Grid System

**Material Design: 8dp grid system**

Check spacing values in `mobile/lib/core/theme/app_spacing.dart`:
- Verify spacing values are multiples of 4 or 8
- Common Material spacings: 4, 8, 12, 16, 24, 32, 48, 64

Grep for hardcoded spacing that breaks the grid:
- `padding: EdgeInsets.all(` with non-standard values (e.g., 5, 7, 9, 10, 15)
- `SizedBox(height: ` or `SizedBox(width: ` with non-grid values
- `margin:` with non-standard values

**Exclude** theme definition files.

### 6. Dark Mode Support

**iOS HIG**: Dark Mode is a core feature, not optional
**Material Design**: Dark theme is part of Material 3 theming

**Check:**
- Read `app_theme.dart` — is `dark` theme defined? (currently only light)
- Check `MaterialApp` — is `darkTheme:` property set?
- Check `ThemeMode` — is it configurable?
- Grep for `Brightness.dark` — any dark mode awareness?
- Report status: Not implemented / Partial / Complete

### 7. Platform-Adaptive UI

**Check for platform-specific adaptations:**
Grep for:
- `Platform.isIOS` or `Platform.isAndroid` — platform checks
- `CupertinoPageScaffold` or `CupertinoNavigationBar` — iOS-specific widgets
- `Adaptive` widgets (e.g., `Switch.adaptive`, `CircularProgressIndicator.adaptive`)
- `defaultTargetPlatform` — platform-aware logic

**Recommendation**: Key areas where platform adaptation matters:
- Alert dialogs (Cupertino vs Material)
- Date/time pickers
- Navigation transitions
- Scroll physics (BouncingScrollPhysics for iOS, ClampingScrollPhysics for Android)

### 8. App Icon and Launch Screen

**Check platform assets:**
- Glob for `ios/Runner/Assets.xcassets/AppIcon.appiconset/` — iOS app icons
- Glob for `android/app/src/main/res/mipmap-*/` — Android app icons
- Check launch screen / splash screen configuration
- Verify icon sizes meet store requirements

### 9. Report Summary

```
## Platform Guidelines Audit

### iOS HIG Compliance
- [ ] Material 3 enabled (compatible with iOS design)
- [ ] Typography meets minimums (16pt body)
- [ ] Touch targets >= 44x44pt
- [ ] Navigation uses Tab Bar pattern
- [ ] Dark Mode: [NOT IMPLEMENTED / PARTIAL / COMPLETE]
- [ ] Back swipe gesture works
- [ ] Platform-adaptive widgets used

### Material Design 3 Compliance
- [ ] Material 3 enabled
- [ ] Color scheme uses fromSeed()
- [ ] Typography meets minimums (16sp body)
- [ ] Touch targets >= 48x48dp
- [ ] 8dp grid system followed
- [ ] Dark theme defined
- [ ] Material components (not legacy)

### Platform Adaptation
- [ ] iOS-specific patterns where needed
- [ ] Android-specific patterns where needed
- [ ] Adaptive widgets used

### Stats
- Material 3 compliance: X%
- iOS HIG compliance: X%
- Platform adaptations found: X
- Dark mode status: [NOT IMPLEMENTED]
```
