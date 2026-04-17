import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../repositories/monitoring_repository.dart';
import '../utility/helpers.dart';
import 'monitoring_ui_helpers.dart';

class JobScheduleSheet extends StatefulWidget {
  final String pondId;
  final String userId;
  final String userName;

  const JobScheduleSheet({
    super.key,
    required this.pondId,
    required this.userId,
    required this.userName,
  });

  @override
  State<JobScheduleSheet> createState() => _JobScheduleSheetState();
}

class _JobScheduleSheetState extends State<JobScheduleSheet> with TickerProviderStateMixin {
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  List<TimeOfDay> _startTimes = [const TimeOfDay(hour: 8, minute: 0)];
  List<int> _selectedDays = [];
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _hasChanges = false;

  final MonitoringRepository _repository = MonitoringRepository();
  late AnimationController _shimmerController;

  final List<String> _daysOfWeek = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _jobTitleController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    
    _loadExistingSchedule();
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _descriptionController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _loadExistingSchedule() async {
    try {
      final schedule = await _repository.getJobSchedule(widget.pondId, widget.userId);
      if (mounted) {
        if (schedule != null) {
          setState(() {
            _isEditing = true;
            _jobTitleController.text = schedule['jobTitle'] ?? '';
            _descriptionController.text = schedule['description'] ?? '';
            _selectedDays = List<int>.from(schedule['scheduledDays'] ?? []);
            
            // Handle startTimes (list) or startTime (string legacy)
            if (schedule['startTimes'] != null) {
              final times = List<String>.from(schedule['startTimes']);
              _startTimes = times.map((t) {
                final p = t.split(':');
                return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
              }).toList();
            } else if (schedule['startTime'] != null) {
              final t = schedule['startTime'] as String;
              final p = t.split(':');
              _startTimes = [TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]))];
            }
          });
        } else {
          // New schedule defaults
          setState(() {
            _selectedDays = [DateTime.now().weekday];
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading schedule: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasChanges = false; // Reset changes after initial load
        });
      }
    }
  }

  void _applyPreset(String type) {
    HapticFeedback.mediumImpact();
    setState(() {
      _hasChanges = true;
      if (type == 'daily') {
        _selectedDays = [1, 2, 3, 4, 5, 6, 7];
      } else if (type == 'weekdays') {
        _selectedDays = [1, 2, 3, 4, 5];
      } else if (type == 'weekends') {
        _selectedDays = [6, 7];
      }
    });
  }

  void _addTimeSlot() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _startTimes.add(picked);
        _startTimes.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
        _hasChanges = true;
      });
    }
  }

  void _removeTimeSlot(int index) {
    if (_startTimes.length <= 1) return;
    HapticFeedback.lightImpact();
    setState(() {
      _startTimes.removeAt(index);
      _hasChanges = true;
    });
  }

  String _getScheduleSummary() {
    if (_selectedDays.isEmpty) return "Select days to see summary";
    
    String daysText;
    if (_selectedDays.length == 7) {
      daysText = "every day";
    } else if (_selectedDays.length == 5 && _selectedDays.every((d) => d <= 5)) {
      daysText = "every weekday";
    } else if (_selectedDays.length == 2 && _selectedDays.every((d) => d >= 6)) {
      daysText = "every weekend";
    } else {
      daysText = "on ${_selectedDays.map((d) => _daysOfWeek[d - 1]).join(', ')}";
    }

    final timesText = _startTimes.map((t) => t.format(context)).join(', ');
    return "Runs $daysText at $timesText";
  }

  bool _isValid() {
    return _jobTitleController.text.trim().isNotEmpty && _selectedDays.isNotEmpty;
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    try {
      final timesStrings = _startTimes.map((t) => 
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}"
      ).toList();

      await _repository.saveJobSchedule(
        pondId: widget.pondId,
        userId: widget.userId,
        userName: widget.userName,
        jobTitle: _jobTitleController.text.trim(),
        scheduledDays: _selectedDays,
        startTimes: timesStrings,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        // Show success state briefly
        setState(() => _isSaving = false);
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (!context.mounted) return;
        
        // ignore: use_build_context_synchronously
        Navigator.pop(context, true);
        // ignore: use_build_context_synchronously
        SnackbarHelper.show(context, "Schedule updated for ${widget.userName}", backgroundColor: Colors.green.shade600);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        
        if (!context.mounted) return;
        
        // ignore: use_build_context_synchronously
        SnackbarHelper.show(context, "Error saving schedule: $e", backgroundColor: Colors.redAccent);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          left: 24, 
          right: 24, 
          bottom: MediaQuery.of(context).viewInsets.bottom + 32
        ),
        child: _isLoading ? _buildSkeleton() : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
          
          _buildHeader(),
          const SizedBox(height: 28),
          
          _buildSectionTitle("JOB DETAILS"),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _jobTitleController, 
            label: "Job Title *", 
            hint: "e.g., Morning PH Testing",
            icon: Icons.title_rounded,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController, 
            label: "Instructions (Optional)", 
            hint: "What should be done?", 
            icon: Icons.notes_rounded,
            maxLines: 2,
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle("REPEAT ON"),
          const SizedBox(height: 12),
          _buildPresets(),
          const SizedBox(height: 12),
          _buildDaysSelector(),
          
          const SizedBox(height: 24),
          _buildSectionTitle("START TIME"),
          const SizedBox(height: 12),
          _buildTimeSlots(),
          
          const SizedBox(height: 24),
          _buildSummaryCard(),
          
          const SizedBox(height: 32),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0A74DA).withValues(alpha: 0.1), 
            shape: BoxShape.circle
          ),
          child: Icon(
            _isEditing ? Icons.edit_calendar_rounded : Icons.event_note_rounded, 
            color: const Color(0xFF0A74DA)
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? "Edit Schedule" : "New Schedule", 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))
              ),
              Text(
                "Assigning to ${widget.userName}", 
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)), 
          onPressed: () => Navigator.maybePop(context)
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title, 
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.2)
    );
  }

  Widget _buildPresets() {
    return Row(
      children: [
        _buildPresetChip("Daily", "daily"),
        const SizedBox(width: 8),
        _buildPresetChip("Weekdays", "weekdays"),
        const SizedBox(width: 8),
        _buildPresetChip("Weekends", "weekends"),
      ],
    );
  }

  Widget _buildPresetChip(String label, String type) {
    return InkWell(
      onTap: () => _applyPreset(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required String hint, 
    required IconData icon,
    int maxLines = 1
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildDaysSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final dayIndex = index + 1;
          final isSelected = _selectedDays.contains(dayIndex);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _hasChanges = true;
                if (isSelected) {
                  _selectedDays.remove(dayIndex);
                } else {
                  _selectedDays.add(dayIndex);
                }
                _selectedDays.sort();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0A74DA) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: isSelected ? [
                  BoxShadow(color: const Color(0xFF0A74DA).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                ] : [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                ],
                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
              ),
              child: Center(
                child: Text(
                  _daysOfWeek[index].substring(0, 1),
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontSize: 14
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Column(
      children: [
        ..._startTimes.asMap().entries.map((entry) => _buildTimeCard(entry.key, entry.value)),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _addTimeSlot,
          icon: const Icon(Icons.more_time_rounded, size: 18),
          label: const Text("Add Another Time", style: TextStyle(fontWeight: FontWeight.w800)),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF0A74DA)),
        ),
      ],
    );
  }

  Widget _buildTimeCard(int index, TimeOfDay time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          final picked = await showTimePicker(context: context, initialTime: time);
          if (picked != null) {
            setState(() {
              _startTimes[index] = picked;
              _startTimes.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
              _hasChanges = true;
            });
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_filled_rounded, color: Color(0xFF94A3B8), size: 20),
              const SizedBox(width: 12),
              Text(
                time.format(context), 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))
              ),
              const Spacer(),
              if (_startTimes.length > 1)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () => _removeTimeSlot(index),
                ),
              const Text("Edit", style: TextStyle(color: Color(0xFF0A74DA), fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_getScheduleSummary()),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A74DA).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0A74DA).withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF0A74DA), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getScheduleSummary(),
                style: const TextStyle(color: Color(0xFF0A74DA), fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final valid = _isValid();
    return Column(
      children: [
        if (!valid && _hasChanges)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _jobTitleController.text.isEmpty ? "Enter a job title" : "Select at least one day",
              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: valid ? [
                BoxShadow(color: const Color(0xFF0A74DA).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))
              ] : [],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: valid ? const Color(0xFF0A74DA) : Colors.grey.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              onPressed: (valid && !_isSaving) ? _saveSchedule : null,
              child: _isSaving
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : Text(
                      _isEditing ? "Update Job Schedule" : "Create Job Schedule", 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
          _skeletonBox(height: 40, width: 200),
          const SizedBox(height: 40),
          _skeletonBox(height: 12, width: 80),
          const SizedBox(height: 12),
          _skeletonBox(height: 56, width: double.infinity),
          const SizedBox(height: 12),
          _skeletonBox(height: 80, width: double.infinity),
          const SizedBox(height: 40),
          _skeletonBox(height: 12, width: 80),
          const SizedBox(height: 16),
          _skeletonBox(height: 50, width: double.infinity),
          const SizedBox(height: 40),
          _skeletonBox(height: 60, width: double.infinity),
        ],
      ),
    );
  }

  Widget _skeletonBox({required double height, required double width}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [Colors.grey.shade100, Colors.white, Colors.grey.shade100],
              stops: const [0.1, 0.5, 0.9],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              transform: SlideGradientTransform(_shimmerController.value),
            ).createShader(bounds);
          },
          child: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Discard changes?", style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text("You have unsaved changes in the schedule. Are you sure you want to close?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Keep Editing", style: TextStyle(fontWeight: FontWeight.bold))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Discard", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}
