import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pondstat/features/profile/presentation/profile_bottom_sheet.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/no_pond_assigned.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/pond_background.dart';
import 'package:pondstat/features/dashboard/presentation/create_pond_sheet.dart';
import 'package:pondstat/features/dashboard/presentation/edit_pond_sheet.dart';
import 'package:pondstat/features/dashboard/presentation/pond_list_card.dart';
import 'package:pondstat/features/auth/data/auth_repository.dart';
import 'package:pondstat/features/dashboard/data/dashboard_repository.dart';

class DefaultDashboardScreen extends StatefulWidget {
  const DefaultDashboardScreen({super.key});

  @override
  State<DefaultDashboardScreen> createState() => _DefaultDashboardScreenState();
}

class _DefaultDashboardScreenState extends State<DefaultDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isFabVisible = true;
  late AnimationController _shimmerController;

  bool _hasConnection = true;
  bool _showOnlineMessage = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final Color primaryBlue = const Color(0xFF0A74DA);
  final Color secondaryBlue = const Color(0xFF4FA0F0);

  late Stream<QuerySnapshot> _userPondsStream;

  @override
  void initState() {
    super.initState();

    _userPondsStream = DashboardRepository().getUserPondsStream(AuthRepository().currentUser!.uid);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _initConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await Connectivity().checkConnectivity();
    } catch (e) {
      debugPrint('Couldn\'t check connectivity status: $e');
      return;
    }
    if (!mounted) {
      return;
    }
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final bool hasInternet = !result.contains(ConnectivityResult.none);

    if (hasInternet && !_hasConnection) {
      setState(() {
        _hasConnection = true;
        _showOnlineMessage = true;
      });
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showOnlineMessage = false;
          });
        }
      });
    } else if (!hasInternet && _hasConnection) {
      setState(() {
        _hasConnection = false;
      });
    } else {
      // For initial load or unchanged status
      setState(() {
        _hasConnection = hasInternet;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => const ProfileBottomSheet(),
    );
  }

  void _showCreatePondSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePondSheet(),
    );
  }

  void _showEditPondSheet(
    BuildContext context,
    String pondId,
    Map<String, dynamic> pondData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          EditPondSheet(pondId: pondId, initialData: pondData),
    );
  }

  String _getGreeting(User user) {
    final name = user.displayName;
    if (name != null && name.trim().isNotEmpty) {
      final firstName = name.split(' ').first;
      return 'Hello, $firstName';
    }
    return 'My Ponds';
  }

  Future<bool?> _confirmDelete(BuildContext context, String pondName) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    String typedName = '';

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final bool isMatch = typedName.trim() == 'DELETE';
            return AlertDialog(
              backgroundColor: theme.scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Delete Pond?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Are you sure you want to delete '$pondName'? This action is permanent and will erase all data, measurements, and history associated with it.",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Type 'DELETE' to confirm:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    onChanged: (val) => setState(() => typedName = val),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? Colors.white12 : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark
                        ? Colors.white12
                        : Colors.grey.shade300,
                    disabledForegroundColor: isDark
                        ? Colors.white38
                        : Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isMatch
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: const Text(
                    "Delete Forever",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deletePond(String pondId, String pondName) async {
    try {
      await DashboardRepository().deletePond(pondId);
      if (mounted) {
        SnackbarHelper.show(
          context,
          "$pondName deleted successfully",
          backgroundColor: Colors.grey.shade800,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(
          context,
          "Failed to delete pond: $e",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthRepository().currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_person_outlined,
                  size: 56,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Session Expired",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please log in again to view your ponds.",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async => await AuthRepository().signOut(),
                icon: const Icon(Icons.login),
                label: const Text(
                  "Log In Again",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 90,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: isDark ? theme.scaffoldBackgroundColor : null,
            gradient: isDark
                ? null
                : LinearGradient(
                    colors: [primaryBlue, secondaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
        ),
        foregroundColor: isDark ? colorScheme.onSurface : Colors.white,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 20, top: 12, bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white12
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.water_drop,
                  color: isDark ? colorScheme.primary : Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getGreeting(user),
                      style: TextStyle(
                        color: isDark
                            ? colorScheme.onSurfaceVariant
                            : Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Pond Dashboard",
                      style: TextStyle(
                        color: isDark ? colorScheme.onSurface : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: GestureDetector(
                onTap: () => _showProfileSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white12
                          : Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark
                        ? colorScheme.primaryContainer
                        : Colors.white,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            user.displayName?.isNotEmpty == true
                                ? user.displayName![0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: isDark
                                  ? colorScheme.onPrimaryContainer
                                  : primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: !_hasConnection
                  ? Container(
                      key: const ValueKey('offline'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.grey.shade600,
                      child: const Text(
                        "You have no internet connection",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : _showOnlineMessage
                  ? Container(
                      key: const ValueKey('online'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.green,
                      child: const Text(
                        "Back online!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                const PondBackground(),
                StreamBuilder<QuerySnapshot>(
                  stream: _userPondsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData &&
                        snapshot.connectionState == ConnectionState.waiting) {
                      return _buildSkeletonLoader();
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }

                    var ponds = snapshot.data?.docs.toList() ?? [];

                    if (ponds.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification notification) {
                        if (notification is ScrollStartNotification ||
                            notification is ScrollUpdateNotification) {
                          if (_isFabVisible) {
                            setState(() => _isFabVisible = false);
                          }
                        } else if (notification is ScrollEndNotification) {
                          if (!_isFabVisible) {
                            setState(() => _isFabVisible = true);
                          }
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        color: primaryBlue,
                        backgroundColor: Colors.white,
                        onRefresh: () async => await Future.delayed(
                          const Duration(milliseconds: 800),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(
                            16,
                          ).copyWith(bottom: 100),
                          itemCount: ponds.length,
                          itemBuilder: (context, index) {
                            final pondDoc = ponds[index];
                            final pondData =
                                pondDoc.data() as Map<String, dynamic>;
                            final String pondName =
                                pondData['name'] ?? 'Unnamed Pond';
                            final String userRole =
                                pondData['roles']?[user.uid] ?? 'viewer';
                            final bool isOwner = userRole == 'owner';

                            final card = PondListCard(
                              pondId: pondDoc.id,
                              pondName: pondName,
                              species: pondData['species'] ?? 'Unspecified',
                              userRole: userRole,
                              createdAt:
                                  (pondData['createdAt'] as Timestamp?)
                                      ?.toDate() ??
                                  DateTime.now(),
                              targetCulturePeriodDays:
                                  pondData['targetCulturePeriodDays'] ?? 90,
                            );

                            if (isOwner) {
                              return Slidable(
                                key: Key(pondDoc.id),
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  extentRatio: 0.50,
                                  children: [
                                    CustomSlidableAction(
                                      onPressed: (context) {
                                        HapticFeedback.mediumImpact();
                                        _showEditPondSheet(
                                          context,
                                          pondDoc.id,
                                          pondData,
                                        );
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
                                          color: primaryBlue,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.edit_rounded, size: 28),
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
                                        bool confirm =
                                            await _confirmDelete(
                                              context,
                                              pondName,
                                            ) ??
                                            false;
                                        if (confirm) {
                                          _deletePond(pondDoc.id, pondName);
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                child: card,
                              );
                            }

                            return card;
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _showCreatePondSheet(context);
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              highlightElevation: 0,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                "New Pond",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
            ),
          ).applyGradient(),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.cardColor;
    final dividerColor = theme.dividerColor;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        final double titleWidth = 140.0 + (index % 3) * 40.0;
        final double subWidth = 90.0 + (index % 2) * 30.0;

        return Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [dividerColor, cardColor, dividerColor],
                    stops: const [0.1, 0.5, 0.9],
                    begin: const Alignment(-1.0, -0.3),
                    end: const Alignment(1.0, 0.3),
                    transform: SlideGradientTransform(_shimmerController.value),
                  ).createShader(bounds);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 18,
                      width: titleWidth,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 12,
                      width: subWidth,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 24,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Container(
                          height: 24,
                          width: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return NoPondAssignedWidget(
      onCreatePond: () => _showCreatePondSheet(context),
    );
  }

  Widget _buildErrorState(String rawError) {
    String friendlyMessage =
        "We couldn't connect to our servers right now. Please check your internet connection.";
    if (rawError.contains('permission-denied')) {
      friendlyMessage = "You don't have permission to view this data.";
    }

    return EmptyStateCard(
      icon: Icons.cloud_off_rounded,
      title: "Unable to Load",
      description: friendlyMessage,
      buttonText: "Try Again",
      onButtonPressed: () => setState(() {}),
    );
  }
}

class SlideGradientTransform extends GradientTransform {
  final double percent;
  const SlideGradientTransform(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (percent * 3 - 1.5),
      0.0,
      0.0,
    );
  }
}

extension GradientContainer on Container {
  Container applyGradient() {
    return Container(
      decoration: (decoration as BoxDecoration?)?.copyWith(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A74DA), Color(0xFF4FA0F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
