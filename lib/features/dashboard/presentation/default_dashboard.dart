import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/pond_slidable_action_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pondstat/features/profile/presentation/profile_bottom_sheet.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/core/widgets/secondary_button.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/no_pond_assigned.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/pond_background.dart';
import 'package:pondstat/features/dashboard/presentation/create_pond_sheet.dart';
import 'package:pondstat/core/services/logging/logger_provider.dart';
import 'package:pondstat/features/dashboard/presentation/edit_pond_sheet.dart';
import 'package:pondstat/features/dashboard/presentation/pond_list_card.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/pondy_aquarium_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/auth/data/auth_repository.dart';
import 'package:pondstat/features/dashboard/data/pond_repository.dart';
import 'package:pondstat/features/dashboard/domain/models/pond.dart';
import 'package:pondstat/core/widgets/error_boundary.dart';
import 'package:pondstat/core/router/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:pondstat/core/widgets/staggered_list_item.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/notification_badge.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/pond_skeleton_loader.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/pond_filter_dropdown.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/custom_showcase.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/onboarding_tour_provider.dart';

class DefaultDashboardScreen extends ConsumerStatefulWidget {
  const DefaultDashboardScreen({super.key});

  @override
  ConsumerState<DefaultDashboardScreen> createState() => _DefaultDashboardScreenState();
}

class _DefaultDashboardScreenState extends ConsumerState<DefaultDashboardScreen> {
  bool _isFabVisible = true;

  bool _hasConnection = true;
  bool _showOnlineMessage = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Search & Filter state
  String _searchQuery = '';
  String? _filterRole;
  String? _filterSpecies;

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  late Stream<List<Pond>> _userPondsStream;

  // Showcase global keys
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _notificationKey = GlobalKey();
  final GlobalKey _aquariumKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();
  final GlobalKey _pondCardKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    ShowcaseView.register(scope: 'dashboard');

    final user = ref.read(authRepositoryProvider).currentUser;
    _userPondsStream = ref.read(pondRepositoryProvider).getUserPondsStream(
      user?.uid ?? '',
    );

    // Sync FCM token on initialization
    ref.read(authRepositoryProvider).updateFcmToken();

    _initConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    _searchFocusNode.addListener(() => setState(() {}));
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tourNotifier = ref.read(onboardingTourProvider);
      if (!tourNotifier.hasSeenDashboard) {
        _userPondsStream.first.then((ponds) {
          if (ponds.isNotEmpty && mounted) {
            ShowcaseView.getNamed('dashboard').startShowCase([
              _profileKey,
              _notificationKey,
              _aquariumKey,
              _searchKey,
              _filterKey,
              _pondCardKey,
              _fabKey,
            ]);
            ref.read(onboardingTourProvider.notifier).markDashboardAsSeen();
          }
        }).catchError((_) {});
      }
    });
  }

  Future<void> _refreshData() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    setState(() {
      _userPondsStream = ref.read(pondRepositoryProvider).getUserPondsStream(
        user?.uid ?? '',
      );
    });
    try {
      await _userPondsStream.first.timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<void> _initConnectivity() async {
    final logger = ref.read(appLoggerProvider);
    late List<ConnectivityResult> result;
    try {
      result = await Connectivity().checkConnectivity().timeout(
        const Duration(seconds: 1),
        onTimeout: () => [ConnectivityResult.none],
      );
    } catch (e, stackTrace) {
      logger.error("Couldn't check connectivity status", error: e, stackTrace: stackTrace, tag: 'NETWORK');
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
    ShowcaseView.getNamed('dashboard').unregister();
    _connectivitySubscription?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => const ProfileBottomSheet(),
    );
  }

  void _showCreatePondSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          EditPondSheet(pondId: pondId, initialData: pondData),
    );
  }

  String _getGreeting(User user) {
    final hour = DateTime.now().hour;
    String timeGreeting = 'Hello';
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }

    final name = user.displayName;
    if (name != null && name.trim().isNotEmpty) {
      final firstName = name.split(' ').first;
      return '$timeGreeting, $firstName! Ready to check your ponds?';
    }
    return '$timeGreeting! Ready to check your ponds?';
  }



  Future<void> _deletePond(String pondId, String pondName) async {
    try {
      await ref.read(pondRepositoryProvider).deletePond(pondId);
      if (mounted) {
        SnackbarHelper.showInfo(context, "$pondName deleted successfully");
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, "Failed to delete pond: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userChangesProvider);
    final user = userAsync.value ?? ref.read(authRepositoryProvider).currentUser;
    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<List<Pond>>(
      stream: _userPondsStream,
      builder: (context, snapshot) {
        final ponds = snapshot.data ?? [];
        final hasPonds = ponds.isNotEmpty;

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
                        colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.75)],
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "PondStat",
                          style: TextStyle(
                            color: isDark ? colorScheme.primary : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              CustomShowcase(
                showcaseKey: _notificationKey,
                scope: 'dashboard',
                title: "Notifications Hub",
                description: "Keep track of alerts, announcements, and system notifications regarding your ponds.",
                child: NotificationBadge(
                  onTap: () => context.push(AppRoutes.notifications),
                  isDark: isDark,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Open profile',
                    child: CustomShowcase(
                      showcaseKey: _profileKey,
                      scope: 'dashboard',
                      title: "Profile & Settings",
                      description: "Access your account options, edit your profile, toggle theme preferences, adjust notification settings, or reset this tutorial tour.",
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
                                          : colorScheme.primary,
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
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        const PondBackground(),
                        if (!snapshot.hasData &&
                            snapshot.connectionState ==
                                ConnectionState.waiting)
                          const PondSkeletonLoader()
                        else if (snapshot.hasError)
                          _buildErrorState(snapshot.error.toString())
                        else if (ponds.isEmpty)
                          _buildEmptyState(context)
                        else
                          _buildPondList(ponds, user, colorScheme),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showOnlineMessage
                        ? Container(
                            key: const ValueKey('online'),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            color: colorScheme.primaryContainer,
                            child: Text(
                              "Back online!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: hasPonds
              ? AnimatedSlide(
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
                            color: colorScheme.primary.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: CustomShowcase(
                        showcaseKey: _fabKey,
                        scope: 'dashboard',
                        title: "Create a Pond Workspace",
                        description: "Tap here to initialize a new pond workspace! Define your target culture period, species, and initial dimensions.",
                        child: FloatingActionButton.extended(
                          heroTag: 'dashboard_fab',
                          onPressed: () => _showCreatePondSheet(context),
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
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildPondList(List<Pond> ponds, User user, ColorScheme colorScheme) {
    // Sort client-side by createdAt descending without mutating original list
    final sortedPonds = List<Pond>.from(ponds)
      ..sort((a, b) {
        final tA = a.createdAt;
        final tB = b.createdAt;
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });

    final uniqueSpecies = sortedPonds
        .map((p) => p.species.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    uniqueSpecies.sort();

    // Apply search and filter
    final filteredPonds = sortedPonds.where((pond) {
      final String pondName = pond.name.isNotEmpty ? pond.name : 'Unnamed Pond';
      final String userRole = pond.roles[user.uid] ?? 'viewer';

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!pondName.toLowerCase().contains(query) &&
            !pond.species.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Role filter
      if (_filterRole != null && userRole != _filterRole) {
        return false;
      }

      // Species filter
      if (_filterSpecies != null &&
          pond.species.trim().toLowerCase() != _filterSpecies!.trim().toLowerCase()) {
        return false;
      }

      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      child: NotificationListener<ScrollNotification>(
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
      child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(
            16,
          ).copyWith(bottom: 100),
          itemCount: filteredPonds.isEmpty ? 3 : filteredPonds.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return CustomShowcase(
                showcaseKey: _aquariumKey,
                scope: 'dashboard',
                title: "Pondy's Ecosystem",
                description: "This is Pondy, your smart farm companion! Tap on the tank to interact, drop feed, or view an immersive full-screen aquarium ecosystem. Keep Pondy happy by interacting with the tank!",
                child: const PondyAquariumCard(),
              );
            }
            if (index == 1) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12.0,
                      left: 4.0,
                    ),
                    child: Text(
                      "Pond List",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // Search and Filter Row
                  Row(
                    children: [
                      Expanded(
                        child: CustomShowcase(
                          showcaseKey: _searchKey,
                          scope: 'dashboard',
                          title: "Search Ponds",
                          description: "Quickly locate specific ponds by typing their names or species in this search bar.",
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _searchFocusNode.hasFocus
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Search ponds...',
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: _searchFocusNode.hasFocus
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear_rounded,
                                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: CustomShowcase(
                          showcaseKey: _filterKey,
                          scope: 'dashboard',
                          title: "Filter Ponds",
                          description: "Filter your list of ponds by species or by your assigned collaborator role (Owner, Editor, Viewer).",
                          child: PondFilterDropdown(
                            uniqueSpecies: uniqueSpecies,
                            filterRole: _filterRole,
                            filterSpecies: _filterSpecies,
                            onRoleChanged: (role) => setState(() => _filterRole = role),
                            onSpeciesChanged: (species) => setState(() => _filterSpecies = species),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }

            if (filteredPonds.isEmpty && index == 2) {
              return Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
                child: EmptyStateCard(
                  image: const Icon(Icons.search_off_rounded, size: 48),
                  title: "No Ponds Found",
                  description: "Try adjusting your search keywords or filters to find what you're looking for.",
                  action: SecondaryButton(
                    text: "Clear Search",
                    onPressed: () {
                      _searchFocusNode.unfocus();
                      _searchController.clear();
                      setState(() {
                        _filterRole = null;
                        _filterSpecies = null;
                      });
                    },
                    width: 180,
                  ),
                ),
              );
            }

            final pond = filteredPonds[index - 2];
            final String pondName = pond.name.isNotEmpty ? pond.name : 'Unnamed Pond';
            final String userRole = pond.roles[user.uid] ?? 'viewer';
            final bool isOwner = userRole == 'owner';

            final card = ErrorBoundary(
              child: PondListCard(
              pondId: pond.id,
              pondName: pondName,
              species: pond.species.isNotEmpty ? pond.species : 'Unspecified',
              userRole: userRole,
              createdAt: pond.createdAt ?? DateTime.now(),
              targetCulturePeriodDays: pond.targetCulturePeriodDays > 0 ? pond.targetCulturePeriodDays : 90,
              ),
            );

            final Widget itemContent = PondSlidableActionWrapper(
              pondId: pond.id,
              pondName: pondName,
              isOwner: isOwner,
              onEdit: () {
                _showEditPondSheet(
                  context,
                  pond.id,
                  pond.toJson(),
                );
              },
              onDelete: () {
                _deletePond(pond.id, pondName);
              },
              child: card,
            );

            Widget finalItem = itemContent;
            if (index == 2) {
              finalItem = CustomShowcase(
                showcaseKey: _pondCardKey,
                scope: 'dashboard',
                title: "Pond Workspaces",
                description: "Tap any pond card to open its detailed monitoring dashboard. Swipe left on a card to quickly edit or delete it (if you are the owner).",
                child: itemContent,
              );
            }

            return StaggeredListItem(
              index: index - 2,
              child: finalItem,
            );
          },
        ),
      ),
    );
  }



  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 150,
          child: NoPondAssignedWidget(
            onCreatePond: () => _showCreatePondSheet(context),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String rawError) {
    String friendlyMessage =
        "We couldn't connect to our servers right now. Please check your internet connection.";
    if (rawError.contains('permission-denied')) {
      friendlyMessage = "You don't have permission to view this data.";
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: EmptyStateCard(
        image: const Icon(Icons.cloud_off_rounded),
        title: "Unable to Load",
        description: friendlyMessage,
        scrollable: true,
        action: SecondaryButton(
          text: "Try Again",
          icon: Icons.refresh_rounded,
          onPressed: _refreshData,
        ),
      ),
    );
  }
}



