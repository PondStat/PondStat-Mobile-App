import 'package:flutter/material.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';

class RecordFormFields extends StatefulWidget {
  final ParameterItem selectedParameter;
  final Color themeColor;
  final List<String> points;
  final List<int> replicates;
  final Map<String, TextEditingController> valueControllers;
  final Map<String, FocusNode> focusNodes;
  final TextEditingController yAvg1Controller;
  final TextEditingController yCfu1Controller;
  final TextEditingController yAvg2Controller;
  final TextEditingController yCfu2Controller;
  final TextEditingController gAvg1Controller;
  final TextEditingController gCfu1Controller;
  final TextEditingController gAvg2Controller;
  final TextEditingController gCfu2Controller;
  final double? Function(String) calculatePointAverage;
  final Function(String) onFieldSubmitted;

  const RecordFormFields({
    super.key,
    required this.selectedParameter,
    required this.themeColor,
    required this.points,
    required this.replicates,
    required this.valueControllers,
    required this.focusNodes,
    required this.yAvg1Controller,
    required this.yCfu1Controller,
    required this.yAvg2Controller,
    required this.yCfu2Controller,
    required this.gAvg1Controller,
    required this.gCfu1Controller,
    required this.gAvg2Controller,
    required this.gCfu2Controller,
    required this.calculatePointAverage,
    required this.onFieldSubmitted,
  });

  @override
  State<RecordFormFields> createState() => _RecordFormFieldsState();
}

class _RecordFormFieldsState extends State<RecordFormFields> {
  int _bacterialTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool hasRange =
        widget.selectedParameter.absoluteMin != null &&
        widget.selectedParameter.absoluteMax != null;

    if (widget.selectedParameter.label == 'Bacterial Analysis') {
      return _buildBacterialAnalysisUI(context, widget.themeColor);
    }

    return Column(
      children: [
        _buildDataPointsHeader(context, hasRange, widget.themeColor),
        const SizedBox(height: 16),
        _buildDataPointInputs(context, widget.themeColor),
      ],
    );
  }

  Widget _buildDataPointsHeader(
    BuildContext context,
    bool hasRange,
    Color themeColor,
  ) {
    Color textDark = Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Data Points",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: textDark,
                fontSize: 18,
              ),
            ),
            if (hasRange) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Safe Range: ${widget.selectedParameter.absoluteMin} - ${widget.selectedParameter.absoluteMax}",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (widget.selectedParameter.absoluteMin != null) ...[
              const SizedBox(height: 4),
              Text(
                "Minimum: ${widget.selectedParameter.absoluteMin}",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (widget.selectedParameter.absoluteMax != null) ...[
              const SizedBox(height: 4),
              Text(
                "Maximum: ${widget.selectedParameter.absoluteMax}",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        if (widget.selectedParameter.unit.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.selectedParameter.unit,
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDataPointInputs(BuildContext context, Color themeColor) {
    Color textDark = Theme.of(context).colorScheme.onSurface;

    if (widget.selectedParameter.isSinglePoint) {
      // For single point parameters, show 1 input value (treated as Point A, Replicate 1 behind the scenes)
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildReplicateInput(
          context,
          'A',
          1,
          themeColor,
          customLabel: "Value",
          isLast: true,
        ),
      );
    }

    // For multi-point parameters, show each point with its 3 replicates and average
    return Column(
      children: [
        for (int pIdx = 0; pIdx < widget.points.length; pIdx++)
          Container(
            margin: EdgeInsets.only(
              bottom: pIdx < widget.points.length - 1 ? 16 : 0,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Point header
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Point ${widget.points[pIdx]}",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: textDark,
                    ),
                  ),
                ),
                // Replicate inputs
                Row(
                  children: [
                    for (int rIdx = 0; rIdx < widget.replicates.length; rIdx++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: rIdx < widget.replicates.length - 1 ? 8 : 0,
                          ),
                          child: _buildReplicateInput(
                            context,
                            widget.points[pIdx],
                            widget.replicates[rIdx],
                            themeColor,
                            isCompact: true,
                            isLast:
                                (pIdx == widget.points.length - 1) &&
                                (rIdx == widget.replicates.length - 1),
                          ),
                        ),
                      ),
                  ],
                ),
                // Average display for this point
                const SizedBox(height: 10),
                _buildAverageDisplay(context, widget.points[pIdx], themeColor),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBacterialAnalysisUI(BuildContext context, Color themeColor) {
    Color textMuted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _bacterialTabIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _bacterialTabIndex == 0
                          ? themeColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "Yellow Colonies",
                        style: TextStyle(
                          color: _bacterialTabIndex == 0
                              ? Colors.white
                              : textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _bacterialTabIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _bacterialTabIndex == 1
                          ? themeColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "Green Colonies",
                        style: TextStyle(
                          color: _bacterialTabIndex == 1
                              ? Colors.white
                              : textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Switch between Yellow and Green Tabs without TabBarView fixed height
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _bacterialTabIndex == 0
              ? _buildBacterialTabContent(context, [
                  (
                    widget.yAvg1Controller,
                    "Test 10-1 (Average)",
                    Icons.circle_rounded,
                    "e.g., 100",
                  ),
                  (
                    widget.yCfu1Controller,
                    "Test 10-1 (CFU/ml)",
                    Icons.science_rounded,
                    "e.g., 10000",
                  ),
                  (
                    widget.yAvg2Controller,
                    "Test 10-2 (Average)",
                    Icons.circle_rounded,
                    "e.g., 100",
                  ),
                  (
                    widget.yCfu2Controller,
                    "Test 10-2 (CFU/ml)",
                    Icons.science_rounded,
                    "e.g., 10000",
                  ),
                ])
              : _buildBacterialTabContent(context, [
                  (
                    widget.gAvg1Controller,
                    "Test 10-1 (Average)",
                    Icons.circle_rounded,
                    "e.g., 100",
                  ),
                  (
                    widget.gCfu1Controller,
                    "Test 10-1 (CFU/ml)",
                    Icons.science_rounded,
                    "e.g., 10000",
                  ),
                  (
                    widget.gAvg2Controller,
                    "Test 10-2 (Average)",
                    Icons.circle_rounded,
                    "e.g., 100",
                  ),
                  (
                    widget.gCfu2Controller,
                    "Test 10-2 (CFU/ml)",
                    Icons.science_rounded,
                    "e.g., 10000",
                  ),
                ]),
        ),
      ],
    );
  }

  Widget _buildBacterialTabContent(
    BuildContext context,
    List<(TextEditingController, String, IconData, String)> fields,
  ) {
    return Column(
      key: ValueKey(_bacterialTabIndex),
      children: [
        for (var field in fields) ...[
          PondStatTextField(
            controller: field.$1,
            label: field.$2,
            hint: field.$4,
            prefixIcon: field.$3,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildReplicateInput(
    BuildContext context,
    String point,
    int replicate,
    Color themeColor, {
    bool isCompact = false,
    String? customLabel,
    bool isLast = false,
  }) {
    Color textDark = Theme.of(context).colorScheme.onSurface;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final key = '$point-$replicate';
    final bool isFocused = widget.focusNodes[key]?.hasFocus ?? false;
    final controller = widget.valueControllers[key]!;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        String? errorMessage;
        if (value.text.isNotEmpty) {
          final parsedValue = double.tryParse(value.text);
          if (parsedValue != null) {
            if (widget.selectedParameter.absoluteMin != null &&
                parsedValue < widget.selectedParameter.absoluteMin!) {
              errorMessage = "Min: ${widget.selectedParameter.absoluteMin}";
            }
            if (widget.selectedParameter.absoluteMax != null &&
                parsedValue > widget.selectedParameter.absoluteMax!) {
              errorMessage = "Max: ${widget.selectedParameter.absoluteMax}";
            }
          }
        }

        final bool hasError = errorMessage != null;
        final activeColor = hasError ? theme.colorScheme.error : themeColor;

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isFocused
                    ? theme.colorScheme.surface
                    : (isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFocused || hasError
                      ? activeColor
                      : Colors.transparent,
                  width: isFocused || hasError ? 2 : 0,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TextField(
                    controller: controller,
                    focusNode: widget.focusNodes[key],
                    keyboardType: widget.selectedParameter.keyboardType,
                    textInputAction: isLast
                        ? TextInputAction.done
                        : TextInputAction.next,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: isCompact ? 14 : 18,
                      color: hasError ? theme.colorScheme.error : textDark,
                    ),
                    onSubmitted: (_) {
                      widget.onFieldSubmitted(key);
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isCompact ? 8 : 16,
                      ),
                      hintText: isCompact
                          ? '0.0'
                          : widget.selectedParameter.hint,
                      hintStyle: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.4),
                        fontSize: isCompact ? 12 : 14,
                      ),
                    ),
                  ),
                  if (hasError)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            if (hasError && !isCompact)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAverageDisplay(
    BuildContext context,
    String point,
    Color themeColor,
  ) {
    Color textMuted = Theme.of(context).colorScheme.onSurfaceVariant;
    final average = widget.calculatePointAverage(point);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, color: themeColor, size: 18),
              const SizedBox(width: 8),
              Text(
                "Average for Point $point",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: textMuted,
                ),
              ),
            ],
          ),
          Text(
            average != null ? average.toString() : "—",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: themeColor,
            ),
          ),
        ],
      ),
    );
  }
}
