import 'package:flutter/material.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';

class RecordFormFields extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool hasRange =
        selectedParameter.absoluteMin != null && selectedParameter.absoluteMax != null;

    if (selectedParameter.label == 'Bacterial Analysis') {
      return _buildBacterialAnalysisUI(context, themeColor);
    }

    return Column(
      children: [
        _buildDataPointsHeader(context, hasRange, themeColor),
        const SizedBox(height: 16),
        _buildDataPointInputs(context, themeColor),
      ],
    );
  }

  Widget _buildDataPointsHeader(
    BuildContext context,
    bool hasRange,
    Color themeColor,
  ) {
    Color textDark = Theme.of(context).colorScheme.onSurface;
    Color textMuted = Theme.of(context).colorScheme.onSurfaceVariant;

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
              const SizedBox(height: 4),
              Row(
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
                    "Safe Range: ${selectedParameter.absoluteMin} - ${selectedParameter.absoluteMax}",
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ] else if (selectedParameter.absoluteMin != null) ...[
              const SizedBox(height: 4),
              Text(
                "Minimum: ${selectedParameter.absoluteMin}",
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (selectedParameter.absoluteMax != null) ...[
              const SizedBox(height: 4),
              Text(
                "Maximum: ${selectedParameter.absoluteMax}",
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        if (selectedParameter.unit.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              selectedParameter.unit,
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

    if (selectedParameter.isSinglePoint) {
      // For single point parameters, show 1 input value (treated as Point A, Replicate 1 behind the scenes)
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildReplicateInput(
          context,
          'A',
          1,
          themeColor,
          customLabel: "Value",
        ),
      );
    }

    // For multi-point parameters, show each point with its 3 replicates and average
    return Column(
      children: [
        for (int pIdx = 0; pIdx < points.length; pIdx++)
          Container(
            margin: EdgeInsets.only(bottom: pIdx < points.length - 1 ? 16 : 0),
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
                    "Point ${points[pIdx]}",
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
                    for (int rIdx = 0; rIdx < replicates.length; rIdx++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: rIdx < replicates.length - 1 ? 8 : 0,
                          ),
                          child: _buildReplicateInput(
                            context,
                            points[pIdx],
                            replicates[rIdx],
                            themeColor,
                            isCompact: true,
                          ),
                        ),
                      ),
                  ],
                ),
                // Average display for this point
                const SizedBox(height: 10),
                _buildAverageDisplay(context, points[pIdx], themeColor),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBacterialAnalysisUI(BuildContext context, Color themeColor) {
    Color textMuted = Theme.of(context).colorScheme.onSurfaceVariant;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Yellow Colonies"),
                Tab(text: "Green Colonies"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 380, // Fixed height for inputs
            child: TabBarView(
              children: [
                // Yellow Tab
                ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    PondStatTextField(
                      controller: yAvg1Controller,
                      label: "Test 10-1 (Average)",
                      hint: "e.g., 100",
                      prefixIcon: Icons.circle_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PondStatTextField(
                      controller: yCfu1Controller,
                      label: "Test 10-1 (CFU/ml)",
                      hint: "e.g., 10000",
                      prefixIcon: Icons.science_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PondStatTextField(
                      controller: yAvg2Controller,
                      label: "Test 10-2 (Average)",
                      hint: "e.g., 100",
                      prefixIcon: Icons.circle_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PondStatTextField(
                      controller: yCfu2Controller,
                      label: "Test 10-2 (CFU/ml)",
                      hint: "e.g., 10000",
                      prefixIcon: Icons.science_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
                // Green Tab
                ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    PondStatTextField(
                      controller: gAvg1Controller,
                      label: "Test 10-1 (Average)",
                      hint: "e.g., 100",
                      prefixIcon: Icons.circle_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PondStatTextField(
                      controller: gCfu1Controller,
                      label: "Test 10-1 (CFU/ml)",
                      hint: "e.g., 10000",
                      prefixIcon: Icons.science_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PondStatTextField(
                      controller: gAvg2Controller,
                      label: "Test 10-2 (Average)",
                      hint: "e.g., 100",
                      prefixIcon: Icons.circle_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PondStatTextField(
                      controller: gCfu2Controller,
                      label: "Test 10-2 (CFU/ml)",
                      hint: "e.g., 10000",
                      prefixIcon: Icons.science_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplicateInput(
    BuildContext context,
    String point,
    int replicate,
    Color themeColor, {
    bool isCompact = false,
    String? customLabel,
  }) {
    Color textDark = Theme.of(context).colorScheme.onSurface;

    final key = '$point-$replicate';
    final bool isFocused = focusNodes[key]?.hasFocus ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isFocused ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? themeColor : Colors.transparent,
          width: isFocused ? 2 : 0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: valueControllers[key],
        focusNode: focusNodes[key],
        keyboardType: selectedParameter.keyboardType,
        textInputAction: TextInputAction.next,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: isCompact ? 14 : 18,
          color: textDark,
        ),
        onSubmitted: (_) {
          onFieldSubmitted(key);
        },
        decoration: InputDecoration(
          labelText:
              customLabel ??
              (isCompact ? "R$replicate" : "Replicate $replicate"),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(
            color: isFocused ? themeColor : Colors.grey.shade500,
            fontWeight: FontWeight.w800,
            fontSize: isCompact ? 11 : 12,
          ),
          hintText: selectedParameter.hint.isEmpty
              ? ''
              : selectedParameter.hint.split(' ').last,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 8, bottom: 12),
        ),
      ),
    );
  }

  Widget _buildAverageDisplay(
    BuildContext context,
    String point,
    Color themeColor,
  ) {
    Color textMuted = Theme.of(context).colorScheme.onSurfaceVariant;
    final average = calculatePointAverage(point);

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
