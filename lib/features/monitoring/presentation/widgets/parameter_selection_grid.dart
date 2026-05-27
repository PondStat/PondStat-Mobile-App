import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/widgets/primary_button.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/all_recorded_state_card.dart';

class ParameterSelectionGrid extends ConsumerWidget {
  final int tabIndex;
  final String species;
  final String pondId;
  final DateTime selectedDay;
  final List<ParameterItem>? customParams;
  final String? customType;
  final List<ParameterItem> wizardSequence;
  final List<String?> wizardDocIds;
  final VoidCallback onShowCreateDialog;
  final void Function(ParameterItem param, String? docId) onParameterToggled;
  final VoidCallback onStartRecording;
  final VoidCallback onClearSelection;

  const ParameterSelectionGrid({
    super.key,
    required this.tabIndex,
    required this.species,
    required this.pondId,
    required this.selectedDay,
    required this.wizardSequence,
    required this.wizardDocIds,
    required this.onShowCreateDialog,
    required this.onParameterToggled,
    required this.onStartRecording,
    required this.onClearSelection,
    this.customParams,
    this.customType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<ParameterItem> hardcodedParams =
        customParams ??
        MonitoringParameters.getParametersByIndex(tabIndex, species);
    String type = customType ?? ['daily', 'weekly', 'biweekly'][tabIndex];

    if (type == 'growth') {
      final gridItems = hardcodedParams.asMap().entries.map((e) {
        return _buildParamTile(
          context: context,
          param: e.value,
          docId: null,
        );
      }).toList();
      return _buildGridWithStartButton(context, gridItems);
    }

    final String dateKey =
        "${selectedDay.year}-${selectedDay.month}-${selectedDay.day}";

    return StreamBuilder<QuerySnapshot>(
      stream: ref.read(monitoringRepositoryProvider).customParametersCollection
          .where('type', isEqualTo: type)
          .where('pondId', isEqualTo: pondId)
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
              .where('pondId', isEqualTo: pondId)
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
                onAddCustomParameter: onShowCreateDialog,
              );
            }

            List<Widget> items = [];
            for (int i = 0; i < filteredParams.length; i++) {
              items.add(
                _buildParamTile(
                  context: context,
                  param: filteredParams[i],
                  docId: filteredDocIds[i],
                ),
              );
            }
            items.add(_buildAddNewButton(context));
            return _buildGridWithStartButton(context, items);
          },
        );
      },
    );
  }

  Widget _buildParamTile({
    required BuildContext context,
    required ParameterItem param,
    String? docId,
  }) {
    final theme = Theme.of(context);
    final textDark = theme.colorScheme.onSurface;
    bool isSelected = wizardSequence.contains(param);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onParameterToggled(param, docId);
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
              : theme.colorScheme.surfaceContainerHighest,
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

  Widget _buildAddNewButton(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onShowCreateDialog();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: theme.colorScheme.outline,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              "Custom",
              style: TextStyle(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridWithStartButton(BuildContext context, List<Widget> gridItems) {
    final textMuted = Theme.of(context).colorScheme.onSurfaceVariant;
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
          child: wizardSequence.isNotEmpty
              ? Column(
                  key: const ValueKey('start_button_area'),
                  children: [
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: "Start Recording (${wizardSequence.length})",
                      icon: Icons.play_arrow_rounded,
                      onPressed: onStartRecording,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: onClearSelection,
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
}
