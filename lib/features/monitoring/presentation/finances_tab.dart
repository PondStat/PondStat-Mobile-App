import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/features/monitoring/presentation/expenses_tab.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/expense_sheet.dart';

class FinancesTab extends StatefulWidget {
  final String pondId;
  final bool canEdit;

  const FinancesTab({
    super.key,
    required this.pondId,
    required this.canEdit,
  });

  @override
  State<FinancesTab> createState() => _FinancesTabState();
}

class _FinancesTabState extends State<FinancesTab> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["Group Expenses", "Pond Expenses", "Pond Sales"];

  final Color primaryBlue = const Color(0xFF0A74DA);

  void _showComingSoonModal(String title) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.construction_rounded, color: Colors.orange.shade700),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Coming Soon",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          "The '$title' feature is currently under development. Stay tuned for updates!",
          style: TextStyle(color: Colors.grey.shade700, height: 1.4, fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it!", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleFabPressed() {
    if (_selectedFilterIndex == 0) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ExpenseSheet(pondId: widget.pondId),
      );
    } else {
      _showComingSoonModal("Add ${_filters[_selectedFilterIndex]}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: List.generate(
                _filters.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: _selectedFilterIndex == index,
                    label: Text(
                      _filters[index],
                      style: TextStyle(
                        fontWeight: _selectedFilterIndex == index ? FontWeight.w800 : FontWeight.w600,
                        color: _selectedFilterIndex == index ? Colors.white : Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: primaryBlue,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _selectedFilterIndex == index ? primaryBlue : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedFilterIndex = index;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContentForFilter(_selectedFilterIndex),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: _handleFabPressed,
              backgroundColor: _selectedFilterIndex == 0 ? Colors.teal : Colors.grey.shade400,
              icon: Icon(
                _selectedFilterIndex == 2 ? Icons.point_of_sale_rounded : Icons.receipt_long_rounded, 
                color: Colors.white,
              ),
              label: Text(
                _selectedFilterIndex == 0 
                    ? "Add Expenses" 
                    : "Add ${_filters[_selectedFilterIndex].split(' ').last}", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            )
          : null,
    );
  }

  Widget _buildContentForFilter(int index) {
    if (index == 0) {
      return ExpensesTab(key: const ValueKey(0), pondId: widget.pondId, canAdd: widget.canEdit);
    } else {
      return _buildComingSoon(key: ValueKey(index), title: _filters[index]);
    }
  }

  Widget _buildComingSoon({required Key key, required String title}) {
    return Center(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "$title Coming Soon",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This feature is currently under development.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

