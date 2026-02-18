import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sendme_rider/flutter_project_imports.dart';

/// What's blocking location access
enum LocationIssue { permission, service, both }

/// Full-screen location permission/service screen.
/// Shown when location permission is denied OR GPS is off OR both.
/// Single "Allow" button — handles re-requesting whatever is needed.
class LocationPermissionScreen extends StatefulWidget {
  final LocationIssue issue;
  final VoidCallback? onGranted;

  const LocationPermissionScreen({
    super.key,
    this.issue = LocationIssue.both,
    this.onGranted,
  });

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen>
    with WidgetsBindingObserver {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Listen for app resume (user comes back from settings)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// When user returns from settings, re-check automatically
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndProceed();
    }
  }

  /// Check both permission + service, and if both OK, try to get location
  Future<void> _checkAndProceed() async {
    if (_loading) return;
    setState(() => _loading = true);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    final hasPermission = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (serviceEnabled && hasPermission) {
      // Both OK — try to actually get location
      try {
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 15));

        if (mounted) {
          widget.onGranted?.call();
          Navigator.of(context).pop(true);
          return;
        }
      } catch (_) {
        // Location fetch failed even with permission + service
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  /// Handle the "Allow" button tap
  Future<void> _onAllowPressed() async {
    setState(() => _loading = true);

    // 1. Check GPS service
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Open GPS settings — user needs to turn it on
      await Geolocator.openLocationSettings();
      // Will re-check in didChangeAppLifecycleState when user returns
      if (mounted) setState(() => _loading = false);
      return;
    }

    // 2. Check permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      // Permanently denied — must go to app settings
      await Geolocator.openAppSettings();
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (permission == LocationPermission.denied) {
      // Request permission via system dialog
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        if (mounted) setState(() => _loading = false);
        return;
      }
    }

    // 3. Permission granted + service on — try to get actual location
    try {
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));

      // Success
      if (mounted) {
        widget.onGranted?.call();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _getMessage() {
    switch (widget.issue) {
      case LocationIssue.service:
        return AppLocalizations.of(context)
                ?.translate('LocationServiceOff') ??
            'Your GPS/Location service is turned off. Please enable it to continue.';
      case LocationIssue.permission:
        return AppLocalizations.of(context)
                ?.translate('LocationDeniedMessage') ??
            'Location permission is not granted. Please allow location access to provide delivery services.';
      case LocationIssue.both:
        return AppLocalizations.of(context)
                ?.translate('LocationDeniedMessage') ??
            'We need access to your location to provide delivery services. Please grant location permission and enable GPS.';
    }
  }

  IconData _getIcon() {
    switch (widget.issue) {
      case LocationIssue.service:
        return Icons.gps_off_rounded;
      case LocationIssue.permission:
        return Icons.location_disabled_rounded;
      case LocationIssue.both:
        return Icons.location_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: _loading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      Icon(
                        _getIcon(),
                        size: 100,
                        color: AppColors.mainAppColor.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppLocalizations.of(context)
                                ?.translate('LocationDenied') ??
                            'Location Access Required',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AssetsFont.textBold,
                          fontSize: 18,
                          color: AppColors.mainAppColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _getMessage(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AssetsFont.textRegular,
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _onAllowPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainAppColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)
                                      ?.translate('Allow') ??
                                  'Allow',
                              style: const TextStyle(
                                fontFamily: AssetsFont.textBold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
