---
description: Detect Flutter performance anti-patterns in the codebase
allowed-tools: Grep, Glob, Read
---

# Flutter Performance Audit

Scan the Flutter codebase for known performance anti-patterns based on Flutter best practices and the project's development guidelines.

## Steps

### 1. ListView Anti-patterns

**Find non-lazy ListViews:**
Grep for `ListView(\s*$` or `ListView(` followed by `children:` in `.dart` files under `mobile/lib/`.
These should use `ListView.builder` for dynamic content to avoid creating all items upfront.

**Acceptable exceptions**: Short static lists with <5 known items.

### 2. Container vs SizedBox

**Find Containers used only for sizing:**
Grep for `Container(` where only `width:` and/or `height:` are specified (no decoration, color, padding, etc.).
These should be `SizedBox` which is lighter weight.

Pattern to search: `Container(\s*\n\s*(width:|height:)` without `decoration:`, `color:`, `padding:`, `margin:` nearby.

### 3. Opacity Widget Usage

**Find Opacity widget:**
Grep for `Opacity(` in `.dart` files. The `Opacity` widget triggers `saveLayer()` which is expensive.

**Better alternatives**:
- For colors: use `color.withOpacity()` or `color.withValues(alpha:)`
- For images: use `FadeInImage`
- For animations: use `AnimatedOpacity` (still uses saveLayer but is expected for animations)

### 4. IntrinsicHeight/IntrinsicWidth in Lists

**Find intrinsic operations in scrollable contexts:**
Grep for `IntrinsicHeight` and `IntrinsicWidth` in files that also contain `ListView`, `GridView`, `CustomScrollView`, or `Sliver`.
These cause O(N^2) layout passes.

### 5. setState Scope

**Find broad setState calls:**
Grep for `setState(` in screen files (`mobile/lib/features/*/screens/*.dart`).
Large screens using setState rebuild the entire widget tree. Consider:
- Moving state to specific child widgets
- Using ValueNotifier + ValueListenableBuilder
- Using Riverpod providers for granular rebuilds

### 6. Build Method Complexity

**Find expensive operations in build():**
Search for these patterns in `.dart` files:
- `Future` or `async` in build methods
- `json` parsing in build methods
- `sort()`, `where()`, `map().toList()` chains in build methods (should be cached/memoized)
- Network/API calls triggered during build

### 7. Image Performance

**Check image loading patterns:**
- Grep for `NetworkImage(` or `Image.network(` — should use `CachedNetworkImage` instead
- Grep for large image assets without sizing constraints
- Check if `cached_network_image` package is used consistently

### 8. Unnecessary Rebuilds

**Find widgets missing const:**
- Grep for `Text('` (with single quotes, literal strings) without `const` prefix
- Grep for `SizedBox(` with only literal values and no `const`
- Grep for `Icon(Icons.` without `const`

### 9. Report Summary

```
## Performance Audit Results

### CRITICAL (causes jank/lag)
- [ListView without .builder, IntrinsicHeight in lists]

### WARNING (degrades performance)
- [Opacity widget, broad setState, uncached images]

### INFO (optimization opportunities)
- [Container→SizedBox, missing const, build() complexity]

### Stats
- Files scanned: X
- Issues found: X (critical: X, warning: X, info: X)
- Top 3 files needing attention: [files with most issues]
```
