import 'package:flutter/material.dart';

// Global list of currently active error boundaries in the build stack.
// Since Flutter builds synchronously and single-threaded, the top boundary
// in this list is the one currently building its descendant subtree.
final List<_ErrorBoundaryState> _activeBoundaries = [];

bool _isGlobalHandlerInitialized = false;

void _initializeGlobalErrorHandler() {
  if (_isGlobalHandlerInitialized) return;
  _isGlobalHandlerInitialized = true;

  final originalBuilder = ErrorWidget.builder;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (_activeBoundaries.isNotEmpty) {
      final boundary = _activeBoundaries.last;
      boundary.reportError(details.exception);
      return const SizedBox.shrink(); // Temporary blank box during this frame
    }
    return originalBuilder(details);
  };
}

/// A widget that catches build-time errors in its child and displays
/// a compact fallback card instead of crashing the entire widget tree.
///
/// Wrap individual list items (e.g. [PondListCard]) with this widget
/// to ensure a single corrupted data entry doesn't break the full list.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();

  @override
  StatefulElement createElement() {
    _initializeGlobalErrorHandler();
    return ErrorBoundaryElement(this);
  }
}

class ErrorBoundaryElement extends StatefulElement {
  ErrorBoundaryElement(ErrorBoundary super.widget);

  _ErrorBoundaryState get _boundaryState => (state as _ErrorBoundaryState);

  @override
  void performRebuild() {
    _activeBoundaries.add(_boundaryState);
    try {
      super.performRebuild();
    } finally {
      _activeBoundaries.remove(_boundaryState);
    }
  }
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  void reportError(Object error) {
    if (_error == null) {
      // Schedule a rebuild to render the fallback card on the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = error;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state when child identity changes (e.g. data rebuild)
    if (oldWidget.child.runtimeType != widget.child.runtimeType ||
        oldWidget.child.key != widget.child.key) {
      setState(() => _error = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback ?? _defaultFallback(context);
    }
    return widget.child;
  }

  Widget _defaultFallback(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.errorContainer.withValues(alpha: 0.15)
            : colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Unable to display this item',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This entry may have corrupted data.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
