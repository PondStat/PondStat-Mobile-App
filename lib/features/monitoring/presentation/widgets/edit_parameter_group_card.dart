import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';

class EditParameterGroupCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Map<String, TextEditingController> controllers;
  final TextEditingController notesController;
  final bool isSinglePoint;
  final VoidCallback onChanged;

  static const List<String> points = ['A', 'B', 'C', 'D'];
  static const List<int> replicates = [1, 2, 3];

  const EditParameterGroupCard({
    super.key,
    required this.doc,
    required this.controllers,
    required this.notesController,
    required this.onChanged,
    this.isSinglePoint = false,
  });

  String _calculateEditReplicateAverage(String point) {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Text(
              "${data['parameter']}${data['unit'] != null && (data['unit'] as String).trim().isNotEmpty ? ' (${data['unit']})' : ''}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isSinglePoint)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: PondStatTextField(
                controller: controllers['A-1']!,
                label: 'Value',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => onChanged(),
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "Point ${points[pIdx]}",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
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
                                onChanged: (_) => onChanged(),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,\-]'),
                                  ),
                                ],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  labelText: "R${replicates[rIdx]}",
                                  isDense: true,
                                  filled: true,
                                  fillColor:
                                      colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
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
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _calculateEditReplicateAverage(
                              points[pIdx],
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 16),
          PondStatTextField(
            controller: notesController,
            label: 'Notes or Findings (Optional)',
            maxLines: 3,
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}
