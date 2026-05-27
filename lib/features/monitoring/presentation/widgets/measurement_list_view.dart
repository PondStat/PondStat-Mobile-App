import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/monitoring/presentation/measurement_card.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/core/widgets/staggered_list_item.dart';
import 'package:pondstat/core/widgets/loading_placeholder.dart';
import 'package:pondstat/core/widgets/error_state_card.dart';

class MeasurementListView extends ConsumerStatefulWidget {
  final String pondId;
  final String type;
  final String dateKey;
  final bool canEdit;
  final Function(List<DocumentSnapshot>) onEdit;
  final Color primaryBlue;

  const MeasurementListView({
    super.key,
    required this.pondId,
    required this.type,
    required this.dateKey,
    required this.canEdit,
    required this.onEdit,
    required this.primaryBlue,
  });

  @override
  ConsumerState<MeasurementListView> createState() => _MeasurementListViewState();
}

class _MeasurementListViewState extends ConsumerState<MeasurementListView> {
  late Stream<QuerySnapshot> _measurementsStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant MeasurementListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pondId != widget.pondId ||
        oldWidget.type != widget.type ||
        oldWidget.dateKey != widget.dateKey) {
      _initStream();
    }
  }

  void _initStream() {
    _measurementsStream = ref.read(monitoringRepositoryProvider).measurementsCollection
        .where('pondId', isEqualTo: widget.pondId)
        .where('type', isEqualTo: widget.type)
        .where('dateKey', isEqualTo: widget.dateKey)
        .snapshots();
  }

  Future<void> _refreshData() async {
    setState(() {
      _initStream();
    });
    try {
      await _measurementsStream.first.timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _measurementsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const LoadingPlaceholder(message: "Loading measurements...");
        }

        if (snapshot.hasError) {
          return ErrorStateCard(
            description: "Error: ${snapshot.error}",
            onRetry: _refreshData,
          );
        }

        final rawDocs = snapshot.data?.docs ?? [];
        final excludedParams = MonitoringParameters.samplingParameters
            .map((p) => p.label)
            .toSet();
        final docs = rawDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final param = data['parameter'] as String?;
          return param != null && !excludedParams.contains(param);
        }).toList();

        if (docs.isEmpty) return _buildEmptyState();

        final sortedDocs = docs.toList()
          ..sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>? ?? {};
            final dataB = b.data() as Map<String, dynamic>? ?? {};
            final tA = dataA['timestamp'] as Timestamp?;
            final tB = dataB['timestamp'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tB.compareTo(tA); // Descending
          });

        return RefreshIndicator(
          color: widget.primaryBlue,
          onRefresh: _refreshData,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 120,
              left: 20,
              right: 20,
            ),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final data =
                  sortedDocs[index].data() as Map<String, dynamic>? ?? {};
              return StaggeredListItem(
                index: index,
                child: MeasurementCard(
                  key: ValueKey(sortedDocs[index].id),
                  time: data['timeString'] ?? 'Unknown Time',
                  title: data['parameter'] ?? 'Unknown Parameter',
                  content: data['value'] != null
                      ? "${data['value']} ${data['unit'] ?? ''}\n(Avg across recorded points)"
                      : "NA",
                  canEdit: widget.canEdit,
                  groupDocs: [sortedDocs[index]],
                  onEdit: () => widget.onEdit([sortedDocs[index]]),
                  notes: data['notes'] as String?,
                ),
              );
            },
          ),
        );
      },
    );
  }


  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: widget.primaryBlue,
      child: EmptyStateCard(
        image: const Icon(Icons.assignment_outlined),
        title: "No ${widget.type} records",
        description: "Tap 'Record Data' to log a measurement.",
        scrollable: true,
      ),
    );
  }
}
