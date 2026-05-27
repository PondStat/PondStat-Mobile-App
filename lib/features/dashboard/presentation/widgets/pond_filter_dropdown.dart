import 'package:flutter/material.dart';

class PondFilterDropdown extends StatelessWidget {
  final List<String> uniqueSpecies;
  final String? filterRole;
  final String? filterSpecies;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<String?> onSpeciesChanged;

  const PondFilterDropdown({
    super.key,
    required this.uniqueSpecies,
    required this.filterRole,
    required this.filterSpecies,
    required this.onRoleChanged,
    required this.onSpeciesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    int activeFiltersCount = 0;
    if (filterRole != null) activeFiltersCount++;
    if (filterSpecies != null) activeFiltersCount++;

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tooltip: 'Filter Ponds',
      onSelected: (value) {
        if (value.startsWith('role:')) {
          final role = value.split(':')[1];
          onRoleChanged(role.isEmpty ? null : role);
        } else if (value.startsWith('species:')) {
          final species = value.split(':')[1];
          onSpeciesChanged(species.isEmpty ? null : species);
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            enabled: false,
            child: Text(
              'Roles',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          PopupMenuItem(
            value: 'role:',
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  color: filterRole == null ? colorScheme.primary : Colors.transparent,
                ),
                const SizedBox(width: 12),
                const Text('All Roles'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'role:owner',
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  color: filterRole == 'owner' ? colorScheme.primary : Colors.transparent,
                ),
                const SizedBox(width: 12),
                const Text('Owner'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'role:editor',
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  color: filterRole == 'editor' ? colorScheme.primary : Colors.transparent,
                ),
                const SizedBox(width: 12),
                const Text('Editor'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'role:viewer',
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  color: filterRole == 'viewer' ? colorScheme.primary : Colors.transparent,
                ),
                const SizedBox(width: 12),
                const Text('Viewer'),
              ],
            ),
          ),
          if (uniqueSpecies.isNotEmpty) ...[
            const PopupMenuDivider(),
            PopupMenuItem(
              enabled: false,
              child: Text(
                'Species',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            PopupMenuItem(
              value: 'species:',
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    color: filterSpecies == null ? colorScheme.primary : Colors.transparent,
                  ),
                  const SizedBox(width: 12),
                  const Text('All Species'),
                ],
              ),
            ),
            for (final species in uniqueSpecies)
              PopupMenuItem(
                value: 'species:$species',
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      color: filterSpecies == species ? colorScheme.primary : Colors.transparent,
                    ),
                    const SizedBox(width: 12),
                    Text(species),
                  ],
                ),
              ),
          ],
        ];
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: activeFiltersCount > 0
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activeFiltersCount > 0 ? colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 20,
              color: activeFiltersCount > 0 ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            if (activeFiltersCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$activeFiltersCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
