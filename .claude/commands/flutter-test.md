---
description: Run Flutter tests with coverage and report gaps
allowed-tools: Bash(flutter test:*), Bash(cd:*), Glob, Grep, Read
---

# Flutter Test + Coverage Report

Run all Flutter tests, report coverage, and identify untested files that need test coverage.

## Steps

### 1. Run Flutter Tests

Run tests in the `mobile/` directory:

```
cd mobile && flutter test --coverage
```

Report:
- Total tests run
- Pass/fail counts
- Any failing test details

### 2. Identify Untested Files

Use Glob to find all `.dart` files in `mobile/lib/` that contain testable logic:

**Priority 1 - Providers** (business logic, most critical):
- Glob for `mobile/lib/core/providers/*.dart`
- Check if corresponding test exists in `mobile/test/core/providers/`

**Priority 2 - Services** (external integrations):
- Glob for `mobile/lib/core/services/*.dart`
- Check if corresponding test exists in `mobile/test/core/services/`

**Priority 3 - Models** (data classes):
- Glob for `mobile/lib/features/*/models/*.dart`
- Check if corresponding test exists

**Priority 4 - Widgets** (UI components):
- Glob for `mobile/lib/core/widgets/*.dart`
- Check if corresponding test exists in `mobile/test/core/widgets/`

**Priority 5 - Screens** (integration-level):
- Glob for `mobile/lib/features/*/screens/*.dart`
- Check if corresponding test exists

### 3. Coverage Gap Analysis

For each untested file found, report:
- File path
- Priority level (1-5)
- What should be tested (based on file type)

### 4. Generate Test Suggestions

For the top 5 most critical untested files, suggest what tests should be written:

**For Providers**: Test state transitions, async operations, error handling
**For Services**: Test API calls with mocked responses, error scenarios
**For Models**: Test fromJson/toJson, copyWith, edge cases
**For Widgets**: Test rendering, interaction callbacks, different states
**For Screens**: Test navigation, user flows, loading/error states

### 5. Report Summary

```
## Test Results
- Tests run: X
- Passed: X
- Failed: X

## Coverage Gaps

### Priority 1 - Providers (CRITICAL)
- [ ] auth_provider.dart — No tests
- [ ] task_provider.dart — No tests
...

### Priority 2 - Services
...

### Priority 3 - Models
...

### Priority 4 - Widgets
...

### Priority 5 - Screens
...

## Total Coverage
- Files with tests: X / Y (Z%)
- Recommended next: [top 3 files to test first]
```
