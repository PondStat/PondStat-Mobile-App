import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';

class RecordFormFields extends StatefulWidget {
  final ParameterItem selectedParameter;
  final Color themeColor;
  final List<String> points;
  final List<int> replicates;
  final Map<String, TextEditingController> valueControllers;
  final Map<String, FocusNode> focusNodes;
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
    required this.calculatePointAverage,
    required this.onFieldSubmitted,
  });

  @override
  State<RecordFormFields> createState() => _RecordFormFieldsState();
}

class _RecordFormFieldsState extends State<RecordFormFields> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDataPointsHeader(context, widget.themeColor),
        const SizedBox(height: 16),
        _buildDataPointInputs(context, widget.themeColor),
      ],
    );
  }

  Widget _buildDataPointsHeader(
    BuildContext context,
    Color themeColor,
  ) {
    Color textDark = Theme.of(context).colorScheme.onSurface;
    final parameter = widget.selectedParameter;

    final hasAbsolute = parameter.absoluteMin != null || parameter.absoluteMax != null;
    final hasOptimal = parameter.optimalMin != null || parameter.optimalMax != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
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
              if (hasAbsolute || hasOptimal) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // 1. Absolute Range / Limits Tag
                    if (parameter.absoluteMin != null && parameter.absoluteMax != null)
                      _buildHeaderTag(
                        dotColor: themeColor,
                        backgroundColor: themeColor.withValues(alpha: 0.1),
                        textColor: textDark.withValues(alpha: 0.7),
                        label: "Valid Range: ${parameter.absoluteMin} - ${parameter.absoluteMax}",
                      )
                    else if (parameter.absoluteMin != null)
                      _buildHeaderTag(
                        dotColor: themeColor,
                        backgroundColor: themeColor.withValues(alpha: 0.1),
                        textColor: textDark.withValues(alpha: 0.7),
                        label: "Minimum: ${parameter.absoluteMin}",
                      )
                    else if (parameter.absoluteMax != null)
                      _buildHeaderTag(
                        dotColor: themeColor,
                        backgroundColor: themeColor.withValues(alpha: 0.1),
                        textColor: textDark.withValues(alpha: 0.7),
                        label: "Maximum: ${parameter.absoluteMax}",
                      ),

                    // 2. Optimal Range / Limits Tag
                    if (parameter.optimalMin != null && parameter.optimalMax != null)
                      _buildHeaderTag(
                        dotColor: Colors.amber.shade700,
                        backgroundColor: Colors.amber.withValues(alpha: 0.1),
                        textColor: Colors.amber.shade900,
                        label: "Optimal: ${parameter.optimalMin} - ${parameter.optimalMax}",
                      )
                    else if (parameter.optimalMin != null)
                      _buildHeaderTag(
                        dotColor: Colors.amber.shade700,
                        backgroundColor: Colors.amber.withValues(alpha: 0.1),
                        textColor: Colors.amber.shade900,
                        label: "Optimal Min: ${parameter.optimalMin}",
                      )
                    else if (parameter.optimalMax != null)
                      _buildHeaderTag(
                        dotColor: Colors.amber.shade700,
                        backgroundColor: Colors.amber.withValues(alpha: 0.1),
                        textColor: Colors.amber.shade900,
                        label: "Optimal Max: ${parameter.optimalMax}",
                      ),
                  ],
                ),
              ],
            ],
          ),
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

  Widget _buildHeaderTag({
    required Color dotColor,
    required Color backgroundColor,
    required Color textColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
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
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPointInputs(BuildContext context, Color themeColor) {
    Color textDark = Theme.of(context).colorScheme.onSurface;

    if (widget.selectedParameter.isSinglePoint) {
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
                const SizedBox(height: 10),
                _buildAverageDisplay(context, widget.points[pIdx], themeColor),
              ],
            ),
          ),
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
        String? warningMessage;
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
            if (errorMessage == null) {
              if (widget.selectedParameter.optimalMin != null &&
                  parsedValue < widget.selectedParameter.optimalMin!) {
                warningMessage = "Sub-optimal: <${widget.selectedParameter.optimalMin}";
              }
              if (widget.selectedParameter.optimalMax != null &&
                  parsedValue > widget.selectedParameter.optimalMax!) {
                warningMessage = "Sub-optimal: >${widget.selectedParameter.optimalMax}";
              }
            }
          } else {
            errorMessage = "Invalid number";
          }
        }

        final bool hasError = errorMessage != null;
        final bool hasWarning = warningMessage != null;
        final activeColor = hasError 
            ? theme.colorScheme.error 
            : (hasWarning ? Colors.amber.shade700 : themeColor);

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
                  color: isFocused || hasError || hasWarning
                      ? activeColor
                      : Colors.transparent,
                  width: 2,
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
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                    ],
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
                          : (customLabel ?? widget.selectedParameter.hint),
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
                    )
                  else if (hasWarning)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Colors.amber.shade700,
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
              )
            else if (hasWarning && !isCompact)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  warningMessage,
                  style: TextStyle(
                    color: Colors.amber.shade700,
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
