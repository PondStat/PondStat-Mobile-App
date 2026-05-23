import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/services/logging/logger_provider.dart';
import 'package:pondstat/core/utils/string_extensions.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/features/auth/data/auth_repository.dart';
import 'package:pondstat/features/dashboard/data/pond_repository.dart';
import 'package:pondstat/core/widgets/primary_button.dart';

class AssignShiftSheet extends ConsumerStatefulWidget {
  final String pondId;
  final String pondName;
  final ScrollController scrollController;

  const AssignShiftSheet({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.scrollController,
  });

  @override
  ConsumerState<AssignShiftSheet> createState() => _AssignShiftSheetState();
}

class _AssignShiftSheetState extends ConsumerState<AssignShiftSheet> {
  Color get primaryBlue => Theme.of(context).colorScheme.primary;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _selectedDay = 'Monday';
  String _selectedShift = 'morning'; // 'morning' or 'afternoon'

  // List of all eligible users fetched from the pond's roles
  List<Map<String, dynamic>> _eligibleUsers = [];

  // Holds the COMPLETE schedule state for ALL eligible users
  // Format: userId -> day -> shift -> bool
  final Map<String, Map<String, dynamic>> _allUserSchedules = {};

  // Holds the INITIAL schedule state for comparison to determine what changed
  final Map<String, Map<String, dynamic>> _initialUserSchedules = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Capture providers before any async gap to avoid ref access after unmount.
    final pondRepo = ref.read(pondRepositoryProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final monitoringRepo = ref.read(monitoringRepositoryProvider);
    final logger = ref.read(appLoggerProvider);

    try {
      // 1. Fetch eligible users
      final pondDoc = await pondRepo.pondsCollection
          .doc(widget.pondId)
          .get();
      if (!mounted || !pondDoc.exists) return;

      final pond = pondDoc.data();
      if (pond == null) return;
      final roles = pond.roles;

      List<Map<String, dynamic>> users = [];
      for (var entry in roles.entries) {
        if (entry.value == 'owner' || entry.value == 'editor') {
          final userDoc = await authRepo.usersCollection
              .doc(entry.key)
              .get();
          if (!mounted) return;
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            users.add({
              'id': entry.key,
              'name': userData['fullName'] ?? 'Unknown User',
            });
          }
        }
      }

      // 2. Fetch existing schedules for all those users
      for (var user in users) {
        final userId = user['id'];
        final scheduleData = await monitoringRepo.getJobSchedule(
          widget.pondId,
          userId,
        );
        if (!mounted) return;

        // Initialize an empty 7-day schedule
        Map<String, dynamic> fullSchedule = {};
        for (var day in _daysOfWeek) {
          fullSchedule[day] = {'morning': false, 'afternoon': false};
        }

        if (scheduleData != null && scheduleData['schedule'] is Map) {
          final savedSchedule =
              scheduleData['schedule'] as Map;
          for (var day in _daysOfWeek) {
            if (savedSchedule.containsKey(day) && savedSchedule[day] is Map) {
              final dayMap = savedSchedule[day] as Map;
              fullSchedule[day]['morning'] =
                  dayMap['morning'] ?? false;
              fullSchedule[day]['afternoon'] =
                  dayMap['afternoon'] ?? false;
            }
          }
        }

        // Deep copy for both tracking current and initial state
        _allUserSchedules[userId] = _deepCopySchedule(fullSchedule);
        _initialUserSchedules[userId] = _deepCopySchedule(fullSchedule);
      }

      if (mounted) {
        setState(() {
          _eligibleUsers = users;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      logger.error('Error loading data for assignment', error: e, stackTrace: stackTrace, tag: 'SCHEDULE');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _deepCopySchedule(Map<String, dynamic> original) {
    Map<String, dynamic> copy = {};
    for (var day in original.keys) {
      copy[day] = {
        'morning': original[day]['morning'],
        'afternoon': original[day]['afternoon'],
      };
    }
    return copy;
  }

  bool _hasChanges() {
    for (var userId in _allUserSchedules.keys) {
      final current = _allUserSchedules[userId]!;
      final initial = _initialUserSchedules[userId]!;

      for (var day in _daysOfWeek) {
        if (current[day]['morning'] != initial[day]['morning'] ||
            current[day]['afternoon'] != initial[day]['afternoon']) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    // Capture provider before async gap.
    final monitoringRepo = ref.read(monitoringRepositoryProvider);

    try {
      int updatedCount = 0;
      for (var user in _eligibleUsers) {
        final userId = user['id'];
        final current = _allUserSchedules[userId]!;
        final initial = _initialUserSchedules[userId]!;

        // Check if this specific user has changes
        bool userChanged = false;
        for (var day in _daysOfWeek) {
          if (current[day]['morning'] != initial[day]['morning'] ||
              current[day]['afternoon'] != initial[day]['afternoon']) {
            userChanged = true;
            break;
          }
        }

        if (userChanged) {
          await monitoringRepo.saveJobSchedule(
            pondId: widget.pondId,
            userId: userId,
            userName: user['name'],
            schedule: current,
          );
          if (!mounted) return;
          updatedCount++;
        }
      }

      if (mounted) {
        Navigator.pop(context); // close bottom sheet
        final connectivityResult = await Connectivity().checkConnectivity().timeout(
          const Duration(seconds: 1),
          onTimeout: () => [ConnectivityResult.none],
        );
        if (mounted) {
          if (connectivityResult.contains(ConnectivityResult.none)) {
            SnackbarHelper.showSuccess(context, "Schedules saved locally for $updatedCount members (will sync when online)");
          } else {
            SnackbarHelper.showSuccess(context, "Schedules updated successfully for $updatedCount members");
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        SnackbarHelper.showError(context, "Error saving schedules: $e");
      }
    }
  }

  void _toggleUserAssignment(String userId, bool isAssigned) {
    HapticFeedback.lightImpact();
    setState(() {
      _allUserSchedules[userId]![_selectedDay][_selectedShift] = isAssigned;
    });
  }

  void _toggleSelectAll() {
    HapticFeedback.selectionClick();
    // Determine if all are currently selected
    bool allSelected = _eligibleUsers.every(
      (user) =>
          _allUserSchedules[user['id']]![_selectedDay][_selectedShift] == true,
    );

    setState(() {
      for (var user in _eligibleUsers) {
        _allUserSchedules[user['id']]![_selectedDay][_selectedShift] =
            !allSelected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.group_add_rounded, color: primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Assign Shift",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: onSurface,
                      ),
                    ),
                    Text(
                      widget.pondName,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters: Day & Shift
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDay,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.expand_more_rounded,
                        color: Color(0xFF64748B),
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDay = val);
                      },
                      items: _daysOfWeek.map((day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedShift == 'morning'
                        ? (isDark
                              ? Colors.amber.withValues(alpha: 0.1)
                              : Colors.amber.shade50)
                        : (isDark
                              ? Colors.indigo.withValues(alpha: 0.1)
                              : Colors.indigo.shade50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedShift == 'morning'
                          ? (isDark
                                ? Colors.amber.withValues(alpha: 0.3)
                                : Colors.amber.shade200)
                          : (isDark
                                ? Colors.indigo.withValues(alpha: 0.3)
                                : Colors.indigo.shade200),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedShift,
                      isExpanded: true,
                      icon: Icon(
                        Icons.expand_more_rounded,
                        color: _selectedShift == 'morning'
                            ? (isDark
                                  ? Colors.amber.shade300
                                  : Colors.amber.shade700)
                            : (isDark
                                  ? Colors.indigo.shade300
                                  : Colors.indigo.shade700),
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _selectedShift == 'morning'
                            ? (isDark
                                  ? Colors.amber.shade300
                                  : Colors.amber.shade800)
                            : (isDark
                                  ? Colors.indigo.shade300
                                  : Colors.indigo.shade800),
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedShift = val);
                      },
                      items: [
                        DropdownMenuItem<String>(
                          value: 'morning',
                          child: Row(
                            children: [
                              Icon(
                                Icons.wb_sunny_rounded,
                                size: 14,
                                color: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "Morning",
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'afternoon',
                          child: Row(
                            children: [
                              Icon(
                                Icons.wb_twilight_rounded,
                                size: 14,
                                color: isDark ? Colors.indigo.shade300 : Colors.indigo.shade700,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "Afternoon",
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Subheader list
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ELIGIBLE MEMBERS",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.2,
                ),
              ),
              if (!_isLoading && _eligibleUsers.isNotEmpty)
                TextButton(
                  onPressed: _toggleSelectAll,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _eligibleUsers.every(
                          (u) =>
                              _allUserSchedules[u['id']]![_selectedDay][_selectedShift] ==
                              true,
                        )
                        ? "Deselect All"
                        : "Select All",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // User List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _eligibleUsers.isEmpty
                ? Center(
                    child: Text(
                      "No eligible members found.\nInvite people with 'Editor' or 'Owner' roles.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: _eligibleUsers.length,
                    itemBuilder: (context, index) {
                      final user = _eligibleUsers[index];
                      final userId = user['id'];
                      final isAssigned =
                          _allUserSchedules[userId]![_selectedDay][_selectedShift] ==
                          true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isAssigned
                              ? primaryBlue.withValues(alpha: 0.15)
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isAssigned
                                ? primaryBlue.withValues(alpha: 0.3)
                                : (isDark
                                      ? Colors.white12
                                      : Colors.grey.shade200),
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isAssigned,
                          onChanged: (val) {
                            if (val != null) _toggleUserAssignment(userId, val);
                          },
                          activeColor: primaryBlue,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          title: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade200,
                                child: Text(
                                  (user['name'] as String?).initials,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  user['name'],
                                  style: TextStyle(
                                    fontWeight: isAssigned
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: onSurface,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),

          // Save Button
          PrimaryButton(
            text: "Save Shift Assignments",
            onPressed: _hasChanges() ? _saveChanges : null,
            isLoading: _isSaving,
          ),
        ],
      ),
    );
  }
}
