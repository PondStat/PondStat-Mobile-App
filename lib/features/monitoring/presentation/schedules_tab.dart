import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

class SchedulesTab extends StatefulWidget {
  final String pondId;
  final String pondName;
  final bool canEdit;

  const SchedulesTab({
    super.key,
    required this.pondId,
    required this.pondName,
    this.canEdit = true,
  });

  @override
  State<SchedulesTab> createState() => _SchedulesTabState();
}

class _SchedulesTabState extends State<SchedulesTab> {
  final Color primaryBlue = const Color(0xFF0A74DA);
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  void _showAssignSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AssignShiftSheet(
          pondId: widget.pondId,
          pondName: widget.pondName,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreHelper.schedulesCollection
            .where('pondId', isEqualTo: widget.pondId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading schedules"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // Parse schedules into a grouped format: day -> shift -> List of user objects
          final Map<String, Map<String, List<Map<String, dynamic>>>>
          groupedSchedules = {
            for (var day in _daysOfWeek) day: {'morning': [], 'afternoon': []},
          };

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final schedule = data['schedule'] as Map<String, dynamic>?;
            final userName = data['userName'] ?? 'Unknown User';
            final userId = data['userId'] ?? doc.id;

            if (schedule != null) {
              for (var day in _daysOfWeek) {
                if (schedule.containsKey(day)) {
                  if (schedule[day]['morning'] == true) {
                    groupedSchedules[day]!['morning']!.add({
                      'id': userId,
                      'name': userName,
                    });
                  }
                  if (schedule[day]['afternoon'] == true) {
                    groupedSchedules[day]!['afternoon']!.add({
                      'id': userId,
                      'name': userName,
                    });
                  }
                }
              }
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              top: 12,
              left: 20,
              right: 20,
              bottom: 100, // padding for FAB
            ),
            itemCount: _daysOfWeek.length,
            itemBuilder: (context, index) {
              final day = _daysOfWeek[index];
              final morningUsers = groupedSchedules[day]!['morning']!;
              final afternoonUsers = groupedSchedules[day]!['afternoon']!;

              // Only show days that have at least one assignment, unless we are in edit mode
              // If edit mode, show all days so they can see nothing is assigned.
              if (morningUsers.isEmpty &&
                  afternoonUsers.isEmpty &&
                  !widget.canEdit) {
                return const SizedBox.shrink();
              }

              return _buildDayCard(day, morningUsers, afternoonUsers);
            },
          );
        },
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              heroTag: 'schedules_fab',
              onPressed: _showAssignSheet,
              backgroundColor: primaryBlue,
              icon: const Icon(Icons.group_add_rounded, color: Colors.white),
              label: const Text(
                "Assign Shifts",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDayCard(
    String day,
    List<Map<String, dynamic>> morningUsers,
    List<Map<String, dynamic>> afternoonUsers,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
            ),
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: onSurface,
              ),
            ),
          ),
          _ShiftExpansionTile(
            shiftName: "Morning",
            icon: Icons.wb_sunny_rounded,
            iconColor: Colors.amber.shade700,
            bgColor: Colors.amber.shade50,
            assignedUsers: morningUsers,
          ),
          Divider(
            height: 1,
            color: Colors.grey.shade200,
            indent: 16,
            endIndent: 16,
          ),
          _ShiftExpansionTile(
            shiftName: "Afternoon",
            icon: Icons.wb_twilight_rounded,
            iconColor: Colors.indigo.shade600,
            bgColor: Colors.indigo.shade50,
            assignedUsers: afternoonUsers,
          ),
        ],
      ),
    );
  }
}

class _ShiftExpansionTile extends StatefulWidget {
  final String shiftName;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final List<Map<String, dynamic>> assignedUsers;

  const _ShiftExpansionTile({
    required this.shiftName,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.assignedUsers,
  });

  @override
  State<_ShiftExpansionTile> createState() => _ShiftExpansionTileState();
}

class _ShiftExpansionTileState extends State<_ShiftExpansionTile> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    if (widget.assignedUsers.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: widget.assignedUsers.isNotEmpty ? _toggleExpanded : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, size: 18, color: widget.iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.shiftName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark
                              ? onSurface.withValues(alpha: 0.9)
                              : const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        widget.assignedUsers.isEmpty
                            ? "No one assigned"
                            : "${widget.assignedUsers.length} assigned",
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.assignedUsers.isEmpty
                              ? Colors.red.shade400
                              : (isDark
                                    ? Colors.white38
                                    : Colors.grey.shade600),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.assignedUsers.isNotEmpty) ...[
                  _OverlapAvatarGroup(users: widget.assignedUsers),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  children: widget.assignedUsers
                      .map(
                        (user) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: _getAvatarColor(
                                  user['name'],
                                ).withValues(alpha: 0.2),
                                child: Text(
                                  StringUtils.getInitials(user['name']),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getAvatarColor(user['name']),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                user['name'],
                                style: TextStyle(
                                  color: onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              secondChild: const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final pastelColors = [
      const Color(0xFFFDA4AF),
      const Color(0xFFFCD34D),
      const Color(0xFF6EE7B7),
      const Color(0xFF93C5FD),
      const Color(0xFFC4B5FD),
      const Color(0xFFF9A8D4),
      const Color(0xFFFDBA74),
      const Color(0xFF5EEAD4),
    ];
    final hash = name.hashCode.abs();
    return pastelColors[hash % pastelColors.length];
  }
}

class _OverlapAvatarGroup extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  const _OverlapAvatarGroup({required this.users});

  @override
  Widget build(BuildContext context) {
    final maxToShow = 3;
    final int toShow = users.length > maxToShow ? maxToShow : users.length;
    final int remaining = users.length > maxToShow
        ? users.length - maxToShow
        : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(toShow + (remaining > 0 ? 1 : 0), (index) {
        if (index == toShow && remaining > 0) {
          // The '+X' circle
          return Align(
            widthFactor: 0.6,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                "+$remaining",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          );
        }

        final user = users[index];
        final name = user['name'] as String;
        final pastelColors = [
          const Color(0xFFFDA4AF),
          const Color(0xFFFCD34D),
          const Color(0xFF6EE7B7),
          const Color(0xFF93C5FD),
          const Color(0xFFC4B5FD),
        ];
        final hash = name.hashCode.abs();
        final color = pastelColors[hash % pastelColors.length];

        return Align(
          widthFactor: 0.6,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Text(
                StringUtils.getInitials(name),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// -----------------------------------------------------------------------------
// Phase 3: Shift-First Assignment Sheet (Multi-select)
// -----------------------------------------------------------------------------

class AssignShiftSheet extends StatefulWidget {
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
  State<AssignShiftSheet> createState() => _AssignShiftSheetState();
}

class _AssignShiftSheetState extends State<AssignShiftSheet> {
  final Color primaryBlue = const Color(0xFF0A74DA);
  final MonitoringRepository _repository = MonitoringRepository();
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
    try {
      // 1. Fetch eligible users
      final pondDoc = await FirestoreHelper.pondsCollection
          .doc(widget.pondId)
          .get();
      if (!pondDoc.exists) return;

      final data = pondDoc.data() ?? {};
      final roles = data['roles'] as Map<String, dynamic>? ?? {};

      List<Map<String, dynamic>> users = [];
      for (var entry in roles.entries) {
        if (entry.value == 'owner' || entry.value == 'editor') {
          final userDoc = await FirestoreHelper.usersCollection
              .doc(entry.key)
              .get();
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
        final scheduleData = await _repository.getJobSchedule(
          widget.pondId,
          userId,
        );

        // Initialize an empty 7-day schedule
        Map<String, dynamic> fullSchedule = {};
        for (var day in _daysOfWeek) {
          fullSchedule[day] = {'morning': false, 'afternoon': false};
        }

        if (scheduleData != null && scheduleData['schedule'] != null) {
          final savedSchedule =
              scheduleData['schedule'] as Map<String, dynamic>;
          for (var day in _daysOfWeek) {
            if (savedSchedule.containsKey(day)) {
              fullSchedule[day]['morning'] =
                  savedSchedule[day]['morning'] ?? false;
              fullSchedule[day]['afternoon'] =
                  savedSchedule[day]['afternoon'] ?? false;
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
    } catch (e) {
      debugPrint("Error loading data for assignment: $e");
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
          await _repository.saveJobSchedule(
            pondId: widget.pondId,
            userId: userId,
            userName: user['name'],
            schedule: current,
          );
          updatedCount++;
        }
      }

      if (mounted) {
        Navigator.pop(context); // close bottom sheet
        SnackbarHelper.show(
          context,
          "Schedules updated successfully for $updatedCount members",
          backgroundColor: Colors.green.shade600,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        SnackbarHelper.show(
          context,
          "Error saving schedules: $e",
          backgroundColor: Colors.redAccent,
        );
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
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
                        ? Colors.amber.shade50
                        : Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedShift == 'morning'
                          ? Colors.amber.shade200
                          : Colors.indigo.shade200,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedShift,
                      isExpanded: true,
                      icon: Icon(
                        Icons.expand_more_rounded,
                        color: _selectedShift == 'morning'
                            ? Colors.amber.shade700
                            : Colors.indigo.shade700,
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _selectedShift == 'morning'
                            ? Colors.amber.shade800
                            : Colors.indigo.shade800,
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
                                color: Colors.amber.shade700,
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
                                color: Colors.indigo.shade700,
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
                              ? primaryBlue.withValues(alpha: 0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isAssigned
                                ? primaryBlue.withValues(alpha: 0.3)
                                : Colors.grey.shade200,
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
                                backgroundColor: Colors.grey.shade200,
                                child: Text(
                                  StringUtils.getInitials(user['name']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
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
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _hasChanges() && !_isSaving ? _saveChanges : null,
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      "Save Shift Assignments",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
