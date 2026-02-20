import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sendme_rider/src/api/api_path.dart';
import 'package:sendme_rider/src/common/global_constants.dart';

/// Notification channel for the foreground service
const _kChannelId = 'location_service_channel';
const _kNotificationId = 999;

/// SharedPreferences keys used by the background isolate
const _kKeyRiderId = 'bg_rider_id';
const _kKeyCityId = 'bg_city_id';
const _kKeyPhone = 'bg_phone';
const _kKeyDeviceId = 'bg_device_id';
const _kKeyDeviceType = 'bg_device_type';
const _kKeyAppVersion = 'bg_app_version';
const _kKeyAuthHeader = 'bg_auth_header';
const _kKeyExtraParams = 'bg_extra_params';
const _kKeyBgStartTime = 'bg_start_time';

// ─── Background isolate entry point ───────────────────────────────────────────
// This runs in a SEPARATE isolate — no access to main isolate singletons.
// Must read everything from SharedPreferences.

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Listen for stop command from UI isolate
  service.on('stop').listen((_) {
    service.stopSelf();
  });

  // Listen for updated credentials from UI isolate
  service.on('updateCredentials').listen((data) async {
    if (data == null) return;
    final p = await SharedPreferences.getInstance();
    if (data['riderId'] != null) p.setInt(_kKeyRiderId, data['riderId']);
    if (data['cityId'] != null) p.setInt(_kKeyCityId, data['cityId']);
    if (data['phone'] != null) p.setString(_kKeyPhone, data['phone']);
    if (data['authHeader'] != null) {
      p.setString(_kKeyAuthHeader, data['authHeader']);
    }
    if (data['extraParams'] != null) {
      p.setString(_kKeyExtraParams, data['extraParams']);
    }
  });

  // Record when background started (for 30-min auto-stop)
  service.on('enterBackground').listen((_) async {
    final p = await SharedPreferences.getInstance();
    p.setInt(_kKeyBgStartTime, DateTime.now().millisecondsSinceEpoch);
    debugPrint('LocationService BG: entered background');
  });

  service.on('enterForeground').listen((_) async {
    final p = await SharedPreferences.getInstance();
    p.remove(_kKeyBgStartTime);
    debugPrint('LocationService BG: entered foreground');
  });

  // Send location every 60 seconds
  Timer.periodic(const Duration(seconds: 60), (_) async {
    await _sendLocationFromBackground(prefs, service);
  });

  // Also send immediately on start
  await _sendLocationFromBackground(prefs, service);
}

Future<void> _sendLocationFromBackground(
  SharedPreferences prefs,
  ServiceInstance service,
) async {
  try {
    // Check 30-min background timeout
    final bgStart = prefs.getInt(_kKeyBgStartTime);
    if (bgStart != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - bgStart;
      if (elapsed > 30 * 60 * 1000) {
        debugPrint('LocationService BG: 30-min timeout — stopping');
        service.stopSelf();
        return;
      }
    }

    // Reload prefs to get latest credentials
    await prefs.reload();

    final riderId = prefs.getInt(_kKeyRiderId);
    final cityId = prefs.getInt(_kKeyCityId);
    final phone = prefs.getString(_kKeyPhone) ?? '';
    final deviceId = prefs.getString(_kKeyDeviceId) ?? '';
    final deviceType = prefs.getInt(_kKeyDeviceType) ?? 1;
    final appVersion = prefs.getString(_kKeyAppVersion) ?? '';
    final authHeader = prefs.getString(_kKeyAuthHeader) ?? '';
    final extraParams = prefs.getString(_kKeyExtraParams) ?? '';

    if (riderId == null) {
      debugPrint('LocationService BG: no riderId — skipping');
      return;
    }

    // Check GPS
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      debugPrint('LocationService BG: GPS disabled');
      return;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('LocationService BG: permission lost');
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final url =
        '${ApiPath.saveRiderLocation}'
        'lat=${pos.latitude}'
        '&lng=${pos.longitude}'
        '&riderId=$riderId'
        '&cityId=$cityId'
        '&deviceId=$deviceId'
        '&userType=${GlobalConstants.rider}'
        '&deviceType=$deviceType'
        '&version=$appVersion'
        '&phoneNumberLogs=$phone'
        '$extraParams';

    final headers = <String, String>{'referer': 'https://sendme.today/'};
    if (authHeader.isNotEmpty) {
      headers['authorization'] = authHeader;
    }

    final response = await http.get(Uri.parse(url), headers: headers);
    debugPrint(
      'LocationService BG: sent (${pos.latitude}, ${pos.longitude}) -> ${response.statusCode}',
    );
  } catch (e) {
    debugPrint('LocationService BG: error: $e');
  }
}

// ─── Main isolate class ───────────────────────────────────────────────────────

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  int? _riderId;
  int? _cityId;
  String? _phoneNumber;
  Timer? _permissionTimer;

  /// Callback when GPS gets turned off while tracking.
  VoidCallback? onGpsDisabled;

  /// Callback when location permission is lost while tracking.
  VoidCallback? onPermissionLost;

  /// Initialize the background service — call once from main().
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Create notification channel for foreground service
    const channel = AndroidNotificationChannel(
      _kChannelId,
      'Location Tracking',
      description: 'Keeps tracking your location for deliveries',
      importance: Importance.low,
    );

    final flnPlugin = FlutterLocalNotificationsPlugin();
    await flnPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _kChannelId,
        initialNotificationTitle: 'SendMe Rider',
        initialNotificationContent: 'Sharing your location...',
        foregroundServiceNotificationId: _kNotificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Request location permissions — returns true if at least foreground granted.
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
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
    }

    // Try requesting background (always) permission
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

  /// Start periodic permission re-check.
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

  /// Save credentials to SharedPreferences so the background isolate can read them.
  Future<void> _saveCredentialsForBackground({
    required String authHeader,
    required String extraParams,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_kKeyRiderId, _riderId!);
    prefs.setInt(_kKeyCityId, _cityId ?? 0);
    prefs.setString(_kKeyPhone, _phoneNumber ?? '');
    prefs.setString(_kKeyDeviceId, GlobalConstants.deviceId);
    prefs.setInt(_kKeyDeviceType, GlobalConstants.deviceType ?? 1);
    prefs.setString(_kKeyAppVersion, GlobalConstants.appVersion);
    prefs.setString(_kKeyAuthHeader, authHeader);
    prefs.setString(_kKeyExtraParams, extraParams);
    // Clear any stale background start time
    prefs.remove(_kKeyBgStartTime);
  }

  /// Build the auth header the same way RiderApiService does.
  Future<String> _buildAuthHeader() async {
    String basicAuth = 'Basic ${base64Encode(utf8.encode('SendMe'))}';
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('RiderData');
      if (userData != null && userData.isNotEmpty) {
        final jsonData = jsonDecode(userData) as Map<String, dynamic>;
        final rest = jsonData['Data'];
        if (rest != null) {
          final userId = rest['UserId'];
          final userType = rest['userType'] ?? 0;
          final mobile = rest['userMobile'] ?? rest['Mobile'] ?? '';
          final now = DateTime.now();
          final password = '$userId*$userType*${now.minute}';
          basicAuth = 'Basic ${base64Encode(utf8.encode('$mobile:$password'))}';
        }
      }
    } catch (e) {
      debugPrint('LocationService: _buildAuthHeader error: $e');
    }
    return basicAuth;
  }

  /// Build extra GET params matching RiderApiService._extraGetParams().
  Future<String> _buildExtraParams() async {
    String phone = '';
    String userName = '';
    int? userId;
    int? cityId;
    String packageName = '';
    String password = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('RiderData');
      if (userData != null && userData.isNotEmpty) {
        final jsonData = jsonDecode(userData) as Map<String, dynamic>;
        final rest = jsonData['Data'];
        if (rest != null) {
          phone = (rest['userMobile'] ?? rest['Mobile'] ?? '').toString();
          userName = (rest['Name'] ?? '').toString();
          userId = rest['UserId'] is int
              ? rest['UserId']
              : int.tryParse('${rest['UserId']}');
          cityId = rest['cityId'] is int
              ? rest['cityId']
              : int.tryParse('${rest['cityId']}');
        }
      }
    } catch (_) {}
    try {
      // Import ThemeUI values — these are static so we can read them here
      packageName = _getPackageName();
      password = _getPackagePassword();
    } catch (_) {}
    return '&adminId=$userId'
        '&phoneNumberLogs=$phone'
        '&userNameLogs=${Uri.encodeComponent(userName)}'
        '&cityIdLogs=$cityId'
        '&requestfrom=app'
        '&userLatitude=${GlobalConstants.userAddressLatitude ?? 0.0}'
        '&userLongitude=${GlobalConstants.userAddressLongitude ?? 0.0}'
        '&packageName=$packageName'
        '&password=$password';
  }

  // These access ThemeUI statics which are available in the main isolate
  String _getPackageName() {
    // Inline import to avoid issues
    return _cachedPackageName;
  }

  String _getPackagePassword() {
    return _cachedPassword;
  }

  static String _cachedPackageName = '';
  static String _cachedPassword = '';

  /// Call this once from main isolate to cache ThemeUI values.
  static void cacheAppCredentials({
    required String packageName,
    required String password,
  }) {
    _cachedPackageName = packageName;
    _cachedPassword = password;
  }

  /// Start tracking — launches the background service.
  Future<void> startTracking({
    required int riderId,
    required int cityId,
    required String phoneNumber,
  }) async {
    if (_isTracking) return;
    _riderId = riderId;
    _cityId = cityId;
    _phoneNumber = phoneNumber;
    _isTracking = true;

    // Save credentials for background isolate
    final authHeader = await _buildAuthHeader();
    final extraParams = await _buildExtraParams();
    await _saveCredentialsForBackground(
      authHeader: authHeader,
      extraParams: extraParams,
    );

    // Start the background service
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
      debugPrint('LocationService: background service started');
    } else {
      // Service already running — just update credentials
      service.invoke('updateCredentials', {
        'riderId': riderId,
        'cityId': cityId,
        'phone': phoneNumber,
        'authHeader': authHeader,
        'extraParams': extraParams,
      });
      debugPrint('LocationService: updated credentials on running service');
    }
  }

  /// Stop tracking — stops the background service.
  Future<void> stopTracking() async {
    _isTracking = false;
    _riderId = null;
    _cityId = null;
    _phoneNumber = null;
    stopPermissionWatcher();

    // Clear ALL background credentials so the isolate can't send after stop
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_kKeyRiderId);
    prefs.remove(_kKeyCityId);
    prefs.remove(_kKeyPhone);
    prefs.remove(_kKeyAuthHeader);
    prefs.remove(_kKeyExtraParams);
    prefs.remove(_kKeyBgStartTime);

    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke('stop');
      debugPrint('LocationService: background service stopped');
    }
  }

  /// Called when app goes to background — tell the service to start the 30-min timer.
  void onAppPaused() {
    if (!_isTracking) return;
    final service = FlutterBackgroundService();
    service.invoke('enterBackground');
    debugPrint('LocationService: app paused — 30-min timer started');
  }

  /// Called when app comes back to foreground.
  /// If service stopped itself (30-min timeout), restart it.
  Future<void> onAppResumed() async {
    if (!_isTracking) return;
    final service = FlutterBackgroundService();
    service.invoke('enterForeground');

    // Check if service is still running — if not, restart
    final isRunning = await service.isRunning();
    if (!isRunning && _riderId != null) {
      debugPrint('LocationService: service was stopped — restarting');
      _isTracking = false; // Reset so startTracking works
      await startTracking(
        riderId: _riderId!,
        cityId: _cityId ?? 0,
        phoneNumber: _phoneNumber ?? '',
      );
    } else {
      debugPrint('LocationService: app resumed — service still running');
    }
  }
}
