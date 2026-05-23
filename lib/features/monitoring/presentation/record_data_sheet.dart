import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/record_form_fields.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/record_submit_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/core/widgets/primary_button.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/all_recorded_state_card.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/create_parameter_dialog.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/delete_parameter_dialog.dart';

class RecordDataSheet extends ConsumerStatefulWidget {
  final int tabIndex;
  final String species;
  final String pondId;
  final DateTime selectedDay;
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
    required this.pondId,
    required this.selectedDay,
    this.customParams,
    this.customType,
  });

  @override
  ConsumerState<RecordDataSheet> createState() => _RecordDataSheetState();
}

class _RecordDataSheetState extends ConsumerState<RecordDataSheet> {
  ParameterItem? selectedParameter;
  String? selectedDocId;
  TimeOfDay selectedTime = TimeOfDay.now();

  // Wizard state
  final List<ParameterItem> _wizardSequence = [];
  final List<String?> _wizardDocIds = [];
  bool _isWizardStarted = false;
  int _wizardStepIndex = 0;

  final List<String> points = const ['A', 'B', 'C', 'D'];
  final List<int> replicates = const [1, 2, 3];
  late final Map<String, TextEditingController> valueControllers;
  late final Map<String, FocusNode> focusNodes;
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;

  Color get textDark => Theme.of(context).colorScheme.onSurface;
  Color get textMuted => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get primaryColor => Theme.of(context).colorScheme.primary;



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

    _notesController.dispose();
    super.dispose();
  }

  bool _hasUnsavedData() {
    if (_notesController.text.isNotEmpty) return true;
    for (var controller in valueControllers.values) {
      if (controller.text.isNotEmpty) return true;
    }

    return false;
  }

  void _clearInputs() {
    for (var controller in valueControllers.values) {
      controller.clear();
    }
    _notesController.clear();
  }

  void _closeForm() {
    _clearInputs();
    setState(() {
      selectedParameter = null;
      selectedDocId = null;
      _isWizardStarted = false;
      _wizardSequence.clear();
      _wizardDocIds.clear();
      _wizardStepIndex = 0;
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



    // Validate that all entered values are valid numbers (typo safety)
    for (var p in points) {
      for (var r in replicates) {
        final key = '$p-$r';
        final textVal = valueControllers[key]!.text.trim();
        if (textVal.isNotEmpty) {
          final val = double.tryParse(textVal);
          if (val == null) {
            SnackbarHelper.showError(
              context,
              "Invalid value at Point $p, Replicate $r: '$textVal' is not a valid number",
            );
            return;
          }
        }
      }
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
      SnackbarHelper.showInfo(context, "Please enter at least one valid replicate value");
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
          if (_wizardStepIndex < _wizardSequence.length - 1) {
            setState(() {
              _wizardStepIndex++;
              selectedParameter = _wizardSequence[_wizardStepIndex];
              selectedDocId = _wizardDocIds[_wizardStepIndex];
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
        SnackbarHelper.showError(context, "Failed to save: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }



  void _showCreateParameterDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateParameterDialog(
        pondId: widget.pondId,
        tabIndex: widget.tabIndex,
        customType: widget.customType,
      ),
    );
  }

  void _confirmDeleteParameter() {
    if (selectedDocId == null || selectedParameter == null) return;

    showDialog<bool>(
      context: context,
      builder: (context) => DeleteParameterDialog(
        label: selectedParameter!.label,
        docId: selectedDocId!,
      ),
    ).then((deleted) {
      if (deleted == true && mounted) {
        setState(() {
          selectedParameter = null;
          selectedDocId = null;
        });
        SnackbarHelper.showInfo(context, "Parameter deleted");
      }
    });
  }

  // --- UI Helpers ---

  Widget _buildParamTile({
    required ParameterItem param,
    String? docId,
    required List<ParameterItem> allParams,
    required int index,
  }) {
    bool isSelected = _wizardSequence.contains(param);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            final idx = _wizardSequence.indexOf(param);
            _wizardSequence.removeAt(idx);
            _wizardDocIds.removeAt(idx);
          } else {
            _wizardSequence.add(param);
            _wizardDocIds.add(docId);
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    param.getColor(context).withValues(alpha: 0.85),
                    param.getColor(context),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? param.getColor(context) : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: param.getColor(context).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : param.getColor(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    param.icon,
                    color: isSelected ? Colors.white : param.getColor(context),
                    size: 20,
                  ),
                ),
                Text(
                  param.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : textDark,
                    letterSpacing: -0.2,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: param.getColor(context),
                  ),
                ),
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
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: Theme.of(context).colorScheme.outline,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              "Custom",
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
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

    List<Widget> gridItems = [];

    if (type == 'growth') {
      gridItems = hardcodedParams.asMap().entries.map((e) {
        return _buildParamTile(
          param: e.value,
          docId: null,
          allParams: hardcodedParams,
          index: e.key,
        );
      }).toList();
      return _buildGridWithStartButton(gridItems);
    }

    final String dateKey =
        "${widget.selectedDay.year}-${widget.selectedDay.month}-${widget.selectedDay.day}";

    return StreamBuilder<QuerySnapshot>(
      stream: ref.read(monitoringRepositoryProvider).customParametersCollection
          .where('type', isEqualTo: type)
          .where('pondId', isEqualTo: widget.pondId)
          .snapshots(),
      builder: (context, customSnapshot) {
        List<ParameterItem> allParams = List.from(hardcodedParams);
        List<String?> docIds = List.filled(
          hardcodedParams.length,
          null,
          growable: true,
        );

        if (customSnapshot.hasData) {
          for (var doc in customSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            allParams.add(
              ParameterItem(
                label: data['label'],
                unit: data['unit'] ?? '',
                icon: Icons.dashboard_customize_rounded,
                category: ParameterCategory.custom,
                createdBy: data['createdBy'],
              ),
            );
            docIds.add(doc.id);
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: ref.read(monitoringRepositoryProvider).measurementsCollection
              .where('pondId', isEqualTo: widget.pondId)
              .where('type', isEqualTo: type)
              .where('dateKey', isEqualTo: dateKey)
              .snapshots(),
          builder: (context, measurementsSnapshot) {
            final Set<String> recordedLabels = {};
            if (measurementsSnapshot.hasData) {
              for (var doc in measurementsSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['parameter'] != null) {
                  recordedLabels.add(data['parameter'] as String);
                }
              }
            }

            final List<ParameterItem> filteredParams = [];
            final List<String?> filteredDocIds = [];

            for (int i = 0; i < allParams.length; i++) {
              if (!recordedLabels.contains(allParams[i].label)) {
                filteredParams.add(allParams[i]);
                filteredDocIds.add(docIds[i]);
              }
            }

            if (filteredParams.isEmpty) {
              return AllRecordedStateCard(
                onAddCustomParameter: _showCreateParameterDialog,
              );
            }

            List<Widget> items = [];
            for (int i = 0; i < filteredParams.length; i++) {
              items.add(
                _buildParamTile(
                  param: filteredParams[i],
                  docId: filteredDocIds[i],
                  allParams: filteredParams,
                  index: i,
                ),
              );
            }
            items.add(_buildAddNewButton());
            return _buildGridWithStartButton(items);
          },
        );
      },
    );
  }

  Widget _buildGridWithStartButton(List<Widget> gridItems) {
    return Column(
      children: [
        GridView.builder(
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
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: _wizardSequence.isNotEmpty
              ? Column(
                  key: const ValueKey('start_button_area'),
                  children: [
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: "Start Recording (${_wizardSequence.length})",
                      icon: Icons.play_arrow_rounded,
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        setState(() {
                          _isWizardStarted = true;
                          _wizardStepIndex = 0;
                          selectedParameter = _wizardSequence[_wizardStepIndex];
                          selectedDocId = _wizardDocIds[_wizardStepIndex];
                        });
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) focusNodes['A-1']?.requestFocus();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _wizardSequence.clear();
                          _wizardDocIds.clear();
                        });
                      },
                      child: Text(
                        "Clear Selection",
                        style: TextStyle(
                          color: textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(key: ValueKey('empty_start_button')),
        ),
      ],
    );
  }

  Widget _buildInputForm() {
    final Color themeColor = selectedParameter!.getColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress Indicator
        if (_isWizardStarted) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Step ${_wizardStepIndex + 1} of ${_wizardSequence.length}",
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "${((_wizardStepIndex + 1) / _wizardSequence.length * 100).toInt()}%",
                      style: TextStyle(
                        color: themeColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_wizardStepIndex + 1) / _wizardSequence.length,
                    backgroundColor: themeColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
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
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            selectedParameter!.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              color: textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
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
                    color: Theme.of(context).colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
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
          calculatePointAverage: _calculatePointAverage,
          onFieldSubmitted: (key) {
            final keys = valueControllers.keys.toList();
            final currentIndex = keys.indexOf(key);
            if (currentIndex >= 0 && currentIndex < keys.length - 1) {
              FocusScope.of(
                context,
              ).requestFocus(focusNodes[keys[currentIndex + 1]]);
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
          isLastParameter: _wizardStepIndex >= _wizardSequence.length - 1,
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
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
                    color: Theme.of(context).colorScheme.surface,
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
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
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
                      color: Theme.of(context).colorScheme.outlineVariant,
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
      ),
    );
  }

  Future<void> _goToPreviousParameter() async {
    if (_wizardStepIndex > 0) {
      if (_hasUnsavedData()) {
        final shouldDiscard = await _onWillPop();
        if (!shouldDiscard) return;
      }
      HapticFeedback.selectionClick();
      _clearInputs();
      setState(() {
        _wizardStepIndex--;
        selectedParameter = _wizardSequence[_wizardStepIndex];
        selectedDocId = _wizardDocIds[_wizardStepIndex];
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) focusNodes['A-1']?.requestFocus();
      });
    }
  }

  Future<void> _goToNextParameter() async {
    if (_wizardStepIndex < _wizardSequence.length - 1) {
      if (_hasUnsavedData()) {
        final shouldDiscard = await _onWillPop();
        if (!shouldDiscard) return;
      }
      HapticFeedback.selectionClick();
      _clearInputs();
      setState(() {
        _wizardStepIndex++;
        selectedParameter = _wizardSequence[_wizardStepIndex];
        selectedDocId = _wizardDocIds[_wizardStepIndex];
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
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                      onPressed: _wizardStepIndex > 0
                          ? _goToPreviousParameter
                          : null,
                      color: _wizardStepIndex > 0
                          ? primaryColor
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _wizardStepIndex < _wizardSequence.length - 1
                          ? _goToNextParameter
                          : null,
                      color: _wizardStepIndex < _wizardSequence.length - 1
                          ? primaryColor
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ],
                ),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
