import 'package:flutter/material.dart';
import 'package:pondstat/features/monitoring/presentation/growth_tab.dart';
import 'package:pondstat/core/utils/helpers.dart';

class GrowthPage extends StatelessWidget {
  final String pondId;
  final bool canEdit;

  const GrowthPage({super.key, required this.pondId, required this.canEdit});

  void _showRecordGrowth(BuildContext context) {
    SnackbarHelper.show(
      context,
      "Growth recording coming soon",
      backgroundColor: Colors.indigo.shade400,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GrowthTab(pondId: pondId),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              heroTag: 'growth_fab',
              onPressed: () => _showRecordGrowth(context),
              backgroundColor: Colors.indigo.shade400,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                "Record Sampling",
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
