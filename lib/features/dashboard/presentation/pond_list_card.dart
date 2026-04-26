import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/features/monitoring/presentation/data_monitoring.dart';

class PondListCard extends StatefulWidget {
  final String pondId;
  final String pondName;
  final String species;
  final String userRole;
  final DateTime createdAt;
  final int targetCulturePeriodDays;

  const PondListCard({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.species,
    required this.userRole,
    required this.createdAt,
    required this.targetCulturePeriodDays,
  });

  @override
  State<PondListCard> createState() => _PondListCardState();
}

class _PondListCardState extends State<PondListCard> {
  bool _isNavigating = false;

  double _scale = 1.0;

  Future<void> _navigateToMonitoring(BuildContext context) async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
      _scale = 1.0;
    });

    HapticFeedback.mediumImpact();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MonitoringPage(
          pondId: widget.pondId,
          pondName: widget.pondName,
          userRole: widget.userRole,
          species: widget.species,
          createdAt: widget.createdAt,
          targetCulturePeriodDays: widget.targetCulturePeriodDays,
        ),
      ),
    );

    if (mounted) {
      setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      label:
          "${widget.pondName} pond. Species: ${widget.species}. Your role is ${widget.userRole}.",
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isDark ? Border.all(color: Colors.white12) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTapDown: (_) => setState(() => _scale = 0.97),
              onTapUp: (_) => setState(() => _scale = 1.0),
              onTapCancel: () => setState(() => _scale = 1.0),
              onTap: () => _navigateToMonitoring(context),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Hero(
                      tag: 'pond-icon-${widget.pondId}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.secondary,
                                colorScheme.primary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.water_drop_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pondName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: -0.3,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.set_meal_rounded,
                                size: 14,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.species,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildRoleBadge(colorScheme, isDark),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade400,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(ColorScheme colorScheme, bool isDark) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (widget.userRole.toLowerCase()) {
      case 'owner':
        bgColor = isDark
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.green.shade50;
        borderColor = isDark
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.green.shade200;
        textColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
        break;
      case 'editor':
        bgColor = isDark
            ? colorScheme.primary.withValues(alpha: 0.15)
            : Colors.blue.shade50;
        borderColor = isDark
            ? colorScheme.primary.withValues(alpha: 0.3)
            : Colors.blue.shade200;
        textColor = isDark
            ? colorScheme.primaryContainer
            : Colors.blue.shade700;
        break;
      case 'viewer':
      default:
        bgColor = isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100;
        borderColor = isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.shade300;
        textColor = isDark ? Colors.white70 : Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        widget.userRole.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
