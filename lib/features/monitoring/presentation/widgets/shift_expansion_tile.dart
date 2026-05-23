import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/core/utils/string_extensions.dart';

const List<Color> _avatarPastelColors = [
  Color(0xFFFDA4AF),
  Color(0xFFFCD34D),
  Color(0xFF6EE7B7),
  Color(0xFF93C5FD),
  Color(0xFFC4B5FD),
  Color(0xFFF9A8D4),
  Color(0xFFFDBA74),
  Color(0xFF5EEAD4),
];

class ShiftExpansionTile extends StatefulWidget {
  final String shiftName;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final List<Map<String, dynamic>> assignedUsers;

  const ShiftExpansionTile({
    super.key,
    required this.shiftName,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.assignedUsers,
  });

  @override
  State<ShiftExpansionTile> createState() => _ShiftExpansionTileState();
}

class _ShiftExpansionTileState extends State<ShiftExpansionTile> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    if (widget.assignedUsers.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return InkWell(
      onTap: widget.assignedUsers.isNotEmpty ? _toggleExpanded : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, size: 18, color: widget.iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.shiftName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: onSurface,
                        ),
                      ),
                      Text(
                        widget.assignedUsers.isEmpty
                            ? "No one assigned"
                            : "${widget.assignedUsers.length} assigned",
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.assignedUsers.isEmpty
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.assignedUsers.isNotEmpty) ...[
                  OverlapAvatarGroup(users: widget.assignedUsers),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  children: widget.assignedUsers
                      .map(
                        (user) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: _getAvatarColor(
                                  user['name'],
                                ).withValues(alpha: 0.2),
                                child: Text(
                                  (user['name'] as String?).initials,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getAvatarColor(user['name']),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                user['name'],
                                style: TextStyle(
                                  color: onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              secondChild: const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final hash = name.hashCode.abs();
    return _avatarPastelColors[hash % _avatarPastelColors.length];
  }
}

class OverlapAvatarGroup extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  const OverlapAvatarGroup({required this.users, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const maxToShow = 3;
    final int toShow = users.length > maxToShow ? maxToShow : users.length;
    final int remaining = users.length > maxToShow
        ? users.length - maxToShow
        : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(toShow + (remaining > 0 ? 1 : 0), (index) {
        if (index == toShow && remaining > 0) {
          // The '+X' circle
          return Align(
            widthFactor: 0.6,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: colorScheme.surfaceContainerHigh,
              child: Text(
                "+$remaining",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        final user = users[index];
        final name = user['name'] as String;
        final hash = name.hashCode.abs();
        final color = _avatarPastelColors[hash % _avatarPastelColors.length];

        return Align(
          widthFactor: 0.6,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surfaceContainer, width: 2),
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Text(
                name.initials,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
