import 'package:sendme_rider/AppConfig.dart';

class ThemeUI {
  // App Branding — derived from activeApp
  static String appPackageName = activeApp.packageName;
  static String appPassword = activeApp.packagePassword;
  static String appDomainName = activeApp.domainName;
  static String appName = activeApp.name;
  static int appType = activeApp.appType;
  static String androidLink = activeApp.androidAppLink;
  static String iosLink = activeApp.iosAppLink;
  static String email = activeApp.email;
  static String privacyPolicyLink = activeApp.privacyPolicyLink;
  static String termsAndConditionsLink = activeApp.termsAndConditionsLink;
  static String whatsappLink = activeApp.whatsappLink;

  // Rider App Bar Theme
  static bool isStatusBarDark = true;
  static String bgColorAppBar = '#FFFFFF';
  static String textColorAppBar = '#000000';

  // Rider Dashboard Theme
  static int themeIdDashboard = 1;

  // Rider Order List Theme
  static int themeIdOrderList = 1;

  // Rider Order Detail Theme
  static int themeIdOrderDetail = 1;

  // Rider Map Theme
  static int themeIdMap = 1;

  // Rider Profile Theme
  static int themeIdProfile = 1;

  // Languages
  static List<String> languageList = ['English', 'Arabic', 'Hindi', 'French'];
}
