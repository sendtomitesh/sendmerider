import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Lightweight internet connectivity checker.
/// Uses a DNS lookup to verify actual internet access.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  Timer? _timer;
  bool _lastStatus = true;

  /// Stream of connectivity changes (true = online, false = offline).
  Stream<bool> get onStatusChange => _controller.stream;

  /// Current connectivity status.
  bool get isOnline => _lastStatus;

  /// Check internet connectivity right now.
  static Future<bool> checkNow() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Start periodic connectivity monitoring every [seconds] seconds.
  void startMonitoring({int seconds = 15}) {
    _timer?.cancel();
    _checkAndNotify();
    _timer = Timer.periodic(
      Duration(seconds: seconds),
      (_) => _checkAndNotify(),
    );
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkAndNotify() async {
    final online = await checkNow();
    if (online != _lastStatus) {
      _lastStatus = online;
      _controller.add(online);
      debugPrint(
        'ConnectivityService: status changed -> ${online ? "online" : "offline"}',
      );
    }
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}
