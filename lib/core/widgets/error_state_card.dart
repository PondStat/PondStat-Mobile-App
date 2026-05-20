import 'package:flutter/material.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/core/widgets/secondary_button.dart';

class ErrorStateCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onRetry;
  final bool scrollable;

  const ErrorStateCard({
    super.key,
    this.title = "Unable to Load",
    required this.description,
    this.onRetry,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      image: const Icon(Icons.cloud_off_rounded),
      title: title,
      description: description,
      scrollable: scrollable,
      action: onRetry != null
          ? SecondaryButton(
              text: "Try Again",
              icon: Icons.refresh_rounded,
              onPressed: onRetry!,
            )
          : null,
    );
  }
}
