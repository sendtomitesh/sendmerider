import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _initDeviceInfo();
  await _initFirebaseToken();
  runApp(const SendmeRiderApp());
}

Future<void> _initDeviceInfo() async {
  try {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      GlobalConstants.deviceId = android.id;
      GlobalConstants.deviceType = 1;
    } else {
      final ios = await deviceInfo.iosInfo;
      GlobalConstants.deviceId = ios.identifierForVendor ?? '';
      GlobalConstants.deviceType = 2;
    }
    final packageInfo = await PackageInfo.fromPlatform();
    GlobalConstants.appVersion = packageInfo.version;
  } catch (e) {
    debugPrint('Error initializing device info: $e');
  }
}

Future<void> _initFirebaseToken() async {
  try {
    GlobalConstants.firebaseToken = await FirebaseMessaging.instance.getToken();
  } catch (e) {
    debugPrint('Error getting Firebase token: $e');
  }
}

class SendmeRiderApp extends StatelessWidget {
  const SendmeRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: activeApp.name,
      theme: ThemeData(
        primarySwatch: AppColors.appPrimaryColor,
        primaryColor: AppColors.mainAppColor,
        fontFamily: AssetsFont.textRegular,
      ),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SplashRouter(),
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _showSplashThenNavigate();
  }

  Future<void> _showSplashThenNavigate() async {
    // Show splash for 3 seconds while checking session in parallel
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      PreferencesHelper.isLoggedIn(),
    ]);

    final loggedIn = results[1] as bool;

    if (!mounted) return;

    if (loggedIn) {
      final rider = await PreferencesHelper.getSavedRider();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => RiderDashboard(riderName: rider?.name ?? 'Rider'),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          AssetsImage.sendmeRiderLogo,
          width: 180,
          height: 180,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
