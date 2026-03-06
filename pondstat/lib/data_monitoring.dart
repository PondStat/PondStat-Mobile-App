import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import 'main.dart';
import 'default_dashboard.dart'; 
import 'profile_bottom_sheet.dart'; 
import 'firestore_helper.dart'; // Import Helper

class MonitoringPage extends StatefulWidget {
  final String pondLetter;
  final String leaderName;
  final bool isLeader; 

  const MonitoringPage({
    super.key,
    required this.pondLetter,
    required this.leaderName,
    required this.isLeader,
  });

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late DateTime _focusedDay;
  DateTime? _selectedDay;

  final List<Map<String, dynamic>> _dailyParameters = const [
    {'label': 'Water Temperature', 'icon': Icons.thermostat_outlined, 'unit': '°C', 'keyboardType': TextInputType.number},
    {'label': 'Air Temperature', 'icon': Icons.air_outlined, 'unit': '°C', 'keyboardType': TextInputType.number},
    {'label': 'pH Level', 'icon': Icons.science_outlined, 'unit': '', 'keyboardType': TextInputType.number},
    {'label': 'Salinity', 'icon': Icons.waves_outlined, 'unit': 'ppm', 'keyboardType': TextInputType.number},
    {'label': 'Feeding Time', 'icon': Icons.local_dining_outlined, 'unit': 'kg', 'keyboardType': TextInputType.number},
  ];

  final List<Map<String, dynamic>> _weeklyParameters = const [
    {'label': 'Microbe Count', 'icon': Icons.mic_outlined, 'unit': 'cells/ml', 'keyboardType': TextInputType.number},
    {'label': 'Phytoplankton Count', 'icon': Icons.nature_outlined, 'unit': 'cells/ml', 'keyboardType': TextInputType.number},
    {'label': 'Zooplankton Count', 'icon': Icons.pets_outlined, 'unit': 'ind/L', 'keyboardType': TextInputType.number},
    {'label': 'Avg Body Weight', 'icon': Icons.fitness_center_outlined, 'unit': 'g', 'keyboardType': TextInputType.number},
  ];

  final List<Map<String, dynamic>> _biweeklyParameters = const [
    {'label': 'Dissolved O2', 'icon': Icons.opacity_outlined, 'unit': 'mg/L', 'keyboardType': TextInputType.number},
    {'label': 'Ammonia', 'icon': Icons.warning_outlined, 'unit': 'ppm', 'keyboardType': TextInputType.number},
    {'label': 'Nitrate', 'icon': Icons.water_drop_outlined, 'unit': 'ppm', 'keyboardType': TextInputType.number},
    {'label': 'Nitrite', 'icon': Icons.water_drop_outlined, 'unit': 'ppm', 'keyboardType': TextInputType.number},
    {'label': 'Alkalinity', 'icon': Icons.balance_outlined, 'unit': 'ppm', 'keyboardType': TextInputType.number},
    {'label': 'Phosphate', 'icon': Icons.data_usage_outlined, 'unit': 'ppm', 'keyboardType': TextInputType.number},
    {'label': 'Ca-Mg Ratio', 'icon': Icons.ac_unit_outlined, 'unit': 'ratio', 'keyboardType': TextInputType.text},
  ];

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
          isTeamLeader: widget.isLeader,
          assignedPond: widget.pondLetter,
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

    final String dateKey = "${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}";

    // Firestore will automatically save this locally if offline, 
    // and push to the cloud when internet returns.
    await FirestoreHelper.measurementsCollection.add({
      'pond': widget.pondLetter,
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
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a day on the calendar first.')),
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Select Parameter for ${_getTabTitle(_tabController.index)}",
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
    final String dateString = "${_selectedDay!.month}/${_selectedDay!.day}/${_selectedDay!.year}";

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
                      const SnackBar(content: Text("Please enter at least one value")),
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
                  ).then((_) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Saved $label: $avg $unit")),
                      );
                    }
                  }).catchError((error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to save: $error")),
                      );
                    }
                  });
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
    final Map<String, Map<String, TextEditingController>> groupControllers = {};
    final List<String> points = const ['A', 'B', 'C', 'D'];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final pointValues = data['pointValues'] as Map<String, dynamic>? ?? {};

      groupControllers[doc.id] = {};

      for (var p in points) {
        String initialValue = pointValues[p]?.toString() ?? '';
        groupControllers[doc.id]![p] = TextEditingController(text: initialValue);
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
                  Text("$label ($unit)", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                try {
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
                  
                  await batch.commit();

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Points updated & Average recalculated")),
                    );
                  }
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

  String _getTabTitle(int index) {
    switch (index) {
      case 0: return "Daily Monitoring";
      case 1: return "Weekly Analysis";
      case 2: return "Biweekly Report";
      default: return "";
    }
  }

  Widget _buildOverlayContent(int index) {
    List<Map<String, dynamic>> parameters;
    switch (index) {
      case 0: parameters = _dailyParameters; break;
      case 1: parameters = _weeklyParameters; break;
      case 2: parameters = _biweeklyParameters; break;
      default: return const Text("Select a tab to add data.");
    }

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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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

  // Visual widget for sync status in the header
  Widget _buildSyncStatus() {
    // Listen to metadata changes to know when data is queued locally vs saved online
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
          message: hasPendingWrites ? "Saving locally (Offline)" : "Synced to Cloud",
          child: Row(
            children: [
              Icon(
                hasPendingWrites ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
                color: hasPendingWrites ? Colors.orange[300] : Colors.white70,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.waves, color: Colors.white, size: 24),
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
                          // Injecting our magical cloud sync icon right here
                          _buildSyncStatus(), 
                        ],
                      ),
                      const Spacer(),
                      
                      GestureDetector(
                        onTap: () => _showProfileSheet(context),
                        child: const Icon(Icons.person_outline, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
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
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Pond ${widget.pondLetter} - ${widget.leaderName}'s Team",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirestoreHelper.measurementsCollection
                                        .where('pond', isEqualTo: widget.pondLetter)
                                        .snapshots(includeMetadataChanges: true), // Request cache awareness
                                    builder: (context, snapshot) {
                                      Map<DateTime, Set<String>> eventsMap = {};
                                      
                                      if (snapshot.hasData) {
                                        for (var doc in snapshot.data!.docs) {
                                          final data = doc.data() as Map<String, dynamic>;
                                          final timestamp = data['timestamp'] as Timestamp?;
                                          final type = data['type'] as String?;

                                          if (timestamp != null && type != null) {
                                            final date = timestamp.toDate();
                                            final normalizedDate = DateTime.utc(
                                                date.year, date.month, date.day);
                                            
                                            if (!eventsMap.containsKey(normalizedDate)) {
                                              eventsMap[normalizedDate] = {};
                                            }
                                            eventsMap[normalizedDate]!.add(type);
                                          }
                                        }
                                      }

                                      return TableCalendar(
                                        firstDay: DateTime.utc(2020, 1, 1),
                                        lastDay: DateTime.utc(2030, 12, 31),
                                        focusedDay: _focusedDay,
                                        availableCalendarFormats: const {
                                          CalendarFormat.month: 'Month'
                                        },
                                        headerStyle: const HeaderStyle(
                                          titleCentered: false,
                                          formatButtonVisible: false,
                                          titleTextStyle: TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        calendarStyle: const CalendarStyle(
                                          cellMargin: EdgeInsets.all(8),
                                          selectedDecoration: BoxDecoration(
                                            color: Color(0xFF0077C2), 
                                            shape: BoxShape.circle,
                                          ),
                                          todayDecoration: BoxDecoration(
                                            color: Colors.blueAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        selectedDayPredicate: (day) =>
                                            isSameDay(_selectedDay, day),
                                        onDaySelected: (selectedDay, focusedDay) {
                                          setState(() {
                                            _selectedDay = DateTime.utc(
                                                selectedDay.year,
                                                selectedDay.month,
                                                selectedDay.day);
                                            _focusedDay = focusedDay;
                                          });
                                        },
                                        calendarBuilders: CalendarBuilders(
                                          markerBuilder: (context, date, events) {
                                            final normalizedDate = DateTime.utc(
                                                date.year, date.month, date.day);
                                            final types = eventsMap[normalizedDate] ?? {};

                                            final hasDaily = types.contains('daily');
                                            final hasWeekly = types.contains('weekly');
                                            final hasBiweekly = types.contains('biweekly');

                                            List<Widget> activeDots = [];
                                            
                                            if (hasDaily) {
                                              activeDots.add(_buildStatusDot(Colors.green));
                                            }
                                            if (hasWeekly) {
                                              activeDots.add(_buildStatusDot(Colors.amber));
                                            }
                                            if (hasBiweekly) {
                                              activeDots.add(_buildStatusDot(Colors.blue));
                                            }

                                            return Positioned(
                                              bottom: 1,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: activeDots
                                                    .map((dot) => Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 1.0),
                                                          child: dot,
                                                        ))
                                                    .toList(),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  const Divider(),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.circle, color: Colors.blueAccent, size: 12),
                                        SizedBox(width: 8),
                                        Text(
                                          "Dates with records",
                                          style: TextStyle(color: Colors.grey, fontSize: 12),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: customBlue,
        shape: const CircleBorder(),
        onPressed: _showAddDataOverlay,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildStreamTab(String type) {
    if (_selectedDay == null) {
      return const Center(child: Text("Select a date to view data"));
    }

    final String dateKey = "${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}";

    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreHelper.measurementsCollection
          .where('pond', isEqualTo: widget.pondLetter)
          .where('type', isEqualTo: type)
          .where('dateKey', isEqualTo: dateKey)
          .orderBy('timestamp', descending: true) // Changed to use standard timestamp vs serverTimestamp for offline safety
          .snapshots(includeMetadataChanges: true), // Enable metadata updates!
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text("No $type data for this date."));

        final Map<String, List<QueryDocumentSnapshot>> groupedData = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final time = data['timeString'] ?? 'Unknown Time';
          if (!groupedData.containsKey(time)) {
            groupedData[time] = [];
          }
          groupedData[time]!.add(doc);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: groupedData.entries.map((entry) {
              final time = entry.key;
              final groupDocs = entry.value;

              String content = groupDocs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return "${d['parameter']}: ${d['value']}${d['unit']}";
              }).join('\n'); 
              
              content += "\n(Avg across Points A, B, C, D)";

              return _infoCard(time, content, groupDocs);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _infoCard(String title, String content, List<QueryDocumentSnapshot> groupDocs) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(content, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _showEditDataDialog(groupDocs); 
                    },
                  ),
                  if (widget.isLeader)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmGroupDelete(groupDocs),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmGroupDelete(List<QueryDocumentSnapshot> docs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Data"),
        content: const Text("Delete all measurements for this time entry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              final batch = FirebaseFirestore.instance.batch();
              for (var doc in docs) {
                batch.delete(doc.reference); // Safely queues deletion offline
              }
              batch.commit();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Entry deleted")),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
}