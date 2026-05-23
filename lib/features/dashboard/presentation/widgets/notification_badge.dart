import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/notifications/data/notifications_repository.dart';

class NotificationBadge extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  final bool isDark;

  const NotificationBadge({
    required this.onTap,
    required this.isDark,
    super.key,
  });

  @override
  ConsumerState<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends ConsumerState<NotificationBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.04), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.04, end: 0.04), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.04, end: -0.03), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.03), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.03, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    if (mounted) {
      _shakeController.reset();
      _shakeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(notificationsRepositoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<int>(
      stream: repository.getUnreadCountStream(),
      builder: (context, snapshot) {
        final int unreadCount = snapshot.data ?? 0;

        if (unreadCount > _lastCount) {
          _lastCount = unreadCount;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _triggerShake();
          });
        } else if (unreadCount < _lastCount) {
          _lastCount = unreadCount;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            Semantics(
              button: true,
              label: unreadCount > 0
                  ? '$unreadCount unread notifications'
                  : 'Notifications',
              child: RotationTransition(
                turns: _shakeAnimation,
                child: IconButton(
                  icon: Icon(
                    unreadCount > 0
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: widget.isDark ? null : Colors.white,
                    size: 28,
                  ),
                  onPressed: widget.onTap,
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 12,
              child: AnimatedScale(
                scale: unreadCount > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isDark ? Colors.black : colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      key: ValueKey<int>(unreadCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
