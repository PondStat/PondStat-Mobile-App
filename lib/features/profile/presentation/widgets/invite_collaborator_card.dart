import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';

class InviteCollaboratorCard extends StatelessWidget {
  final TextEditingController emailController;
  final FocusNode emailFocus;
  final bool isAdding;
  final VoidCallback onInvite;

  const InviteCollaboratorCard({
    super.key,
    required this.emailController,
    required this.emailFocus,
    required this.isAdding,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textDark = colorScheme.onSurface;
    final primaryBlue = const Color(0xFF0A74DA);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Invite Collaborator",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: textDark,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: PondStatTextField(
                  controller: emailController,
                  focusNode: emailFocus,
                  label: 'Collaborator Email',
                  hint: 'user@up.edu.ph',
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onInvite(),
                  suffixIcon: emailController.text.isNotEmpty
                      ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            emailController.clear();
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: isAdding ? null : onInvite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: isAdding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
