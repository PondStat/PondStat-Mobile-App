import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/record_form_fields.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/record_submit_button.dart';

class RecordDataSheet extends StatefulWidget {
  final int tabIndex;
  final String species;
  final Future<void> Function({
    required String label,
    required String unit,
    required String timeString,
    required double averageValue,
    required String type,
    required Map<String, double> pointValues,
    required Map<String, List<double>> replicateValues,
    String? notes,
  })
  onSave;
  final List<ParameterItem>? customParams;
  final String? customType;

  const RecordDataSheet({
    super.key,
    required this.tabIndex,
    required this.onSave,
    required this.species,
    this.customParams,
    this.customType,
  });

  @override
  State<RecordDataSheet> createState() => _RecordDataSheetState();
}

class _RecordDataSheetState extends State<RecordDataSheet> {
  ParameterItem? selectedParameter;
  String? selectedDocId;
  List<ParameterItem> _currentParams = [];
  int _currentIndex = 0;
  TimeOfDay selectedTime = TimeOfDay.now();

  final List<String> points = const ['A', 'B', 'C', 'D'];
  final List<int> replicates = const [1, 2, 3];
  late final Map<String, TextEditingController> valueControllers;
  late final Map<String, FocusNode> focusNodes;
  final TextEditingController _notesController = TextEditingController();

  // Bacterial Analysis Controllers
  final TextEditingController _yAvg1Controller = TextEditingController();
  final TextEditingController _yCfu1Controller = TextEditingController();
  final TextEditingController _yAvg2Controller = TextEditingController();
  final TextEditingController _yCfu2Controller = TextEditingController();
  final TextEditingController _gAvg1Controller = TextEditingController();
  final TextEditingController _gCfu1Controller = TextEditingController();
  final TextEditingController _gAvg2Controller = TextEditingController();
  final TextEditingController _gCfu2Controller = TextEditingController();

  bool _isSaving = false;
  final MonitoringRepository _repository = MonitoringRepository();

  final Color primaryBlue = const Color(0xFF0A74DA);
  Color get textDark => Theme.of(context).colorScheme.onSurface;
  Color get textMuted => Theme.of(context).colorScheme.onSurfaceVariant;

  @override
  void initState() {
    super.initState();
    // Create controllers for each replicate of each point
    valueControllers = {};
    focusNodes = {};

    for (var p in points) {
      for (var r in replicates) {
        final key = '$p-$r';
        valueControllers[key] = TextEditingController();
        focusNodes[key] = FocusNode();
      }
    }

    for (var controller in valueControllers.values) {
      controller.addListener(() => setState(() {}));
    }
    for (var node in focusNodes.values) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (var controller in valueControllers.values) {
      controller.dispose();
    }
    for (var node in focusNodes.values) {
      node.dispose();
    }
    _yAvg1Controller.dispose();
    _yCfu1Controller.dispose();
    _yAvg2Controller.dispose();
    _yCfu2Controller.dispose();
    _gAvg1Controller.dispose();
    _gCfu1Controller.dispose();
    _gAvg2Controller.dispose();
    _gCfu2Controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _hasUnsavedData() {
    if (_notesController.text.isNotEmpty) return true;
    for (var controller in valueControllers.values) {
      if (controller.text.isNotEmpty) return true;
    }
    if (_yAvg1Controller.text.isNotEmpty ||
        _yCfu1Controller.text.isNotEmpty ||
        _yAvg2Controller.text.isNotEmpty ||
        _yCfu2Controller.text.isNotEmpty ||
        _gAvg1Controller.text.isNotEmpty ||
        _gCfu1Controller.text.isNotEmpty ||
        _gAvg2Controller.text.isNotEmpty ||
        _gCfu2Controller.text.isNotEmpty) {
      return true;
    }
    return false;
  }

  void _clearInputs() {
    for (var controller in valueControllers.values) {
      controller.clear();
    }
    _notesController.clear();
    _yAvg1Controller.clear();
    _yCfu1Controller.clear();
    _yAvg2Controller.clear();
    _yCfu2Controller.clear();
    _gAvg1Controller.clear();
    _gCfu1Controller.clear();
    _gAvg2Controller.clear();
    _gCfu2Controller.clear();
  }

  void _closeForm() {
    _clearInputs();
    setState(() {
      selectedParameter = null;
      selectedDocId = null;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedData()) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Unsaved Data?'),
        content: const Text(
          'You have entered data that has not been saved yet. Are you sure you want to close this sheet?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  // --- Logic ---

  double? _calculatePointAverage(String point) {
    double sum = 0;
    int count = 0;

    for (var r in replicates) {
      final key = '$point-$r';
      final textVal = valueControllers[key]!.text.trim();
      if (textVal.isNotEmpty) {
        final val = double.tryParse(textVal);
        if (val != null) {
          sum += val;
          count++;
        }
      }
    }

    if (count == 0) return null;
    return double.parse((sum / count).toStringAsFixed(2));
  }

  void _processAndSaveForm({bool keepOpen = false}) async {
    if (selectedParameter == null || _isSaving) return;

    if (selectedParameter!.label == 'Bacterial Analysis') {
      await _saveBacterialAnalysis();
      return;
    }

    double totalSum = 0;
    int pointsWithData = 0;
    Map<String, double> pointValues = {};
    Map<String, List<double>> replicateValues = {};

    // Calculate average for each point
    for (var p in points) {
      final pointAvg = _calculatePointAverage(p);
      if (pointAvg != null) {
        pointValues[p] = pointAvg;
        totalSum += pointAvg;
        pointsWithData++;

        // Collect replicate values for this point
        final replicates = <double>[];
        for (var r in this.replicates) {
          final key = '$p-$r';
          final textVal = valueControllers[key]!.text.trim();
          if (textVal.isNotEmpty) {
            final val = double.tryParse(textVal);
            if (val != null) {
              replicates.add(val);
            }
          }
        }
        if (replicates.isNotEmpty) {
          replicateValues[p] = replicates;
        }
      }
    }

    if (pointsWithData == 0) {
      SnackbarHelper.show(
        context,
        "Please enter at least one valid replicate value",
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    setState(() => _isSaving = true);
    double avg = double.parse((totalSum / pointsWithData).toStringAsFixed(2));
    String type =
        widget.customType ?? ['daily', 'weekly', 'biweekly'][widget.tabIndex];

    try {
      await widget.onSave(
        label: selectedParameter!.label,
        unit: selectedParameter!.unit,
        timeString: selectedTime.format(context),
        averageValue: avg,
        type: type,
        pointValues: pointValues,
        replicateValues: replicateValues,
        notes: _notesController.text.trim(),
      );

      HapticFeedback.heavyImpact();
      if (mounted) {
        if (keepOpen) {
          _clearInputs();
          if (_currentIndex < _currentParams.length - 1) {
            setState(() {
              _currentIndex++;
              selectedParameter = _currentParams[_currentIndex];
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) focusNodes['A-1']?.requestFocus();
            });
          } else {
            _closeForm();
          }
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(
          context,
          "Failed to save: $e",
          backgroundColor: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveBacterialAnalysis({bool keepOpen = false}) async {
    setState(() => _isSaving = true);
    String type =
        widget.customType ?? ['daily', 'weekly', 'biweekly'][widget.tabIndex];
    final timeStr = selectedTime.format(context);
    final notes = _notesController.text.trim();

    final mappings = {
      'Test 10-1 (Average yellow colonies)': {
        'val': _yAvg1Controller.text.trim(),
        'unit': '',
      },
      'Test yellow 10-1 (CFU/ml)': {
        'val': _yCfu1Controller.text.trim(),
        'unit': 'CFU/mL',
      },
      'Test 10-2 (Average yellow colonies)': {
        'val': _yAvg2Controller.text.trim(),
        'unit': '',
      },
      'Test yellow 10-2 (CFU/ml)': {
        'val': _yCfu2Controller.text.trim(),
        'unit': 'CFU/mL',
      },
      'Test 10-1 (Average green colonies)': {
        'val': _gAvg1Controller.text.trim(),
        'unit': '',
      },
      'Test green 10-1 (CFU/ml)': {
        'val': _gCfu1Controller.text.trim(),
        'unit': 'CFU/mL',
      },
      'Test 10-2 (Average green colonies)': {
        'val': _gAvg2Controller.text.trim(),
        'unit': '',
      },
      'Test green 10-2 (CFU/ml)': {
        'val': _gCfu2Controller.text.trim(),
        'unit': 'CFU/mL',
      },
    };

    int saves = 0;
    try {
      for (var entry in mappings.entries) {
        if (entry.value['val']!.isNotEmpty) {
          final doubleVal = double.tryParse(entry.value['val']!);
          if (doubleVal != null) {
            await widget.onSave(
              label: entry.key,
              unit: entry.value['unit']!,
              timeString: timeStr,
              averageValue: doubleVal,
              type: type,
              pointValues: {'A': doubleVal}, // Treated as single point
              replicateValues: {
                'A': [doubleVal],
              },
              notes: notes,
            );
            saves++;
          }
        }
      }

      if (saves == 0) {
        if (mounted) {
          SnackbarHelper.show(
            context,
            "Please enter at least one value",
            backgroundColor: Colors.orange.shade700,
          );
        }
        return;
      }

      HapticFeedback.heavyImpact();
      if (mounted) {
        if (keepOpen) {
          _clearInputs();
          if (_currentIndex < _currentParams.length - 1) {
            setState(() {
              _currentIndex++;
              selectedParameter = _currentParams[_currentIndex];
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) focusNodes['A-1']?.requestFocus();
            });
          } else {
            _closeForm();
          }
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(
          context,
          "Failed to save: $e",
          backgroundColor: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showCreateParameterDialog() {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              "New Parameter",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PondStatTextField(
                  controller: nameController,
                  label: "Parameter Name",
                  hint: "e.g., Turbidity",
                  prefixIcon: Icons.science_outlined,
                ),
                const SizedBox(height: 12),
                PondStatTextField(
                  controller: unitController,
                  label: "Unit",
                  hint: "e.g., NTU",
                  prefixIcon: Icons.straighten_rounded,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    labelText: "Graph Category",
                    prefixIcon: const Icon(
                      Icons.category_rounded,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF0A74DA),
                        width: 2,
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Chemical',
                      child: Text('Chemical'),
                    ),
                    DropdownMenuItem(
                      value: 'Physical',
                      child: Text('Physical'),
                    ),
                    DropdownMenuItem(
                      value: 'Biological',
                      child: Text('Biological'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
              ],
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      unitController.text.isNotEmpty &&
                      selectedCategory != null) {
                    String type =
                        widget.customType ??
                        ['daily', 'weekly', 'biweekly'][widget.tabIndex];
                    await _repository.addCustomParameter(
                      label: nameController.text.trim(),
                      unit: unitController.text.trim(),
                      type: type,
                      category: selectedCategory!,
                    );
                    if (context.mounted) Navigator.pop(context);
                  } else {
                    SnackbarHelper.show(
                      context,
                      "Please fill out all fields",
                      backgroundColor: Colors.orange.shade700,
                    );
                  }
                },
                child: const Text(
                  "Create",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteParameter() {
    if (selectedDocId == null || selectedParameter == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text(
              "Delete Parameter",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          "Delete '${selectedParameter!.label}'? This will remove it for everyone.",
          style: TextStyle(color: textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final idToDelete = selectedDocId!;
              await _repository.deleteCustomParameter(idToDelete);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {
                  selectedParameter = null;
                  selectedDocId = null;
                });
                SnackbarHelper.show(
                  context,
                  "Parameter deleted",
                  backgroundColor: Colors.grey.shade800,
                );
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildParamTile({
    required ParameterItem param,
    String? docId,
    required List<ParameterItem> allParams,
    required int index,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          selectedParameter = param;
          selectedDocId = docId;
          _currentParams = allParams;
          _currentIndex = index;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) focusNodes['A-1']?.requestFocus();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [param.color.withValues(alpha: 0.85), param.color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: param.color.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(param.icon, color: Colors.white, size: 20),
            ),
            Text(
              param.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.2,
                height: 1.1,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewButton() {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _showCreateParameterDialog();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.grey.shade400, size: 28),
            const SizedBox(height: 6),
            Text(
              "Custom",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterGrid() {
    List<ParameterItem> hardcodedParams =
        widget.customParams ??
        MonitoringParameters.getParametersByIndex(
          widget.tabIndex,
          widget.species,
        );
    String type =
        widget.customType ?? ['daily', 'weekly', 'biweekly'][widget.tabIndex];

    if (type == 'growth') {
      List<Widget> gridItems = hardcodedParams.asMap().entries.map((e) {
        return _buildParamTile(
          param: e.value,
          allParams: hardcodedParams,
          index: e.key,
        );
      }).toList();
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: gridItems.length,
        itemBuilder: (context, i) => gridItems[i],
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreHelper.customParametersCollection
          .where('type', isEqualTo: type)
          .snapshots(),
      builder: (context, snapshot) {
        List<ParameterItem> allParams = List.from(hardcodedParams);
        List<String?> docIds = List.filled(hardcodedParams.length, null, growable: true);

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            allParams.add(
              ParameterItem(
                label: data['label'],
                unit: data['unit'] ?? '',
                icon: Icons.dashboard_customize_rounded,
                color: Colors.blueGrey,
                createdBy: data['createdBy'],
              ),
            );
            docIds.add(doc.id);
          }
        }

        List<Widget> gridItems = [];
        for (int i = 0; i < allParams.length; i++) {
          gridItems.add(
            _buildParamTile(
              param: allParams[i],
              docId: docIds[i],
              allParams: allParams,
              index: i,
            ),
          );
        }
        gridItems.add(_buildAddNewButton());

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: gridItems.length,
          itemBuilder: (context, i) => gridItems[i],
        );
      },
    );
  }

  Widget _buildInputForm() {
    final Color themeColor = selectedParameter!.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      selectedParameter!.icon,
                      color: themeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "RECORDING",
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          selectedParameter!.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            color: textDark,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (selectedDocId != null &&
                selectedParameter?.createdBy ==
                    FirebaseAuth.instance.currentUser?.uid)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                onPressed: _confirmDeleteParameter,
              ),
          ],
        ),
        const SizedBox(height: 28),
        _buildTimePickerCard(themeColor),
        const SizedBox(height: 32),
        RecordFormFields(
          selectedParameter: selectedParameter!,
          themeColor: themeColor,
          points: points,
          replicates: replicates,
          valueControllers: valueControllers,
          focusNodes: focusNodes,
          yAvg1Controller: _yAvg1Controller,
          yCfu1Controller: _yCfu1Controller,
          yAvg2Controller: _yAvg2Controller,
          yCfu2Controller: _yCfu2Controller,
          gAvg1Controller: _gAvg1Controller,
          gCfu1Controller: _gCfu1Controller,
          gAvg2Controller: _gAvg2Controller,
          gCfu2Controller: _gCfu2Controller,
          calculatePointAverage: _calculatePointAverage,
          onFieldSubmitted: (key) {
            final keys = valueControllers.keys.toList();
            final currentIndex = keys.indexOf(key);
            if (currentIndex >= 0 && currentIndex < keys.length - 1) {
              FocusScope.of(context).requestFocus(focusNodes[keys[currentIndex + 1]]);
            } else {
              FocusScope.of(context).unfocus();
            }
          },
        ),
        const SizedBox(height: 24),
        PondStatTextField(
          controller: _notesController,
          label: "Notes or Findings (Optional)",
          hint: "e.g., Water looks slightly cloudy today",
          prefixIcon: Icons.notes_rounded,
          maxLines: 3,
        ),
        const SizedBox(height: 32),
        RecordSubmitButton(
          isSaving: _isSaving,
          themeColor: themeColor,
          isLastParameter: _currentIndex >= _currentParams.length - 1,
          onSaveNext: () => _processAndSaveForm(keepOpen: true),
          onSaveFinish: () => _processAndSaveForm(keepOpen: false),
        ),
      ],
    );
  }

  Widget _buildTimePickerCard(Color themeColor) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: selectedTime,
        );
        if (picked != null) {
          HapticFeedback.selectionClick();
          setState(() => selectedTime = picked);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white10
                : Colors.grey.shade100,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time_filled_rounded,
                    color: textMuted,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  selectedTime.format(context),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: textDark,
                  ),
                ),
              ],
            ),
            Text(
              "Edit",
              style: TextStyle(color: themeColor, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          top: 12,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              _buildSheetHeader(),
              const SizedBox(height: 16),
              _buildContentSwitcher(),
            ],
          ),
        ),
      ),
    );
  }

  void _goToPreviousParameter() {
    if (_currentIndex > 0) {
      _clearInputs();
      setState(() {
        _currentIndex--;
        selectedParameter = _currentParams[_currentIndex];
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) focusNodes['A-1']?.requestFocus();
      });
    }
  }

  void _goToNextParameter() {
    if (_currentIndex < _currentParams.length - 1) {
      _clearInputs();
      setState(() {
        _currentIndex++;
        selectedParameter = _currentParams[_currentIndex];
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) focusNodes['A-1']?.requestFocus();
      });
    }
  }

  Widget _buildSheetHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (selectedParameter != null)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_rounded, size: 20, color: textDark),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              _closeForm();
            },
          ),
        Expanded(
          child: selectedParameter == null
              ? Text(
                  "Select Parameter",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                    letterSpacing: -0.5,
                  ),
                )
              : Row(
                  children: [
                    Text(
                      "Enter Data",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: _currentIndex > 0
                          ? _goToPreviousParameter
                          : null,
                      color: _currentIndex > 0
                          ? primaryBlue
                          : Colors.grey.shade300,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _currentIndex < _currentParams.length - 1
                          ? _goToNextParameter
                          : null,
                      color: _currentIndex < _currentParams.length - 1
                          ? primaryBlue
                          : Colors.grey.shade300,
                    ),
                  ],
                ),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded, size: 20, color: textMuted),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildContentSwitcher() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: selectedParameter == null
          ? KeyedSubtree(
              key: const ValueKey('grid'),
              child: _buildParameterGrid(),
            )
          : KeyedSubtree(key: const ValueKey('form'), child: _buildInputForm()),
    );
  }
}
