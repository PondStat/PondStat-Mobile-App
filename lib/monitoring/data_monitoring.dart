import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/profile_bottom_sheet.dart';
import '../firebase/firestore_helper.dart';
import '../utility/helpers.dart';
import 'record_data_sheet.dart';
import 'measurement_card.dart';
import 'monitoring_calendar.dart';
import '../pond_background.dart';
import '../firebase/user_log_helper.dart';

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

  bool get canEdit =>
      widget.userRole == 'owner' || widget.userRole == 'editor';
  final Color customBlue = const Color(0xFF0077C2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

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

    final docRef = await FirestoreHelper.measurementsCollection.add({
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

    await UserLogHelper.logAction(
      action: 'create_measurement',
      entityType: 'measurement',
      pondId: widget.pondId,
      pondName: widget.pondName,
      category: type,
      parameter: label,
      unit: unit,
      dateKey: dateKey,
      timeString: timeString,
      averageValue: averageValue,
      pointValues: pointValues,
      extra: {
        'measurementId': docRef.id,
        'recordedBy': user.uid,
        'recorderName': user.displayName ?? 'Unknown',
      },
    );
  }

  void _showAddDataOverlay() {
    if (!canEdit) {
      SnackbarHelper.show(context, 'You need Editor or Owner permissions to add data.');
      return;
    }

    if (_selectedDay == null) {
      SnackbarHelper.show(context, 'Please select a day on the calendar first.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
          p: TextEditingController(text: pointValues[p]?.toString() ?? '')
      };
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Edit Measurements'),
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
                        color: customBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: points
                          .map(
                            (p) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: TextField(
                                  controller: groupControllers[doc.id]![p],
                                  keyboardType: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    labelText: p,
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: customBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final batch = FirebaseFirestore.instance.batch();
                final List<Map<String, dynamic>> editLogs = [];

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final controllersMap = groupControllers[doc.id];
                  if (controllersMap == null) continue;

                  final oldPointValuesDynamic =
                      data['pointValues'] as Map<String, dynamic>? ?? {};
                  final Map<String, double> oldPointValues = {
                    for (final entry in oldPointValuesDynamic.entries)
                      entry.key: (entry.value as num).toDouble(),
                  };
                  final double? oldAverageValue =
                      data['value'] != null ? (data['value'] as num).toDouble() : null;

                  double sum = 0;
                  int count = 0;
                  Map<String, double> newPointValues = {};

                  for (var p in points) {
                    final text = controllersMap[p]?.text.trim();
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
                    final double newAvg =
                        double.parse((sum / count).toStringAsFixed(2));

                    batch.update(doc.reference, {
                      'pointValues': newPointValues,
                      'value': newAvg,
                    });

                    editLogs.add({
                      'measurementId': doc.id,
                      'parameter': data['parameter'] ?? 'Unknown Parameter',
                      'unit': data['unit'] ?? '',
                      'timeString': data['timeString'] ?? 'Unknown Time',
                      'dateKey': data['dateKey'] ?? '',
                      'type': data['type'] ?? '',
                      'oldAverageValue': oldAverageValue,
                      'oldPointValues': oldPointValues,
                      'newAverageValue': newAvg,
                      'newPointValues': newPointValues,
                    });
                  }
                }

                try {
                  await batch.commit();

                  for (final log in editLogs) {
                    await UserLogHelper.logAction(
                      action: 'edit_measurement',
                      entityType: 'measurement',
                      pondId: widget.pondId,
                      pondName: widget.pondName,
                      category: log['type'],
                      parameter: log['parameter'],
                      unit: log['unit'],
                      dateKey: log['dateKey'],
                      timeString: log['timeString'],
                      averageValue: log['newAverageValue'],
                      pointValues: Map<String, double>.from(log['newPointValues']),
                      extra: {
                        'measurementId': log['measurementId'],
                        'oldAverageValue': log['oldAverageValue'],
                        'oldPointValues': log['oldPointValues'],
                      },
                    );
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    SnackbarHelper.show(context, "Measurements updated");
                  }
                } catch (e) {
                  if (mounted) {
                    SnackbarHelper.show(context, "Error: $e");
                  }
                }
              },
              child: const Text("Update"),
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
                  ? Icons.cloud_upload_outlined
                  : Icons.cloud_done_outlined,
              color: hasPendingWrites ? Colors.orange : Colors.green,
              size: 20,
            ),
            if (hasPendingWrites) ...[
              const SizedBox(width: 4),
              Text(
                "Saving offline",
                style: TextStyle(
                  color: Colors.orange[800],
                  fontSize: 10,
                ),
              )
            ]
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
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction == ScrollDirection.reverse) {
                  if (_isFabVisible) {
                    setState(() => _isFabVisible = false);
                  }
                } else if (notification.direction == ScrollDirection.forward) {
                  if (!_isFabVisible) {
                    setState(() => _isFabVisible = true);
                  }
                }
                return true;
              },
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black87,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: customBlue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.waves,
                                color: customBlue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "PondStat",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                _buildSyncStatus(),
                              ],
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showProfileSheet(context),
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.black87,
                                size: 30,
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
                          vertical: 5,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Monitoring",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                widget.pondName,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: customBlue.withOpacity(0.15),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Card(
                            elevation: 0,
                            color: Colors.white.withOpacity(0.95),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
                                  const Divider(),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 16.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          color: Colors.blueAccent,
                                          size: 10,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Dates with records",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
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
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: customBlue,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey.shade600,
                          dividerColor: Colors.transparent,
                          labelPadding: EdgeInsets.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          tabs: [
                            Tab(child: _buildTabLabel("Daily", Colors.green)),
                            Tab(child: _buildTabLabel("Weekly", Colors.amber)),
                            Tab(child: _buildTabLabel("Biweekly", Colors.blue)),
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
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isFabVisible ? 1.0 : 0.0,
                child: FloatingActionButton.extended(
                  backgroundColor: customBlue,
                  onPressed: _showAddDataOverlay,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Record Data",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
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
          color: customBlue,
          onRefresh: () async =>
              await Future.delayed(const Duration(milliseconds: 800)),
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 100,
              left: 16,
              right: 16,
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
                pondId: widget.pondId,
                pondName: widget.pondName,
                category: type,
                dateKey: data['dateKey'] ?? dateKey,
                averageValue: data['value'] != null
                    ? (data['value'] as num).toDouble()
                    : null,
                pointValues: data['pointValues'] != null
                    ? Map<String, double>.from(
                        (data['pointValues'] as Map<String, dynamic>).map(
                          (key, value) => MapEntry(key, (value as num).toDouble()),
                        ),
                      )
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => FadeTransition(
        opacity:
            Tween<double>(begin: 0.4, end: 1.0).animate(_shimmerController),
        child: Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No $type records",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap 'Record Data' to log a measurement.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 16;

  @override
  double get maxExtent => _tabBar.preferredSize.height + 16;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white.withOpacity(0.9),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}