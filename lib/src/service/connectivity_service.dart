import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Lightweight internet connectivity checker.
/// Uses DNS lookups with multiple hosts to avoid false negatives.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  Timer? _timer;
  bool _lastStatus = true;
  int _consecutiveFailures = 0;

  /// Stream of connectivity changes (true = online, false = offline).
  Stream<bool> get onStatusChange => _controller.stream;

  /// Current connectivity status.
  bool get isOnline => _lastStatus;

  /// Check internet connectivity right now.
  /// Tries multiple hosts to avoid false negatives from a single DNS failure.
  static Future<bool> checkNow() async {
    final hosts = ['google.com', 'cloudflare.com', 'apple.com'];
    for (final host in hosts) {
      try {
        final result = await InternetAddress.lookup(
          host,
        ).timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  /// Start periodic connectivity monitoring every [seconds] seconds.
  void startMonitoring({int seconds = 30}) {
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
    if (online) {
      _consecutiveFailures = 0;
      if (!_lastStatus) {
        _lastStatus = true;
        _controller.add(true);
        debugPrint('ConnectivityService: back online');
      }
    } else {
      _consecutiveFailures++;
      // Only report offline after 2 consecutive failures to avoid false alarms
      if (_consecutiveFailures >= 2 && _lastStatus) {
        _lastStatus = false;
        _controller.add(false);
        debugPrint('ConnectivityService: offline');
      }
    }
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}
