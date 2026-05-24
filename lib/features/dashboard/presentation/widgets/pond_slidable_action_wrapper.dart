import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/delete_pond_dialog.dart';

class PondSlidableActionWrapper extends StatelessWidget {
  final Widget child;
  final String pondId;
  final String pondName;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PondSlidableActionWrapper({
    super.key,
    required this.child,
    required this.pondId,
    required this.pondName,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!isOwner) {
      return child;
    }

    return Slidable(
      key: Key(pondId),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.50,
        children: [
          CustomSlidableAction(
            onPressed: (context) {
              onEdit();
            },
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            child: Container(
              margin: const EdgeInsets.only(
                bottom: 16,
                left: 8,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_rounded,
                    size: 28,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Edit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          CustomSlidableAction(
            onPressed: (context) async {
              HapticFeedback.mediumImpact();
              bool confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => DeletePondDialog(pondName: pondName),
                  ) ??
                  false;
              if (confirm) {
                onDelete();
              }
            },
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            child: Container(
              margin: const EdgeInsets.only(
                bottom: 16,
                left: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_sweep_rounded,
                    size: 28,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Delete',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}
