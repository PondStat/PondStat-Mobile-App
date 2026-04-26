import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase/firestore_helper.dart';
import '../measurement_card.dart';

class MeasurementListView extends StatefulWidget {
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
  State<MeasurementListView> createState() => _MeasurementListViewState();
}

class _MeasurementListViewState extends State<MeasurementListView> {
  String? _selectedFilter;

  @override
  void didUpdateWidget(covariant MeasurementListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset filter when changing tabs or dates
    if (oldWidget.type != widget.type || oldWidget.dateKey != widget.dateKey) {
      setState(() => _selectedFilter = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreHelper.measurementsCollection
          .where('pondId', isEqualTo: widget.pondId)
          .where('type', isEqualTo: widget.type)
          .where('dateKey', isEqualTo: widget.dateKey)
          .orderBy('recordedAt', descending: true)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        // Only show loader if we have NO data yet AND we are waiting
        if (!snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        // 1. Extract Unique Parameters
        final Set<String> uniqueParams = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final param = data['parameter'] as String?;
          if (param != null) uniqueParams.add(param);
        }
        final filterOptions = uniqueParams.toList()..sort();

        // 2. Filter the documents
        final filteredDocs = _selectedFilter == null
            ? docs
            : docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['parameter'] == _selectedFilter;
              }).toList();

        return Column(
          children: [
            // Filter Bar
            if (filterOptions.isNotEmpty)
              Container(
                height: 50,
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildFilterChip('All', null),
                    ...filterOptions.map(
                      (param) => _buildFilterChip(param, param),
                    ),
                  ],
                ),
              ),

            // List View
            Expanded(
              child: RefreshIndicator(
                color: widget.primaryBlue,
                onRefresh: () async =>
                    await Future.delayed(const Duration(milliseconds: 800)),
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 4,
                    bottom: 120,
                    left: 20,
                    right: 20,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    return MeasurementCard(
                      time: data['timeString'] ?? 'Unknown Time',
                      title: data['parameter'] ?? 'Unknown Parameter',
                      content:
                          "${data['value'] ?? '0'} ${data['unit'] ?? ''}\n(Avg across recorded points)",
                      notes: data['notes'],
                      canEdit: widget.canEdit,
                      groupDocs: [filteredDocs[index]],
                      onEdit: () => widget.onEdit([filteredDocs[index]]),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String? filterValue) {
    final isSelected = _selectedFilter == filterValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedFilter = filterValue);
          } else if (_selectedFilter == filterValue) {
            // Prevent unselecting the current chip if it's the only one selected
            // (always keep something selected, usually 'All')
            if (filterValue != null) {
              setState(() => _selectedFilter = null);
            }
          }
        },
        selectedColor: widget.primaryBlue,
        backgroundColor: Colors.grey.shade100,
        side: BorderSide(
          color: isSelected ? widget.primaryBlue : Colors.grey.shade300,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No ${widget.type} records",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap 'Record Data' to log a measurement.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
