import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

class UnifiedScheduleSheet extends StatefulWidget {
  final String pondId;
  final String pondName;
  final bool canEdit;

  const UnifiedScheduleSheet({
    super.key,
    required this.pondId,
    required this.pondName,
    this.canEdit = true,
  });

  @override
  State<UnifiedScheduleSheet> createState() => _UnifiedScheduleSheetState();
}

class _UnifiedScheduleSheetState extends State<UnifiedScheduleSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryBlue = const Color(0xFF0A74DA);

  // --- Assign State ---
  bool _isLoadingUsers = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  final MonitoringRepository _repository = MonitoringRepository();
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final Map<String, Map<String, bool>> _schedule = {};
  List<Map<String, dynamic>> _eligibleUsers = [];
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    // Only show tabs if user can edit, otherwise just overview
    _tabController = TabController(length: widget.canEdit ? 2 : 1, vsync: this);

    _resetSchedule();
    if (widget.canEdit) {
      _loadEligibleUsers();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Assign Logic ---
  void _resetSchedule() {
    for (var day in _daysOfWeek) {
      _schedule[day] = {'morning': false, 'afternoon': false};
    }
  }

  Future<void> _loadEligibleUsers() async {
    try {
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

      if (mounted) {
        setState(() {
          _eligibleUsers = users;
          if (users.isNotEmpty) {
            _selectedUserId = users.first['id'];
            _loadExistingSchedule();
          } else {
            _isLoadingUsers = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading eligible users: $e");
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _loadExistingSchedule() async {
    if (_selectedUserId == null) return;

    setState(() {
      _isLoadingUsers = true;
      _hasChanges = false;
      _resetSchedule();
    });

    try {
      final scheduleData = await _repository.getJobSchedule(
        widget.pondId,
        _selectedUserId!,
      );
      if (mounted) {
        if (scheduleData != null && scheduleData['schedule'] != null) {
          final savedSchedule =
              scheduleData['schedule'] as Map<String, dynamic>;
          setState(() {
            for (var day in _daysOfWeek) {
              if (savedSchedule.containsKey(day)) {
                _schedule[day]?['morning'] =
                    savedSchedule[day]['morning'] ?? false;
                _schedule[day]?['afternoon'] =
                    savedSchedule[day]['afternoon'] ?? false;
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading schedule: $e");
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  void _onUserChanged(String? newUserId) async {
    if (newUserId == null || newUserId == _selectedUserId) return;

    if (_hasChanges) {
      final shouldDiscard = await _showDiscardDialog();
      if (shouldDiscard != true) return;
    }

    setState(() => _selectedUserId = newUserId);
    _loadExistingSchedule();
  }

  void _toggleShift(String day, String shift) {
    HapticFeedback.lightImpact();
    setState(() {
      _schedule[day]![shift] = !_schedule[day]![shift]!;
      _hasChanges = true;
    });
  }

  bool _hasAnyShiftSelected() {
    for (var day in _daysOfWeek) {
      if (_schedule[day]!['morning'] == true ||
          _schedule[day]!['afternoon'] == true) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveSchedule() async {
    if (_selectedUserId == null) return;

    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    try {
      final user = _eligibleUsers.firstWhere((u) => u['id'] == _selectedUserId);
      await _repository.saveJobSchedule(
        pondId: widget.pondId,
        userId: _selectedUserId!,
        userName: user['name'],
        schedule: _schedule,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasChanges = false;
        });
        SnackbarHelper.show(
          context,
          "Schedule updated for ${user['name']}",
          backgroundColor: Colors.green.shade600,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        SnackbarHelper.show(
          context,
          "Error saving schedule: $e",
          backgroundColor: Colors.redAccent,
        );
      }
    }
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Discard Changes?"),
        content: const Text(
          "You have unsaved changes. Are you sure you want to discard them?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Keep Editing",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Discard"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_hasChanges || _isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _showDiscardDialog();
        if (shouldDiscard == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
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
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            _buildHeader(),
            const SizedBox(height: 16),
            if (widget.canEdit)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: primaryBlue,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelColor: Colors.grey.shade600,
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: "Overview"),
                    Tab(text: "Assign Jobs"),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  if (widget.canEdit) _buildAssignTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.event_note_rounded, color: primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Schedule Manager",
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
    );
  }

  // --- Overview Tab ---
  Widget _buildOverviewTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreHelper.schedulesCollection
          .where('pondId', isEqualTo: widget.pondId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading schedule"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyOverview();

        final Map<String, List<Map<String, dynamic>>> daySchedules = {
          for (var day in _daysOfWeek) day: [],
        };

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final schedule = data['schedule'] as Map<String, dynamic>?;
          if (schedule != null) {
            for (var day in _daysOfWeek) {
              if (schedule.containsKey(day)) {
                final morning = schedule[day]['morning'] == true;
                final afternoon = schedule[day]['afternoon'] == true;
                if (morning || afternoon) {
                  daySchedules[day]!.add({
                    'userName': data['userName'] ?? 'Unknown',
                    'morning': morning,
                    'afternoon': afternoon,
                  });
                }
              }
            }
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: _daysOfWeek.length,
          itemBuilder: (context, index) {
            final day = _daysOfWeek[index];
            final members = daySchedules[day]!;
            if (members.isEmpty) return const SizedBox.shrink();
            return _buildDayCard(day, members);
          },
        );
      },
    );
  }

  Widget _buildEmptyOverview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No Schedules Set",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Use the Assign tab to create schedules.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(String day, List<Map<String, dynamic>> members) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: primaryBlue,
              ),
            ),
          ),
          ...members.map((m) => _buildMemberRow(m)),
        ],
      ),
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> member) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final List<String> shifts = [];
    if (member['morning']) shifts.add("Morning");
    if (member['afternoon']) shifts.add("Afternoon");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member['userName'],
              style: TextStyle(fontWeight: FontWeight.w700, color: onSurface),
            ),
          ),
          Row(
            children: shifts
                .map(
                  (shift) => Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: shift == "Morning"
                          ? Colors.amber.shade50
                          : Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: shift == "Morning"
                            ? Colors.amber.shade200
                            : Colors.indigo.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          shift == "Morning"
                              ? Icons.wb_sunny_rounded
                              : Icons.wb_twilight_rounded,
                          size: 12,
                          color: shift == "Morning"
                              ? Colors.amber.shade700
                              : Colors.indigo.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shift,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: shift == "Morning"
                                ? Colors.amber.shade800
                                : Colors.indigo.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // --- Assign Tab ---
  Widget _buildAssignTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_eligibleUsers.isEmpty && !_isLoadingUsers) {
      return const Center(child: Text("No eligible members found."));
    }
    if (_isLoadingUsers && _eligibleUsers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserDropdown(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "ASSIGN SHIFTS",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _daysOfWeek.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                  ),
                  itemBuilder: (context, index) =>
                      _buildDayRow(_daysOfWeek[index]),
                ),
        ),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildUserDropdown() {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUserId,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF64748B)),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
          onChanged: _onUserChanged,
          items: _eligibleUsers.map((user) {
            return DropdownMenuItem<String>(
              value: user['id'],
              child: Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Text(user['name']),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDayRow(String day) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final bool morning = _schedule[day]?['morning'] ?? false;
    final bool afternoon = _schedule[day]?['afternoon'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: onSurface,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildShiftButton(
                    label: "Morning",
                    icon: Icons.wb_sunny_rounded,
                    isSelected: morning,
                    onTap: () => _toggleShift(day, 'morning'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildShiftButton(
                    label: "Afternoon",
                    icon: Icons.wb_twilight_rounded,
                    isSelected: afternoon,
                    onTap: () => _toggleShift(day, 'afternoon'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = label == "Morning"
        ? Colors.amber.shade700
        : Colors.indigo.shade600;
    final activeBgColor = label == "Morning"
        ? Colors.amber.shade50
        : Colors.indigo.shade50;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? activeColor : Colors.grey.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final bool canSave = _hasChanges && !_isSaving && _hasAnyShiftSelected();

    return SizedBox(
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
        onPressed: canSave ? _saveSchedule : null,
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
                "Save Schedule",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
