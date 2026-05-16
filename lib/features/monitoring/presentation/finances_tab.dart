import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/features/monitoring/presentation/expenses_tab.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/expense_sheet.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';

class FinancesTab extends StatefulWidget {
  final String pondId;
  final bool canEdit;

  const FinancesTab({super.key, required this.pondId, required this.canEdit});

  @override
  State<FinancesTab> createState() => _FinancesTabState();
}

class _FinancesTabState extends State<FinancesTab>
    with AutomaticKeepAliveClientMixin {
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    "Group Expenses",
    "Pond Expenses",
    "Pond Sales",
  ];

  @override
  bool get wantKeepAlive => true;

  void _handleFabPressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseSheet(pondId: widget.pondId),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

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
                  child: ChoiceChip(
                    selected: _selectedFilterIndex == index,
                    label: Text(
                      _filters[index],
                      style: TextStyle(
                        fontWeight: _selectedFilterIndex == index
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: _selectedFilterIndex == index
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    backgroundColor: colorScheme.surfaceContainer,
                    selectedColor: primaryColor,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _selectedFilterIndex == index
                            ? primaryColor
                            : colorScheme.outlineVariant,
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
      floatingActionButton: (widget.canEdit && _selectedFilterIndex == 0)
          ? FloatingActionButton.extended(
              heroTag: 'finances_fab',
              onPressed: _handleFabPressed,
              backgroundColor: Colors.teal,
              icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
              label: const Text(
                "Add Expenses",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContentForFilter(int index) {
    if (index == 0) {
      return ExpensesTab(
        key: const ValueKey(0),
        pondId: widget.pondId,
        canAdd: widget.canEdit,
      );
    } else {
      return _buildComingSoon(key: ValueKey(index), title: _filters[index]);
    }
  }

  Widget _buildComingSoon({required Key key, required String title}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: EmptyStateCard(
          icon: Icons.construction_rounded,
          title: "$title Coming Soon",
          description: "This feature is currently under development.",
        ),
      ),
    );
  }
}
