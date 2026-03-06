import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../profile_bottom_sheet.dart';
import '../firebase/firestore_helper.dart';
import 'monitoring_parameters.dart';
import 'measurement_card.dart';
import 'monitoring_calendar.dart';

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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late DateTime _focusedDay;
  DateTime? _selectedDay;

  bool get canEdit => widget.userRole == 'owner' || widget.userRole == 'editor';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = DateTime.utc(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ProfileBottomSheet(
          isTeamLeader: widget.userRole == 'owner',
          assignedPond: null,
          onRoleChanged: (isLeader) {
            Navigator.pop(context);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AuthWrapper()),
              (route) => false,
            );
          },
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

    await FirestoreHelper.measurementsCollection.add({
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
  }

  void _showAddDataOverlay() {
    if (!canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You need Editor or Owner permissions to add data.')),
      );
      return;
    }

    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a day on the calendar first.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Add Data for ${_selectedDay!.month}/${_selectedDay!.day}/${_selectedDay!.year}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Select Parameter for ${MonitoringParameters.getTabTitle(_tabController.index)}",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const Divider(),
                _buildOverlayContent(_tabController.index),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showParameterInputOverlay(Map<String, dynamic> parameter) {
    Navigator.pop(context);

    final String label = parameter['label'];
    final String unit = parameter['unit'];
    final TextInputType keyboardType = parameter['keyboardType'];
    final List<String> points = const ['A', 'B', 'C', 'D'];
    final String dateString =
        "${_selectedDay!.month}/${_selectedDay!.day}/${_selectedDay!.year}";

    TimeOfDay? selectedTime = TimeOfDay.now();
    Map<String, TextEditingController> valueControllers = {
      for (var p in points) p: TextEditingController()
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            scrollable: true,
            title: Text('Record $label ${unit.isNotEmpty ? "($unit)" : ""}'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Date: $dateString"),
                const Divider(),
                TextButton(
                  onPressed: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedTime = picked);
                    }
                  },
                  child: Text(selectedTime != null
                      ? "Selected Time: ${selectedTime!.format(context)}"
                      : "Select Time"),
                ),
                const SizedBox(height: 10),
                Column(
                  children: points.map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: valueControllers[p],
                        keyboardType: keyboardType,
                        decoration: InputDecoration(
                          labelText: "Point $p Value ($unit)",
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  double sum = 0;
                  int count = 0;
                  Map<String, double> pointValues = {};

                  for (var p in points) {
                    final val = double.tryParse(valueControllers[p]!.text);
                    if (val != null) {
                      sum += val;
                      count++;
                      pointValues[p] = val;
                    }
                  }

                  if (count == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please enter at least one value")),
                    );
                    return;
                  }

                  double avg = sum / count;
                  avg = double.parse(avg.toStringAsFixed(2));

                  String type = 'daily';
                  if (_tabController.index == 1) type = 'weekly';
                  if (_tabController.index == 2) type = 'biweekly';

                  _saveDataToFirestore(
                    label: label,
                    unit: unit,
                    timeString: selectedTime!.format(context),
                    averageValue: avg,
                    type: type,
                    pointValues: pointValues,
                  ).catchError((error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to save: $error")),
                      );
                    }
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Saved $label: $avg $unit")),
                  );
                },
                child: const Text("Save"),
              )
            ],
          ),
        );
      },
    );
  }

  void _showEditDataDialog(List<QueryDocumentSnapshot> docs) {
    if (!canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You need Editor or Owner permissions to edit data.')),
      );
      return;
    }

    final Map<String, Map<String, TextEditingController>> groupControllers = {};
    final List<String> points = const ['A', 'B', 'C', 'D'];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final pointValues = data['pointValues'] as Map<String, dynamic>? ?? {};

      groupControllers[doc.id] = {};

      for (var p in points) {
        String initialValue = pointValues[p]?.toString() ?? '';
        groupControllers[doc.id]![p] =
            TextEditingController(text: initialValue);
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Edit Point Values'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String label = data['parameter'];
              final String unit = data['unit'] ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$label ($unit)",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: points.map((p) {
                      return SizedBox(
                        width: 60,
                        child: TextField(
                          controller: groupControllers[doc.id]![p],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: p,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 24),
                ],
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final batch = FirebaseFirestore.instance.batch();

                for (var doc in docs) {
                  final controllersMap = groupControllers[doc.id];
                  if (controllersMap == null) continue;

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
                    double newAvg = sum / count;
                    newAvg = double.parse(newAvg.toStringAsFixed(2));

                    batch.update(doc.reference, {
                      'pointValues': newPointValues,
                      'value': newAvg,
                    });
                  }
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Points updated & Average recalculated")),
                );

                try {
                  await batch.commit();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error updating: $e")),
                    );
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

  Widget _buildOverlayContent(int index) {
    List<Map<String, dynamic>> parameters =
        MonitoringParameters.getParametersByIndex(index);
    if (parameters.isEmpty) return const Text("Select a tab to add data.");

    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    double padding = 32.0;
    double spacing = 10.0;
    double itemWidth = (screenWidth - padding - spacing) / crossAxisCount;
    double itemHeight = 75.0;
    double childAspectRatio = itemWidth / itemHeight;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: parameters.length,
      itemBuilder: (context, i) {
        final param = parameters[i];
        return InkWell(
          onTap: () => _showParameterInputOverlay(param),
          child: Card(
            elevation: 2,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Icon(param['icon'] as IconData, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        param['label'] as String,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
        bool hasPendingWrites = false;

        if (snapshot.hasData) {
          hasPendingWrites = snapshot.data!.metadata.hasPendingWrites;
        }

        return Tooltip(
          message:
              hasPendingWrites ? "Saving locally (Offline)" : "Synced to Cloud",
          child: Row(
            children: [
              Icon(
                hasPendingWrites
                    ? Icons.cloud_upload_outlined
                    : Icons.cloud_done_outlined,
                color: hasPendingWrites
                    ? Colors.orange[300]
                    : Colors.lightGreenAccent,
                size: 20,
              ),
              if (hasPendingWrites) ...[
                const SizedBox(width: 4),
                Text(
                  "Offline mode",
                  style: TextStyle(color: Colors.orange[300], fontSize: 10),
                )
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color customBlue = Color(0xFF0077C2);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              color: customBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.waves,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PondStat",
                            style: TextStyle(
                              color: Colors.white,
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
                        child: const Icon(Icons.person_outline,
                            color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Monitoring",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.pondName,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
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
                                            selectedDay.day);
                                        _focusedDay = focusedDay;
                                      });
                                    },
                                  ),
                                  const Divider(),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.circle,
                                            color: Colors.blueAccent, size: 12),
                                        SizedBox(width: 8),
                                        Text(
                                          "Dates with records",
                                          style: TextStyle(
                                              color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: const Color(0xFF0077C2),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey,
                              dividerColor: Colors.transparent,
                              labelPadding: EdgeInsets.zero,
                              tabs: [
                                Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildStatusDot(Colors.green),
                                      const SizedBox(width: 8),
                                      const Text("Daily"),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildStatusDot(Colors.amber),
                                      const SizedBox(width: 8),
                                      const Text("Weekly"),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildStatusDot(Colors.blue),
                                      const SizedBox(width: 8),
                                      const Text("Biweekly"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 400,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildStreamTab('daily'),
                                _buildStreamTab('weekly'),
                                _buildStreamTab('biweekly'),
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
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              backgroundColor: customBlue,
              shape: const CircleBorder(),
              onPressed: _showAddDataOverlay,
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            )
          : null,
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
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text("No $type data for this date."));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final time = data['timeString'] ?? 'Unknown Time';
            final parameter = data['parameter'] ?? 'Unknown Parameter';
            final value = data['value']?.toString() ?? '0';
            final unit = data['unit'] ?? '';

            final title = "$parameter";
            final content = "$value $unit\n(Avg across recorded points)";

            return MeasurementCard(
              time: time,
              title: title,
              content: content,
              canEdit: canEdit,
              groupDocs: [doc],
              onEdit: () => _showEditDataDialog([doc]),
            );
          },
        );
      },
    );
  }
}