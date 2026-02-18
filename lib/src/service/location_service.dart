import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:sendme_rider/src/api/api_path.dart';
import 'package:sendme_rider/src/common/global_constants.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Timer? _timer;
  Timer? _permissionTimer;
  int? _riderId;
  int? _cityId;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  /// Callback when GPS gets turned off while tracking.
  /// The UI should listen to this and show the location permission screen.
  VoidCallback? onGpsDisabled;

  /// Callback when location permission is lost while tracking.
  VoidCallback? onPermissionLost;

  /// Request location permissions directly — no custom UI, just the system dialog.
  /// Returns true if at least foreground access is granted.
  /// Also attempts background location for rider tracking.
  static Future<bool> requestPermissions() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      debugPrint('LocationService: GPS is disabled');
      return false;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      debugPrint('LocationService: permission denied forever');
      return false;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: permission denied');
        return false;
      }
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
    }

    // Try requesting background (always) permission via permission_handler
    if (permission == LocationPermission.whileInUse) {
      try {
        final bgStatus = await ph.Permission.locationAlways.request();
        debugPrint('LocationService: background permission result: $bgStatus');
      } catch (e) {
        debugPrint('LocationService: background permission request error: $e');
      }
    }

    return true;
  }

  /// Start a periodic timer that re-checks permission every [minutes] minutes.
  /// If permission is not granted, it re-requests it.
  void startPermissionWatcher({int minutes = 3}) {
    _permissionTimer?.cancel();
    _permissionTimer = Timer.periodic(
      Duration(minutes: minutes),
      (_) => _checkAndRequestPermission(),
    );
  }

  void stopPermissionWatcher() {
    _permissionTimer?.cancel();
    _permissionTimer = null;
  }

  Future<void> _checkAndRequestPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('LocationService: permission not granted, re-requesting...');
      await requestPermissions();
    }
  }

  Future<void> startTracking({
    required int riderId,
    required int cityId,
  }) async {
    if (_isTracking) return;
    _riderId = riderId;
    _cityId = cityId;
    _isTracking = true;

    // Send immediately, then every 60 seconds (matching original app's Timer.periodic 60000ms)
    await _checkGpsAndSendUpdate();
    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _checkGpsAndSendUpdate(),
    );
  }

  Future<void> stopTracking() async {
    _timer?.cancel();
    _timer = null;
    _isTracking = false;
    stopPermissionWatcher();
  }

  /// Matches the original app's _checkGps() pattern:
  /// 1. Check if GPS service is enabled — if not, notify UI
  /// 2. Check permission — if lost, notify UI
  /// 3. Get current position
  /// 4. Send to server
  Future<void> _checkGpsAndSendUpdate() async {
    try {
      // Check GPS service (like original app's _checkGps)
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        debugPrint('LocationService: GPS disabled during tracking');
        onGpsDisabled?.call();
        return;
      }

      // Check permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: permission lost during tracking');
        onPermissionLost?.call();
        return;
      }

      // Get current position (like original app's getCurrentPosition in _checkGps)
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Send to server (like original app's riderLocation())
      await _sendLocationToServer(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('LocationService: error getting location: $e');
    }
  }

  Future<void> _sendLocationToServer(double lat, double lng) async {
    if (_riderId == null) return;
    try {
      final url =
          '${ApiPath.saveRiderLocation}'
          'lat=$lat'
          '&lng=$lng'
          '&riderId=$_riderId'
          '&cityId=$_cityId'
          '&deviceId=${GlobalConstants.deviceId}'
          '&userType=${GlobalConstants.rider}'
          '&deviceType=${GlobalConstants.deviceType}'
          '&version=${GlobalConstants.appVersion}';

      final response = await http.get(Uri.parse(url));
      debugPrint(
        'LocationService: sent location ($lat, $lng) -> ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('LocationService: failed to send location: $e');
    }
  }
}
