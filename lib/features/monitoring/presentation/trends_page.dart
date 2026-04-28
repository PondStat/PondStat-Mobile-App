import 'package:flutter/material.dart';
import 'package:pondstat/features/monitoring/presentation/trends_tab.dart';
import 'package:pondstat/core/utils/helpers.dart';

class TrendsPage extends StatelessWidget {
  final String pondId;
  final String species;

  const TrendsPage({super.key, required this.pondId, required this.species});

  void _exportReport(BuildContext context) {
    SnackbarHelper.show(context, "Export functionality coming soon", backgroundColor: Colors.red.shade400);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          TrendsTab(pondId: pondId, species: species),
          Positioned(
            top: 8,
            right: 20,
            child: FloatingActionButton.small(
              heroTag: 'export_btn',
              backgroundColor: Colors.red.shade50,
              elevation: 0,
              onPressed: () => _exportReport(context),
              child: Icon(Icons.ios_share_rounded, color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }
}
