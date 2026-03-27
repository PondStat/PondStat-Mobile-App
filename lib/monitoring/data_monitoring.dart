import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/profile_bottom_sheet.dart';
import '../firebase/firestore_helper.dart';
import '../utility/helpers.dart';
import 'record_data_sheet.dart';
import 'measurement_card.dart';
import 'monitoring_calendar.dart';
import '../pond_background.dart';

import 'monitoring_ui_helpers.dart';
import 'edit_history_sheet.dart';

class MonitoringPage extends StatefulWidget {
  final String pondId;
  final String pondName;
  final String userRole;

  const MonitoringPage({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.userRole,
  });

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _shimmerController;

  late DateTime _focusedDay;
  DateTime? _selectedDay;

  bool _isFabVisible = true;

  bool get canEdit => widget.userRole == 'owner' || widget.userRole == 'editor';

  final Color primaryBlue = const Color(0xFF0A74DA);
  final Color secondaryBlue = const Color(0xFF4FA0F0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        HapticFeedback.lightImpact();
      }
    });

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = DateTime.utc(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _showProfileSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ProfileBottomSheet(
          currentPondId: widget.pondId,
          currentPondName: widget.pondName,
          currentUserRole: widget.userRole,
        );
      },
    );
  }

  Future<void> deleteMeasurement(DocumentSnapshot doc) async {
    final user = FirebaseAuth.instance.currentUser;
    final data = doc.data() as Map<String, dynamic>;

    final batch = FirebaseFirestore.instance.batch();
    batch.delete(doc.reference);

    final historyRef = FirestoreHelper.measurementHistoryCollection.doc();
    batch.set(historyRef, {
      'pondId': widget.pondId,
      'measurementId': doc.id,
      'parameter': data['parameter'],
      'action': 'delete',
      'editedAt': Timestamp.now(),
      'editedBy': user?.uid,
      'editorName': user?.displayName ?? 'Unknown',
      'before': data,
      'after': null,
    });

    await batch.commit();
  }

  Future<void> _saveDataToFirestore({
    required String label,
    required String unit,
    required String timeString,
    required double averageValue,
    required String type,
    required Map<String, double> pointValues,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedDay == null) return;

    final String dateKey =
        "${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}";

    final batch = FirebaseFirestore.instance.batch();
    final measurementRef = FirestoreHelper.measurementsCollection.doc();

    batch.set(measurementRef, {
      'pondId': widget.pondId,
      'dateKey': dateKey,
      'timestamp': Timestamp.fromDate(_selectedDay!),
      'recordedAt': FieldValue.serverTimestamp(),
      'recordedBy': user.uid,
      'recorderName': user.displayName ?? 'Unknown',
      'type': type,
      'parameter': label,
      'value': averageValue,
      'unit': unit,
      'timeString': timeString,
      'pointValues': pointValues,
    });

    final historyRef = FirestoreHelper.measurementHistoryCollection.doc();
    batch.set(historyRef, {
      'pondId': widget.pondId,
      'measurementId': measurementRef.id,
      'parameter': label,
      'action': 'create',
      'editedAt': FieldValue.serverTimestamp(),
      'editedBy': user.uid,
      'editorName': user.displayName ?? 'Unknown',
      'before': null,
      'after': {'value': averageValue, 'pointValues': pointValues},
    });

    try {
      await batch.commit();
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

  void _showEditHistory(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return EditHistorySheet(
              pondId: widget.pondId,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  void _showAddDataOverlay() {
    HapticFeedback.lightImpact();
    if (!canEdit) {
      SnackbarHelper.show(
        context,
        'You need Editor or Owner permissions to add data.',
      );
      return;
    }

    if (_selectedDay == null) {
      SnackbarHelper.show(
        context,
        'Please select a day on the calendar first.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return RecordDataSheet(
          tabIndex: _tabController.index,
          onSave: _saveDataToFirestore,
        );
      },
    );
  }

  void _showEditDataDialog(List<QueryDocumentSnapshot> docs) {
    if (!canEdit) return;

    final Map<String, Map<String, TextEditingController>> groupControllers = {};
    final List<String> points = const ['A', 'B', 'C', 'D'];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final pointValues = data['pointValues'] as Map<String, dynamic>? ?? {};
      groupControllers[doc.id] = {
        for (var p in points)
          p: TextEditingController(text: pointValues[p]?.toString() ?? ''),
      };
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Edit Measurements',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: docs.map((doc) {
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
                    const SizedBox(height: 12),
                    Row(
                      children: points.map((p) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: TextField(
                              controller: groupControllers[doc.id]![p],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                labelText: p,
                                isDense: true,
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
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
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                final user = FirebaseAuth.instance.currentUser;
                final batch = FirebaseFirestore.instance.batch();

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final historyRef = FirestoreHelper
                      .measurementHistoryCollection
                      .doc();
                  batch.set(historyRef, {
                    'pondId': widget.pondId,
                    'measurementId': doc.id,
                    'parameter': data['parameter'],
                    'editedAt': Timestamp.now(),
                    'editedBy': user?.uid,
                    'editorName': user?.displayName ?? 'Unknown',
                    'action': 'delete',
                    'before': {
                      'value': data['value'],
                      'pointValues': data['pointValues'] ?? {},
                    },
                    'after': null,
                  });
                  batch.delete(doc.reference);
                }

                Navigator.pop(context);

                try {
                  await batch.commit();
                  if (mounted)
                    SnackbarHelper.show(context, "Measurements deleted");
                } catch (e) {
                  if (mounted) SnackbarHelper.show(context, "Error: $e");
                }
              },
              child: const Text(
                "Delete",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
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
              onPressed: () async {
                final batch = FirebaseFirestore.instance.batch();
                final user = FirebaseAuth.instance.currentUser;

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final controllersMap = groupControllers[doc.id];
                  if (controllersMap == null) continue;

                  final oldValue = data['value'];
                  final oldPoints = Map<String, dynamic>.from(
                    data['pointValues'] ?? {},
                  );

                  double sum = 0;
                  int count = 0;
                  Map<String, double> newPointValues = {};

                  for (var p in points) {
                    final text = controllersMap[p]?.text;
                    if (text != null && text.isNotEmpty) {
                      final val = double.tryParse(text);
                      if (val != null) {
                        sum += val;
                        count++;
                        newPointValues[p] = val;
                      }
                    }
                  }

                  if (count > 0) {
                    double newAvg = double.parse(
                      (sum / count).toStringAsFixed(2),
                    );

                    batch.update(doc.reference, {
                      'pointValues': newPointValues,
                      'value': newAvg,
                    });

                    final historyRef = FirestoreHelper
                        .measurementHistoryCollection
                        .doc();
                    batch.set(historyRef, {
                      'pondId': widget.pondId,
                      'measurementId': doc.id,
                      'parameter': data['parameter'],
                      'editedAt': FieldValue.serverTimestamp(),
                      'editedBy': user?.uid,
                      'editorName': user?.displayName ?? 'Unknown',
                      'action': 'update',
                      'before': {'value': oldValue, 'pointValues': oldPoints},
                      'after': {'value': newAvg, 'pointValues': newPointValues},
                    });
                  }
                }

                Navigator.pop(context);

                try {
                  await batch.commit();
                  if (mounted)
                    SnackbarHelper.show(context, "Measurements updated");
                } catch (e) {
                  if (mounted) SnackbarHelper.show(context, "Error: $e");
                }
              },
              child: const Text(
                "Update",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSyncStatus() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreHelper.measurementsCollection
          .limit(1)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        bool hasPendingWrites = snapshot.hasData
            ? snapshot.data!.metadata.hasPendingWrites
            : false;
        return Row(
          children: [
            Icon(
              hasPendingWrites
                  ? Icons.cloud_upload_rounded
                  : Icons.cloud_done_rounded,
              color: hasPendingWrites
                  ? Colors.orange.shade400
                  : Colors.green.shade400,
              size: 16,
            ),
            if (hasPendingWrites) ...[
              const SizedBox(width: 4),
              Text(
                "Saving offline",
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const PondBackground(),
          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollStartNotification ||
                    notification is ScrollUpdateNotification) {
                  if (_isFabVisible) setState(() => _isFabVisible = false);
                } else if (notification is ScrollEndNotification) {
                  if (!_isFabVisible) setState(() => _isFabVisible = true);
                }
                return false;
              },
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF1E293B),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Hero(
                              tag: 'pond-icon-${widget.pondId}',
                              child: Material(
                                type: MaterialType.transparency,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [secondaryBlue, primaryBlue],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryBlue.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.water_drop_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "PondStat",
                                    style: TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  _buildSyncStatus(),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.history_rounded,
                                  color: Color(0xFF64748B),
                                ),
                                tooltip: 'Edit History',
                                onPressed: () => _showEditHistory(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showProfileSheet(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  color: Color(0xFF64748B),
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 8,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryBlue, secondaryBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        "MONITORING",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.pondName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 24,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.waves_rounded,
                                color: Colors.white.withOpacity(0.5),
                                size: 48,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
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
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 16.0,
                                  ),
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
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,

                      delegate: SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xFF64748B),
                          dividerColor: Colors.transparent,
                          labelPadding: EdgeInsets.zero,
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
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStreamTab('daily'),
                    _buildStreamTab('weekly'),
                    _buildStreamTab('biweekly'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? AnimatedSlide(
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
                        color: primaryBlue.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: _showAddDataOverlay,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    focusElevation: 0,
                    hoverElevation: 0,
                    highlightElevation: 0,
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text(
                      "Record Data",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ).applyGradient(),
              ),
            )
          : null,
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

  Widget _buildStreamTab(String type) {
    if (_selectedDay == null) {
      return const Center(child: Text("Select a date to view data"));
    }

    final String dateKey =
        "${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}";

    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreHelper.measurementsCollection
          .where('pondId', isEqualTo: widget.pondId)
          .where('type', isEqualTo: type)
          .where('dateKey', isEqualTo: dateKey)
          .orderBy('recordedAt', descending: true)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonLoader();
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState(type);

        return RefreshIndicator(
          color: primaryBlue,
          onRefresh: () async =>
              await Future.delayed(const Duration(milliseconds: 800)),
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 120,
              left: 20,
              right: 20,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return MeasurementCard(
                time: data['timeString'] ?? 'Unknown Time',
                title: data['parameter'] ?? 'Unknown Parameter',
                content:
                    "${data['value'] ?? '0'} ${data['unit'] ?? ''}\n(Avg across recorded points)",
                canEdit: canEdit,
                groupDocs: [docs[index]],
                onEdit: () => _showEditDataDialog([docs[index]]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) => AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  Colors.grey.shade200,
                  Colors.white,
                  Colors.grey.shade200,
                ],
                stops: const [0.1, 0.5, 0.9],
                begin: const Alignment(-1.0, -0.3),
                end: const Alignment(1.0, 0.3),
                transform: SlideGradientTransform(_shimmerController.value),
              ).createShader(bounds);
            },
            child: Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No $type records",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap 'Record Data' to log a measurement.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
