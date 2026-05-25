import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'package:pondstat/core/services/connectivity_provider.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/features/auth/data/auth_repository.dart';
import 'package:pondstat/features/chat/data/chat_repository.dart';
import 'package:pondstat/features/chat/domain/models/pond_chat_message.dart';
import 'package:pondstat/features/notifications/data/notifications_repository.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/pond_background.dart';

class PondChatPage extends ConsumerStatefulWidget {
  final String pondId;
  final String pondName;
  final String userRole;

  const PondChatPage({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.userRole,
  });

  @override
  ConsumerState<PondChatPage> createState() => _PondChatPageState();
}

class _PondChatPageState extends ConsumerState<PondChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String? _attachedImagePath;
  String? _selectedTag;
  bool _isSending = false;

  final List<String> _tagOptions = ['pH', 'Salinity', 'Temperature', 'DO', 'Growth'];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'pH':
        return Colors.blue;
      case 'Salinity':
        return Colors.teal;
      case 'Temperature':
        return Colors.orange;
      case 'DO':
        return Colors.cyan;
      case 'Growth':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTagIcon(String tag) {
    switch (tag) {
      case 'pH':
        return Icons.water_drop_rounded;
      case 'Salinity':
        return Icons.waves_rounded;
      case 'Temperature':
        return Icons.thermostat_rounded;
      case 'DO':
        return Icons.air_rounded;
      case 'Growth':
        return Icons.trending_up_rounded;
      default:
        return Icons.local_offer_rounded;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _attachedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error selecting photo: $e');
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Attach Photo",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: theme.colorScheme.primary),
                ),
                title: const Text("Take Photo", style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_rounded, color: theme.colorScheme.primary),
                ),
                title: const Text("Choose from Gallery", style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTagSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Tag a Parameter",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              ..._tagOptions.map((tag) {
                final color = _getTagColor(tag);
                final icon = _getTagIcon(tag);
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(
                    tag == 'DO' ? 'Dissolved Oxygen (DO)' : tag,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedTag = tag;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty && _attachedImagePath == null) return;

    final isOffline = ref.read(isOfflineProvider);
    if (isOffline && _attachedImagePath != null) {
      SnackbarHelper.showError(
        context,
        "Cannot upload photo attachments while offline. Please remove photo or connect to internet.",
      );
      return;
    }

    setState(() => _isSending = true);
    FocusScope.of(context).unfocus();

    try {
      final userAsync = ref.read(userChangesProvider);
      final currentUser = userAsync.value ?? ref.read(firebaseAuthProvider).currentUser;
      final senderId = currentUser?.uid ?? '';
      final senderName = currentUser?.displayName ?? 'PondStat User';
      final senderPhotoUrl = currentUser?.photoURL;

      String? uploadedImageUrl;
      if (_attachedImagePath != null) {
        final messageId = ref.read(chatRepositoryProvider).getChatsCollection(widget.pondId).doc().id;
        uploadedImageUrl = await ref.read(chatRepositoryProvider).uploadChatImage(
          widget.pondId,
          messageId,
          _attachedImagePath!,
        );
      }

      await ref.read(chatRepositoryProvider).sendMessage(
            pondId: widget.pondId,
            senderId: senderId,
            senderName: senderName,
            senderPhotoUrl: senderPhotoUrl,
            message: messageText,
            imageUrl: uploadedImageUrl,
            taggedParameter: _selectedTag,
          );

      // Trigger notifications for other collaborators
      final notificationTitle = 'New message in ${widget.pondName}';
      final notificationBody = _selectedTag != null
          ? '[$_selectedTag] $senderName: $messageText'
          : '$senderName: $messageText';

      unawaited(
        ref.read(notificationsRepositoryProvider).notifyPondMembers(
              pondId: widget.pondId,
              title: notificationTitle,
              body: notificationBody,
            ),
      );

      _messageController.clear();
      setState(() {
        _attachedImagePath = null;
        _selectedTag = null;
      });

      // Scroll to bottom
      _scrollToBottom();
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to send message: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _viewFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(8),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(PondChatMessage message, String currentUserId, ThemeData theme) {
    final isMe = message.senderId == currentUserId;
    final colorScheme = theme.colorScheme;
    final timestampText = message.createdAt != null
        ? DateFormat('h:mm a').format(message.createdAt!)
        : 'Sending...';

    final bubbleColor = isMe
        ? colorScheme.primary
        : (theme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest
            : Colors.white);

    final textColor = isMe
        ? Colors.white
        : colorScheme.onSurface;

    final nameColor = isMe
        ? Colors.white70
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message.senderPhotoUrl != null
                  ? NetworkImage(message.senderPhotoUrl!)
                  : null,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              child: message.senderPhotoUrl == null
                  ? Text(
                      message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: nameColor,
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: theme.brightness == Brightness.dark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.taggedParameter != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTagColor(message.taggedParameter!).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getTagColor(message.taggedParameter!).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getTagIcon(message.taggedParameter!),
                                color: _getTagColor(message.taggedParameter!),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Tagged: ${message.taggedParameter}",
                                style: TextStyle(
                                  color: _getTagColor(message.taggedParameter!),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (message.imageUrl != null) ...[
                        GestureDetector(
                          onTap: () => _viewFullScreenImage(message.imageUrl!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              message.imageUrl!,
                              width: 200,
                              height: 150,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 200,
                                  height: 150,
                                  alignment: Alignment.center,
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  child: const CircularProgressIndicator(strokeWidth: 2),
                                );
                              },
                            ),
                          ),
                        ),
                        if (message.message.isNotEmpty) const SizedBox(height: 8),
                      ],
                      if (message.message.isNotEmpty)
                        Text(
                          message.message,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    timestampText,
                    style: TextStyle(
                      fontSize: 9,
                      color: nameColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: message.senderPhotoUrl != null
                  ? NetworkImage(message.senderPhotoUrl!)
                  : null,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              child: message.senderPhotoUrl == null
                  ? Text(
                      message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';

    final messagesAsync = ref.watch(pondMessagesProvider(widget.pondId));

    // Scroll to bottom on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const PondBackground(),
          SafeArea(
            child: Column(
              children: [
                // Frosted header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: colorScheme.onSurface,
                            size: 20,
                          ),
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "POND CHAT & NOTES",
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              widget.pondName,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Messages List
                Expanded(
                  child: messagesAsync.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: colorScheme.primary,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No messages yet",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  "Start the conversation or log updates for your collaborators.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 10),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageItem(messages[index], currentUserId, theme);
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          "Failed to load messages: $error",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ),

                // Attached image & selected tag review panel
                if (_attachedImagePath != null || _selectedTag != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_attachedImagePath != null) ...[
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_attachedImagePath!),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -2,
                                right: -2,
                                child: GestureDetector(
                                  onTap: () => setState(() => _attachedImagePath = null),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (_selectedTag != null) ...[
                          Chip(
                            avatar: Icon(
                              _getTagIcon(_selectedTag!),
                              color: Colors.white,
                              size: 14,
                            ),
                            label: Text(
                              _selectedTag!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: _getTagColor(_selectedTag!),
                            deleteIcon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                            onDeleted: () => setState(() => _selectedTag = null),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                        const Spacer(),
                      ],
                    ),
                  ),

                // Message input box
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surface : Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      // Camera/Gallery attachment icon
                      IconButton(
                        icon: Icon(Icons.add_photo_alternate_outlined, color: colorScheme.primary),
                        tooltip: 'Attach Image',
                        onPressed: _isSending ? null : _showImagePickerOptions,
                      ),
                      // Parameter tagging icon
                      IconButton(
                        icon: Icon(Icons.local_offer_outlined, color: colorScheme.primary),
                        tooltip: 'Tag Parameter',
                        onPressed: _isSending ? null : _showTagSelector,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            enabled: !_isSending,
                            maxLines: 4,
                            minLines: 1,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: 'Type observation or note...',
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send Button
                      _isSending
                          ? const SizedBox(
                              width: 36,
                              height: 36,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : FloatingActionButton.small(
                              onPressed: _sendMessage,
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              child: const Icon(Icons.send_rounded, size: 18),
                            ),
                    ],
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
