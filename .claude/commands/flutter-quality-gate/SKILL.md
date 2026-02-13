---
name: flutter-quality-gate
description: >
  This skill should be used when creating or modifying Dart files in the Flutter mobile app
  (mobile/lib/). It ensures code follows project conventions for naming, widget organization,
  theme token usage, and performance patterns. Apply this skill when writing new widgets,
  screens, providers, or modifying existing Flutter code.
version: 1.0.0
---

# Flutter Quality Gate

When writing or modifying `.dart` files in `mobile/lib/`, apply these quality checks to all code you produce.

## Naming Conventions

- **Files**: Use `snake_case.dart` (e.g., `task_tracking_screen.dart`)
- **Classes/Enums**: Use `UpperCamelCase` (e.g., `TaskTrackingScreen`, `TaskStatus`)
- **Variables/Functions**: Use `lowerCamelCase` (e.g., `userName`, `fetchTasks()`)
- **Constants**: Use `lowerCamelCase` for Dart conventions (e.g., `maxTaskDistance`)
- **Private members**: Prefix with `_` (e.g., `_privateMethod()`)
- **Reusable widgets in `core/widgets/`**: Use `sf_` file prefix and `SF` class prefix (e.g., `sf_button.dart` → `SFButton`)

## Widget Organization

- **Keep widgets small**: If a widget's `build()` method exceeds ~100 lines, extract sub-widgets
- **Single responsibility**: Each widget should do one thing well
- **Use `const` constructors**: Always add `const` to constructors when all fields are final and non-dynamic
- **Use `const` on literal widgets**: `const Text('...')`, `const SizedBox(height: 8)`, `const Icon(Icons.add)`
- **Extract build helpers**: If `build()` has complex conditionals, extract to `_buildSomething()` methods — but prefer separate widget classes for reusability

## No Business Logic in build()

Never put these in `build()` methods:
- API calls or network requests
- Heavy computation or data transformation
- `async`/`await` operations
- Complex `setState` with business logic

Instead:
- Use Riverpod providers for async data
- Pre-compute values in `initState()` or provider
- Use `ref.watch()` for reactive data in `build()`

## Theme Token Usage

Always use design tokens from `core/theme/` instead of hardcoded values:

| Instead of | Use |
|-----------|-----|
| `Color(0xFF...)` or `Colors.blue` | `AppColors.primary`, `AppColors.gray600` |
| `EdgeInsets.all(16)` | `EdgeInsets.all(AppSpacing.paddingMD)` |
| `BorderRadius.circular(12)` | `AppRadius.radiusMD` or `AppRadius.card` |
| `BoxShadow(...)` | `AppShadows.small` or `AppShadows.medium` |
| Raw `TextStyle(fontSize: 16)` | `Theme.of(context).textTheme.bodyLarge` |
| `GoogleFonts.nunito(...)` directly | Use theme's text styles |

**Exception**: Theme definition files in `core/theme/` define these values and are excluded.

## Performance Patterns

- **Lists**: Use `ListView.builder` for dynamic lists, not `ListView(children: [...])`
- **Sizing**: Use `SizedBox` instead of `Container` when only specifying width/height
- **Opacity**: Avoid `Opacity()` widget — use `color.withValues(alpha: 0.5)` for simple cases
- **Images**: Use `CachedNetworkImage` for network images, not `Image.network`
- **Const**: Mark all possible widgets as `const` to prevent unnecessary rebuilds

## State Management (Riverpod)

- Use `ref.watch()` in `build()` for reactive updates
- Use `ref.read()` in callbacks and event handlers
- Prefer `StateNotifier` with immutable state classes
- Use `copyWith()` for state updates
- Keep providers in `core/providers/` for shared state
- Feature-specific providers go in `features/*/providers/`

## File Structure

When creating new features, follow this structure:
```
features/
  feature_name/
    screens/       # Full-page widgets
    widgets/       # Feature-specific reusable widgets
    models/        # Data models
    providers/     # Feature-specific providers (if any)
```
