import 'package:geolocator/geolocator.dart';
import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';
import 'package:sendme_rider/src/ui/common/location_permission_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleLocationPermission();
    });
  }

  /// Check permission + GPS + actually get location.
  /// If anything fails, show the LocationPermissionScreen with the right issue type.
  Future<void> _handleLocationPermission() async {
    if (!mounted) return;

    // Check GPS service
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    // Check permission status
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final hasPermission =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    // Determine what's wrong
    if (!serviceEnabled && !hasPermission) {
      _showLocationScreen(LocationIssue.both);
      return;
    }
    if (!serviceEnabled) {
      _showLocationScreen(LocationIssue.service);
      return;
    }
    if (!hasPermission) {
      _showLocationScreen(LocationIssue.permission);
      return;
    }

    // Both OK — try to actually get the location
    try {
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));
      // Location obtained successfully
    } catch (_) {
      // Could not get location even with permission + service on
      _showLocationScreen(LocationIssue.both);
    }
  }

  void _showLocationScreen(LocationIssue issue) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LocationPermissionScreen(issue: issue)),
    );
  }

  void _onLoginSuccess() async {
    final rider = await PreferencesHelper.getSavedRider();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RiderDashboard(riderName: rider?.name ?? 'Rider'),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.grey.shade50,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: PhoneVerificationView(onLoginSuccess: _onLoginSuccess),
        ),
      ),
    );
  }
}
