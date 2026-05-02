# Dark Mode Readability Fixes Design

## Goal
Replace hardcoded dark colors and light backgrounds with theme-aware alternatives in monitoring-related UI components to ensure readability in both light and dark modes.

## Problem
Several files use `Color(0xFF1E293B)` (Slate 800) for text and icons, which becomes invisible or hard to read in dark mode. Additionally, `Colors.grey.shade100` is used for backgrounds/borders, which is too bright in dark mode.

## Proposed Changes

### 1. Theme-Aware Colors
In the `build` method of affected widgets, we will define:
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final colorScheme = Theme.of(context).colorScheme;
final onSurface = colorScheme.onSurface;
```

### 2. Replacements
- **Text/Icon Color**: Replace `Color(0xFF1E293B)` with `onSurface`.
- **Background/Border Color**: Replace `Colors.grey.shade100` with `isDark ? Colors.white10 : Colors.grey.shade100`.

### 3. Files to Modify
- `lib/features/monitoring/presentation/edit_history_sheet.dart`
- `lib/features/monitoring/presentation/expenses_tab.dart`
- `lib/features/monitoring/presentation/schedules_tab.dart`
- `lib/features/monitoring/presentation/unified_schedule_sheet.dart`
- `lib/features/monitoring/presentation/widgets/expense_sheet.dart`
- `lib/features/monitoring/presentation/widgets/measurement_list_view.dart`

## Verification
- Run `dart format` on modified files.
- Run `dart analyze` to ensure no errors.
- (Manual) Verify visual appearance in both themes if possible (though I can't do this easily in this environment, I will ensure the code logic is correct).
