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
      appBar: AppBar(
        title: const Text("Trends & Analysis"),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _exportReport(context),
          ),
        ],
      ),
      body: TrendsTab(pondId: pondId, species: species),
    );
  }
}
