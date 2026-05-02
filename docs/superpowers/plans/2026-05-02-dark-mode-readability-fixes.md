# Dark Mode Readability Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace hardcoded dark colors and light backgrounds with theme-aware alternatives in monitoring UI components.

**Architecture:** Use `Theme.of(context)` to retrieve the current theme's `colorScheme.onSurface` and `brightness` to conditionally set colors.

**Tech Stack:** Flutter (Dart)

---

### Task 1: Fix `edit_history_sheet.dart`

**Files:**
- Modify: `lib/features/monitoring/presentation/edit_history_sheet.dart`

- [ ] **Step 1: Update `build` method to include theme variables**
- [ ] **Step 2: Replace `Color(0xFF1E293B)` with `onSurface`**
- [ ] **Step 3: Replace `Colors.grey.shade100` with theme-aware background color**
- [ ] **Step 4: Verify with `dart analyze`**

### Task 2: Fix `expenses_tab.dart`

**Files:**
- Modify: `lib/features/monitoring/presentation/expenses_tab.dart`

- [ ] **Step 1: Update `build` method to include theme variables**
- [ ] **Step 2: Replace `Color(0xFF1E293B)` and `Colors.grey.shade100`**
- [ ] **Step 3: Verify with `dart analyze`**

### Task 3: Fix `schedules_tab.dart`

**Files:**
- Modify: `lib/features/monitoring/presentation/schedules_tab.dart`

- [ ] **Step 1: Update `build` method to include theme variables**
- [ ] **Step 2: Replace `Color(0xFF1E293B)`**
- [ ] **Step 3: Verify with `dart analyze`**

### Task 4: Fix `unified_schedule_sheet.dart`

**Files:**
- Modify: `lib/features/monitoring/presentation/unified_schedule_sheet.dart`

- [ ] **Step 1: Update `build` method to include theme variables**
- [ ] **Step 2: Replace `Color(0xFF1E293B)` and `Colors.grey.shade100`**
- [ ] **Step 3: Verify with `dart analyze`**

### Task 5: Fix `widgets/expense_sheet.dart`

**Files:**
- Modify: `lib/features/monitoring/presentation/widgets/expense_sheet.dart`

- [ ] **Step 1: Update `build` method to include theme variables**
- [ ] **Step 2: Replace `Color(0xFF1E293B)`**
- [ ] **Step 3: Verify with `dart analyze`**

### Task 6: Fix `widgets/measurement_list_view.dart`

**Files:**
- Modify: `lib/features/monitoring/presentation/widgets/measurement_list_view.dart`

- [ ] **Step 1: Update `build` method to include theme variables**
- [ ] **Step 2: Replace `Color(0xFF1E293B)` and `Colors.grey.shade100`**
- [ ] **Step 3: Verify with `dart analyze`**

### Task 7: Final Verification and Commit

- [ ] **Step 1: Run `dart format .`**
- [ ] **Step 2: Run `dart analyze .`**
- [ ] **Step 3: Commit changes**
