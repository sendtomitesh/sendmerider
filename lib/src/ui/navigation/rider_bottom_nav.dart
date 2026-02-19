import 'package:geolocator/geolocator.dart';
import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';
import 'package:sendme_rider/src/service/location_service.dart';
import 'package:sendme_rider/src/service/notification_service.dart';
import 'package:sendme_rider/src/service/connectivity_service.dart';
import 'package:sendme_rider/src/ui/common/no_internet_screen.dart';
import 'package:sendme_rider/src/ui/common/location_permission_screen.dart';
// import 'package:sendme_rider/src/ui/common/force_update_screen.dart';

class RiderBottomNav extends StatefulWidget {
  final String riderName;
  const RiderBottomNav({super.key, required this.riderName});

  @override
  State<RiderBottomNav> createState() => _RiderBottomNavState();
}

class _RiderBottomNavState extends State<RiderBottomNav> {
  RiderProfile? _rider;
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;
  final _apiService = RiderApiService();
  StreamSubscription<bool>? _connectivitySub;
  bool _isShowingNoInternet = false;
  bool _isShowingLocationScreen = false;
  List<Widget>? _pages;

  @override
  void initState() {
    super.initState();
    _setupConnectivityMonitor();
    _setupLocationCallbacks();
    _loadRider();
  }

  @override
  void dispose() {
    LocationService.instance.onGpsDisabled = null;
    LocationService.instance.onPermissionLost = null;
    LocationService.instance.stopTracking();
    LocationService.instance.stopPermissionWatcher();
    ConnectivityService.instance.stopMonitoring();
    _connectivitySub?.cancel();
    super.dispose();
  }

  /// Listen for GPS/permission loss during tracking (like original app's _checkGps)
  void _setupLocationCallbacks() {
    LocationService.instance.onGpsDisabled = () {
      if (mounted && !_isShowingLocationScreen) {
        _isShowingLocationScreen = true;
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => const LocationPermissionScreen(
                  issue: LocationIssue.service,
                ),
              ),
            )
            .then((_) => _isShowingLocationScreen = false);
      }
    };
    LocationService.instance.onPermissionLost = () {
      if (mounted && !_isShowingLocationScreen) {
        _isShowingLocationScreen = true;
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => const LocationPermissionScreen(
                  issue: LocationIssue.permission,
                ),
              ),
            )
            .then((_) => _isShowingLocationScreen = false);
      }
    };
  }

  void _setupConnectivityMonitor() {
    ConnectivityService.instance.startMonitoring();
    _connectivitySub = ConnectivityService.instance.onStatusChange.listen((
      online,
    ) {
      if (!online && mounted && !_isShowingNoInternet) {
        _isShowingNoInternet = true;
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const NoInternetScreen()))
            .then((_) {
              _isShowingNoInternet = false;
              // Retry loading if we were in error state
              if (_error != null) _loadRider();
            });
      }
    });
  }

  Future<void> _loadRider() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final saved = await PreferencesHelper.getSavedRider();
      if (saved == null || (saved.mobile ?? '').isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'No saved rider data found. Please log in again.';
        });
        return;
      }

      final result = await _apiService.fetchRiderProfileWithMeta(
        mobile: saved.mobile!,
      );
      final riderProfile = result.profile;
      final rawResponse = result.rawResponse;

      if (!mounted) return;

      // Check if rider is blocked
      final isBlocked = _parseInt(rawResponse['isBlocked']) == 1;
      if (isBlocked) {
        await PreferencesHelper.clearSession();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      // Force update check — skip for standalone rider app since the backend
      // returns the customer app version which doesn't apply here.
      // TODO: Re-enable when rider app has its own version tracking on the backend.
      // final serverVersion = Platform.isIOS
      //     ? (rawResponse['IOSVersion']?.toString() ?? '')
      //     : (rawResponse['AndroidVersion']?.toString() ?? '');
      // if (serverVersion.isNotEmpty &&
      //     _isNewerVersion(serverVersion, GlobalConstants.appVersion)) {
      //   if (!mounted) return;
      //   Navigator.of(context).pushAndRemoveUntil(
      //     MaterialPageRoute(builder: (_) => const ForceUpdateScreen()),
      //     (route) => false,
      //   );
      //   return;
      // }

      setState(() {
        _rider = riderProfile.copyWith(
          name: riderProfile.name.isNotEmpty
              ? riderProfile.name
              : (saved.name ?? widget.riderName),
        );
        _isLoading = false;
      });
      // Request location permission and try to get actual location
      final hasPermission = await LocationService.requestPermissions();
      if (!hasPermission) {
        // Determine what's wrong — permission or service or both
        LocationService.instance.startPermissionWatcher(minutes: 3);
        if (mounted) {
          final serviceOn = await Geolocator.isLocationServiceEnabled();
          final perm = await Geolocator.checkPermission();
          final permOk =
              perm == LocationPermission.always ||
              perm == LocationPermission.whileInUse;
          LocationIssue issue;
          if (!serviceOn && !permOk) {
            issue = LocationIssue.both;
          } else if (!serviceOn) {
            issue = LocationIssue.service;
          } else {
            issue = LocationIssue.permission;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LocationPermissionScreen(issue: issue),
            ),
          );
        }
      } else {
        // Permission granted — verify we can actually get location
        try {
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(const Duration(seconds: 15));
        } catch (_) {
          // Could not get location — show permission screen
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const LocationPermissionScreen(issue: LocationIssue.both),
              ),
            );
          }
        }
      }
      _updateLocationTracking();
      // Register for push notifications
      NotificationService.registerToken(_rider!.id);
      NotificationService.setNavigationCallback(_onNotificationOrderTap);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load rider profile';
      });
    }
  }

  /// Compare semantic versions. Returns true if [server] is strictly newer than [installed].
  /// Currently unused — force update is disabled for standalone rider app.
  // bool _isNewerVersion(String server, String installed) {
  //   if (server.isEmpty || installed.isEmpty) return false;
  //   final sParts = server.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  //   final iParts = installed
  //       .split('.')
  //       .map((s) => int.tryParse(s) ?? 0)
  //       .toList();
  //   final len = sParts.length > iParts.length ? sParts.length : iParts.length;
  //   for (int i = 0; i < len; i++) {
  //     final s = i < sParts.length ? sParts[i] : 0;
  //     final c = i < iParts.length ? iParts[i] : 0;
  //     if (s > c) return true;
  //     if (s < c) return false;
  //   }
  //   return false;
  // }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _onRiderUpdated(RiderProfile updated) {
    setState(() => _rider = updated);
    _updateLocationTracking();
  }

  void _onNotificationOrderTap(int orderId) {
    if (_rider == null || !mounted) return;
    Navigator.of(context).push<int?>(
      MaterialPageRoute(
        builder: (_) => OrderDetailPage(orderId: orderId, riderId: _rider!.id),
      ),
    );
  }

  void _updateLocationTracking() {
    if (_rider == null) return;
    if (_rider!.status == 0) {
      // Available — start tracking
      LocationService.instance.startTracking(
        riderId: _rider!.id,
        cityId: _rider!.cityId,
        phoneNumber: _rider!.contact,
      );
    } else {
      // Unavailable — stop tracking
      LocationService.instance.stopTracking();
    }
  }

  List<Widget> _buildPages() {
    _pages ??= [
      OrdersPage(riderName: _rider!.name, riderProfile: _rider),
      ReportPage(riderId: _rider!.id),
      ReviewPage(riderId: _rider!.id),
      ProfilePage(rider: _rider!, onRiderUpdated: _onRiderUpdated),
    ];
    return _pages!;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _rider == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  _error ??
                      (AppLocalizations.of(
                            context,
                          )?.translate('somethingWentWrong') ??
                          'Something went wrong'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AssetsFont.textMedium,
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadRider,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    AppLocalizations.of(context)?.translate('retry') ?? 'Retry',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainAppColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pages = _buildPages();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime != null &&
            now.difference(_lastBackPressTime!) < const Duration(seconds: 3)) {
          SystemNavigator.pop();
        } else {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.translate('pressAgainToExit') ??
                    'Press again to exit',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Center(
                      child: Container(
                        height: 3,
                        width: 30,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? AppColors.mainAppColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: AppColors.mainAppColor,
                unselectedItemColor: Colors.grey,
                selectedLabelStyle: const TextStyle(
                  fontFamily: AssetsFont.textBold,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: AssetsFont.textRegular,
                  fontSize: 12,
                ),
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list_alt_rounded),
                    label:
                        AppLocalizations.of(context)?.translate('orders') ??
                        'Orders',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart_rounded),
                    label:
                        AppLocalizations.of(context)?.translate('report') ??
                        'Report',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.star_outline_rounded),
                    label:
                        AppLocalizations.of(context)?.translate('review') ??
                        'Review',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline_rounded),
                    label:
                        AppLocalizations.of(context)?.translate('profile') ??
                        'Profile',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
