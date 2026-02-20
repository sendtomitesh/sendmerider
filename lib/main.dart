import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';
import 'package:sendme_rider/src/service/location_service.dart';
import 'package:sendme_rider/src/service/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _initDeviceInfo();
  await _initFirebaseToken();
  await NotificationService.initialize();
  await LocationService.initializeService();
  LocationService.cacheAppCredentials(
    packageName: ThemeUI.appPackageName,
    password: ThemeUI.appPassword,
  );
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
        fontFamily: AssetsFont.textMedium,
      ),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final loggedIn = await PreferencesHelper.isLoggedIn();
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
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.shrink(),
    );
  }
}
