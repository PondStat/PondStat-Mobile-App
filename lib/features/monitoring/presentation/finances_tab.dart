import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pondstat/features/monitoring/presentation/expenses_tab.dart';
import 'package:pondstat/features/monitoring/presentation/pond_expenses_tab.dart';
import 'package:pondstat/features/monitoring/presentation/pond_sales_tab.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/expense_sheet.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/pond_expense_sheet.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/pond_sale_sheet.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/custom_showcase.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/onboarding_tour_provider.dart';

class FinancesTab extends ConsumerStatefulWidget {
  final String pondId;
  final bool canEdit;

  const FinancesTab({super.key, required this.pondId, required this.canEdit});

  @override
  ConsumerState<FinancesTab> createState() => _FinancesTabState();
}

class _FinancesTabState extends ConsumerState<FinancesTab>
    with AutomaticKeepAliveClientMixin {
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    "Group Expenses",
    "Pond Expenses",
    "Pond Sales",
  ];

  final GlobalKey _financesChipsKey = GlobalKey();
  final GlobalKey _addExpensesKey = GlobalKey();

  void _startTour() {
    final keys = [_financesChipsKey];
    if (widget.canEdit && _selectedFilterIndex == 0) {
      keys.add(_addExpensesKey);
    }
    ShowcaseView.get().startShowCase(keys);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasSeen = ref.read(onboardingTourProvider).hasSeenFinances;
      if (!hasSeen) {
        _startTour();
        ref.read(onboardingTourProvider.notifier).markFinancesAsSeen();
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  void _handleFabPressed() {
    if (_selectedFilterIndex == 0) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ExpenseSheet(pondId: widget.pondId),
      );
    } else if (_selectedFilterIndex == 1) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PondExpenseSheet(pondId: widget.pondId),
      );
    } else if (_selectedFilterIndex == 2) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PondSaleSheet(pondId: widget.pondId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    ref.listen<int?>(tourTriggerProvider, (previous, next) {
      if (next == 0) {
        final tabController = DefaultTabController.of(context);
        if (tabController.index == 1) {
          _startTour();
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Filter Chips
          CustomShowcase(
            showcaseKey: _financesChipsKey,
            title: 'Financial Filters',
            description: 'Filter transaction history between combined group expenses, direct pond expenses, and sales.',
            child: SingleChildScrollView(
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
          ? _buildFabForFilter(_selectedFilterIndex)
          : null,
    );
  }

  Widget? _buildFabForFilter(int index) {
    if (index == 0) {
      return CustomShowcase(
        showcaseKey: _addExpensesKey,
        title: 'Add Expenses',
        description: 'Log new financial expenditures like feed purchases, labor, or equipment for this pond.',
        child: Semantics(
          label: "Add expenses receipt data",
          button: true,
          child: FloatingActionButton.extended(
            heroTag: 'finances_fab_group',
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
          ),
        ),
      );
    } else if (index == 1) {
      return Semantics(
        label: "Add direct pond expense",
        button: true,
        child: FloatingActionButton.extended(
          heroTag: 'finances_fab_pond',
          onPressed: _handleFabPressed,
          backgroundColor: Colors.indigo,
          icon: const Icon(Icons.receipt_rounded, color: Colors.white),
          label: const Text(
            "Add Pond Expense",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (index == 2) {
      return Semantics(
        label: "Add pond sale",
        button: true,
        child: FloatingActionButton.extended(
          heroTag: 'finances_fab_sale',
          onPressed: _handleFabPressed,
          backgroundColor: const Color(0xFF10B981),
          icon: const Icon(Icons.monetization_on_rounded, color: Colors.white),
          label: const Text(
            "Add Sale",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildContentForFilter(int index) {
    if (index == 0) {
      return ExpensesTab(
        key: const ValueKey(0),
        pondId: widget.pondId,
        canAdd: widget.canEdit,
      );
    } else if (index == 1) {
      return PondExpensesTab(
        key: const ValueKey(1),
        pondId: widget.pondId,
        canAdd: widget.canEdit,
      );
    } else {
      return PondSalesTab(
        key: const ValueKey(2),
        pondId: widget.pondId,
        canAdd: widget.canEdit,
      );
    }
  }
}
