import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../profile/profile_bottom_sheet.dart';
import '../utility/helpers.dart';
import '../pond_background.dart';
import '../repositories/monitoring_repository.dart';
import '../services/safety_service.dart';

import 'monitoring_parameters.dart';
import 'monitoring_ui_helpers.dart';
import 'edit_history_sheet.dart';
import 'trends_tab.dart';
import 'record_data_sheet.dart';

import 'widgets/monitoring_header.dart';
import 'widgets/pond_info_card.dart';
import 'widgets/measurement_list_view.dart';
import 'widgets/expense_sheet.dart';
import 'monitoring_calendar.dart';
import 'expenses_tab.dart';
import 'growth_tab.dart';

class MonitoringPage extends StatefulWidget {
  final String pondId;
  final String pondName;
  final String userRole;
  final String species;

  const MonitoringPage({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.userRole,
    required this.species,
  });

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  late DateTime _focusedDay;
  DateTime? _selectedDay;
  bool _isFabVisible = true;

  Map<String, dynamic>? _mySchedule;
  bool _isLoadingSchedule = true;

  final MonitoringRepository _repository = MonitoringRepository();
  final SafetyService _safetyService = SafetyService();

  bool get canEdit => widget.userRole == 'owner' || widget.userRole == 'editor';

  final Color primaryBlue = const Color(0xFF0A74DA);
  final Color secondaryBlue = const Color(0xFF4FA0F0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _pageController = PageController();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        HapticFeedback.lightImpact();
        if (_pageController.hasClients &&
            _pageController.page?.round() != _tabController.index) {
          _pageController.animateToPage(
            _tabController.index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
        }
        setState(() {}); // For FAB visibility
      }
    });

    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = DateTime.utc(now.year, now.month, now.day);

    _loadMySchedule();
  }

  Future<void> _loadMySchedule() async {
    if (!canEdit) {
      if (mounted) setState(() => _isLoadingSchedule = false);
      return;
    }
    try {
      final scheduleData = await _repository.getJobSchedule(
        widget.pondId,
        _repository.currentUser!.uid,
      );
      if (mounted) {
        setState(() {
          if (scheduleData != null && scheduleData['schedule'] != null) {
            _mySchedule = scheduleData['schedule'] as Map<String, dynamic>;
          }
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSchedule = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --- UI Actions ---

  void _showProfileSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileBottomSheet(
        currentPondId: widget.pondId,
        currentPondName: widget.pondName,
        currentUserRole: widget.userRole,
      ),
    );
  }

  void _showEditHistory() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => EditHistorySheet(
          pondId: widget.pondId,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showAddDataOverlay() {
    HapticFeedback.lightImpact();
    if (!canEdit) {
      SnackbarHelper.show(context, 'Permissions required to add data.');
      return;
    }

    if (_selectedDay == null) {
      SnackbarHelper.show(context, 'Please select a day first.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordDataSheet(
        tabIndex: _tabController.index,
        onSave: _handleSaveData,
        species: widget.species,
      ),
    );
  }

  // --- Data Logic ---

  Future<void> _handleSaveData({
    required String label,
    required String unit,
    required String timeString,
    required double averageValue,
    required String type,
    required Map<String, double> pointValues,
    required Map<String, List<double>> replicateValues,
  }) async {
    try {
      await _repository.saveMeasurement(
        pondId: widget.pondId,
        label: label,
        unit: unit,
        timeString: timeString,
        averageValue: averageValue,
        type: type,
        pointValues: pointValues,
        replicateValues: replicateValues,
        selectedDay: _selectedDay!,
      );

      final parameterItem = MonitoringParameters.getParameterByLabel(
        label,
        widget.species,
      );
      if (parameterItem != null) {
        await _safetyService.checkAndNotify(
          parameter: parameterItem,
          value: averageValue,
          pondName: widget.pondName,
        );
      }

      if (mounted) {
        SnackbarHelper.show(
          context,
          "Data recorded",
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(context, "Error: $e", backgroundColor: Colors.red);
      }
    }
  }

  void _showEditDataDialog(List<DocumentSnapshot> docs) {
    if (!canEdit) return;

    final List<String> points = const ['A', 'B', 'C', 'D'];
    final List<int> replicates = const [1, 2, 3];
    final Map<String, Map<String, TextEditingController>> groupControllers = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final replicateValuesMap =
          data['replicateValues'] as Map<String, dynamic>? ?? {};
      groupControllers[doc.id] = {};

      // Create controllers for each replicate of each point
      for (var p in points) {
        for (var r in replicates) {
          final key = '$p-$r';
          final replicatesList = replicateValuesMap[p] as List<dynamic>? ?? [];
          final value = r <= replicatesList.length
              ? replicatesList[r - 1].toString()
              : '';
          groupControllers[doc.id]![key] = TextEditingController(text: value);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Edit Measurements (Replicates Only)',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final paramItem = MonitoringParameters.getParameterByLabel(
              data['parameter'],
              widget.species,
            );
            final isSinglePoint = paramItem?.isSinglePoint ?? false;

            return _buildEditReplicateGroup(
              doc,
              groupControllers[doc.id]!,
              points,
              replicates,
              isSinglePoint: isSinglePoint,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => _handleBatchDelete(docs),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => _handleBatchUpdateWithReplicates(
              docs,
              groupControllers,
              points,
              replicates,
            ),
            child: const Text(
              "Update",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBatchDelete(List<DocumentSnapshot> docs) async {
    final confirm = await _showConfirmDeleteDialog();
    if (confirm != true) return;

    try {
      for (var doc in docs) {
        await _repository.deleteMeasurement(
          pondId: widget.pondId,
          measurementId: doc.id,
          currentData: doc.data() as Map<String, dynamic>,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        SnackbarHelper.show(context, "Measurements deleted");
      }
    } catch (e) {
      if (mounted) SnackbarHelper.show(context, "Error: $e");
    }
  }

  Future<void> _handleBatchUpdateWithReplicates(
    List<DocumentSnapshot> docs,
    Map<String, Map<String, TextEditingController>> groupControllers,
    List<String> points,
    List<int> replicates,
  ) async {
    final Map<String, Map<String, double>> updatedPointValues = {};
    final Map<String, Map<String, List<double>>> updatedReplicateValues = {};

    // Calculate point averages from replicate values
    for (var doc in docs) {
      final controllersMap = groupControllers[doc.id]!;
      Map<String, double> newPointValues = {};
      Map<String, List<double>> newReplicateValues = {};

      for (var p in points) {
        final replicatesList = <double>[];
        for (var r in replicates) {
          final key = '$p-$r';
          final val = double.tryParse(controllersMap[key]?.text ?? '');
          if (val != null) {
            replicatesList.add(val);
          }
        }

        if (replicatesList.isNotEmpty) {
          newReplicateValues[p] = replicatesList;
          final avg = double.parse(
            (replicatesList.reduce((a, b) => a + b) / replicatesList.length)
                .toStringAsFixed(2),
          );
          newPointValues[p] = avg;
        }
      }

      if (newPointValues.isNotEmpty) {
        updatedPointValues[doc.id] = newPointValues;
        updatedReplicateValues[doc.id] = newReplicateValues;
      }
    }

    try {
      await _repository.updateMeasurementsWithReplicates(
        pondId: widget.pondId,
        docs: docs,
        updatedPointValues: updatedPointValues,
        updatedReplicateValues: updatedReplicateValues,
      );

      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final pointValues = updatedPointValues[doc.id];
        if (pointValues == null) continue;

        final avg =
            pointValues.values.reduce((a, b) => a + b) /
            pointValues.values.length;
        final paramItem = MonitoringParameters.getParameterByLabel(
          data['parameter'],
          widget.species,
        );
        if (paramItem != null) {
          await _safetyService.checkAndNotify(
            parameter: paramItem,
            value: avg,
            pondName: widget.pondName,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        SnackbarHelper.show(
          context,
          "Measurements updated",
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(context, "Error: $e", backgroundColor: Colors.red);
      }
    }
  }

  // --- Helper Builders ---

  Widget _buildEditReplicateGroup(
    DocumentSnapshot doc,
    Map<String, TextEditingController> controllers,
    List<String> points,
    List<int> replicates, {
    bool isSinglePoint = false,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${data['parameter']} (${data['unit'] ?? ''})",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          if (isSinglePoint)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controllers['A-1'],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Value',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (int pIdx = 0; pIdx < points.length; pIdx++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: pIdx < points.length - 1 ? 20 : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Point header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "Point ${points[pIdx]}",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    // Replicate inputs
                    Row(
                      children: [
                        for (int rIdx = 0; rIdx < replicates.length; rIdx++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: rIdx < replicates.length - 1 ? 8 : 0,
                              ),
                              child: TextField(
                                controller:
                                    controllers['${points[pIdx]}-${replicates[rIdx]}'],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  labelText: "R${replicates[rIdx]}",
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Average display
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: primaryBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Avg:",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            _calculateEditReplicateAverage(
                              controllers,
                              points[pIdx],
                              replicates,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  String _calculateEditReplicateAverage(
    Map<String, TextEditingController> controllers,
    String point,
    List<int> replicates,
  ) {
    double sum = 0;
    int count = 0;
    for (var r in replicates) {
      final key = '$point-$r';
      final text = controllers[key]?.text.trim() ?? '';
      if (text.isNotEmpty) {
        final val = double.tryParse(text);
        if (val != null) {
          sum += val;
          count++;
        }
      }
    }
    if (count == 0) return "—";
    return double.parse((sum / count).toStringAsFixed(2)).toString();
  }

  Widget _buildJobBanner() {
    if (_isLoadingSchedule || _mySchedule == null) {
      return const SizedBox.shrink();
    }

    // Determine current day of week
    final now = DateTime.now();
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final currentDayName = dayNames[now.weekday - 1];

    final todaySchedule = _mySchedule![currentDayName] as Map<String, dynamic>?;
    if (todaySchedule == null) return const SizedBox.shrink();

    final morning = todaySchedule['morning'] == true;
    final afternoon = todaySchedule['afternoon'] == true;

    if (!morning && !afternoon) return const SizedBox.shrink();

    List<String> shifts = [];
    if (morning) shifts.add("Morning");
    if (afternoon) shifts.add("Afternoon");

    // Determine Jobs based on frequencies
    List<String> jobs = ["Tank Monitoring", "Daily Parameters"];
    if (now.weekday == DateTime.wednesday) {
      jobs.add("Biweekly Parameters");
    } else if (now.weekday == DateTime.saturday) {
      jobs.add("Biweekly Parameters");
      jobs.add("Weekly Parameters");
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade900.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Colors.amber.shade800,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Tasks Today",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${shifts.join(' & ')} Shift",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: jobs
                .map(
                  (job) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      job,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Delete"),
        content: const Text("Delete this measurement?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _selectedDay == null
        ? ""
        : "${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const PondBackground(),
          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification ||
                    notification is ScrollUpdateNotification) {
                  if (_isFabVisible) setState(() => _isFabVisible = false);
                } else if (notification is ScrollEndNotification) {
                  if (!_isFabVisible) setState(() => _isFabVisible = true);
                }
                return false;
              },
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: MonitoringHeader(
                      pondId: widget.pondId,
                      onBackTap: () => Navigator.pop(context),
                      onHistoryTap: _showEditHistory,
                      onProfileTap: _showProfileSheet,
                      primaryBlue: primaryBlue,
                      secondaryBlue: secondaryBlue,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: PondInfoCard(
                      pondName: widget.pondName,
                      primaryBlue: primaryBlue,
                      secondaryBlue: secondaryBlue,
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildJobBanner()),
                  SliverToBoxAdapter(child: _buildCalendarSection()),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicator: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF64748B),
                        dividerColor: Colors.transparent,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        tabs: [
                          Tab(
                            child: _buildTabLabel(
                              "Daily",
                              Colors.green.shade400,
                            ),
                          ),
                          Tab(
                            child: _buildTabLabel(
                              "Weekly",
                              Colors.amber.shade400,
                            ),
                          ),
                          Tab(
                            child: _buildTabLabel(
                              "Biweekly",
                              Colors.purple.shade400,
                            ),
                          ),
                          Tab(
                            child: _buildTabLabel(
                              "Growth",
                              Colors.indigo.shade400,
                            ),
                          ),
                          Tab(
                            child: _buildTabLabel(
                              "Trends",
                              Colors.red.shade400,
                            ),
                          ),
                          Tab(
                            child: _buildTabLabel(
                              "Expenses",
                              Colors.teal.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                body: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    _tabController.animateTo(index);
                    setState(() {});
                  },
                  children: [
                    _buildStreamTab('daily', dateKey),
                    _buildStreamTab('weekly', dateKey),
                    _buildStreamTab('biweekly', dateKey),
                    GrowthTab(pondId: widget.pondId),
                    TrendsTab(pondId: widget.pondId, species: widget.species),
                    ExpensesTab(pondId: widget.pondId, canAdd: canEdit),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildCalendarSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              MonitoringCalendar(
                pondId: widget.pondId,
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                onDaySelected: (selectedDay, focusedDay) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedDay = DateTime.utc(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                    );
                    _focusedDay = focusedDay;
                  });
                },
              ),
              Divider(color: Colors.grey.shade100, height: 1),
              _buildCalendarLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            "Dates with records",
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabLabel(String text, Color dotColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStreamTab(String type, String dateKey) {
    if (_selectedDay == null) {
      return const Center(child: Text("Select a date to view data"));
    }
    return MeasurementListView(
      pondId: widget.pondId,
      type: type,
      dateKey: dateKey,
      canEdit: canEdit,
      onEdit: _showEditDataDialog,
      primaryBlue: primaryBlue,
    );
  }

  void _showExpenseOverlay() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseSheet(pondId: widget.pondId),
    );
  }

  Widget? _buildFab() {
    if (!canEdit) return null;

    final String label;
    final IconData icon;
    final VoidCallback action;
    final Color fabColor;

    if (_tabController.index == 4) {
      label = "Export Report";
      icon = Icons.ios_share_rounded;
      action = () {
        HapticFeedback.lightImpact();
        SnackbarHelper.show(
          context,
          "Export functionality coming soon",
          backgroundColor: Colors.red.shade400,
        );
      };
      fabColor = Colors.red.shade400;
    } else if (_tabController.index == 5) {
      label = "Add Expense";
      icon = Icons.receipt_long_rounded;
      action = _showExpenseOverlay;
      fabColor = Colors.teal;
    } else if (_tabController.index == 3) {
      label = "Record Sampling";
      icon = Icons.add_rounded;
      action = () {
        HapticFeedback.lightImpact();
        SnackbarHelper.show(
          context,
          "Growth recording coming soon",
          backgroundColor: Colors.indigo.shade400,
        );
      };
      fabColor = Colors.indigo.shade400;
    } else {
      label = "Record Data";
      icon = Icons.add_rounded;
      action = _showAddDataOverlay;
      fabColor = primaryBlue;
    }

    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _isFabVisible ? 1.0 : 0.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: fabColor.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: action,
            backgroundColor: fabColor,
            elevation: 0,
            icon: Icon(icon, color: Colors.white),
            label: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
          ),
        ),
      ),
    );
  }
}
