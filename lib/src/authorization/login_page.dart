import 'package:geolocator/geolocator.dart';
import 'package:sendme_rider/flutter_imports.dart';
import 'package:sendme_rider/flutter_project_imports.dart';

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
      _showLocationPermissionModal();
    });
  }

  Future<void> _showLocationPermissionModal() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AssetsImage.sendmeRiderTrackingApp,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.translate('LocationPermission') ??
                    'Location Permission',
                style: TextStyle(
                  fontFamily: AssetsFont.textBold,
                  fontSize: 18,
                  color: AppColors.mainAppColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(
                      context,
                    )?.translate('LocationPermissionBody') ??
                    'We need your location to provide delivery services',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AssetsFont.textRegular,
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.mainAppColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        AppLocalizations.of(
                              context,
                            )?.translate('AddManually') ??
                            'Add Manually',
                        style: TextStyle(
                          fontFamily: AssetsFont.textBold,
                          fontSize: 14,
                          color: AppColors.mainAppColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await Geolocator.requestPermission();
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainAppColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.translate('Allow') ??
                            'Allow',
                        style: const TextStyle(
                          fontFamily: AssetsFont.textBold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
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
