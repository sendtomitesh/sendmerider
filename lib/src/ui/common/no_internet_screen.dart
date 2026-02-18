import 'package:flutter/material.dart';
import 'package:sendme_rider/flutter_project_imports.dart';
import 'package:sendme_rider/src/service/connectivity_service.dart';

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    final online = await ConnectivityService.checkNow();
    if (!mounted) return;
    if (online) {
      Navigator.of(context).pop();
    } else {
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.translate('stillNoInternet') ??
                'Still no internet. Please check your connection.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(
                      context,
                    )?.translate('noInternetConnection') ??
                    'No Internet Connection',
                style: const TextStyle(
                  fontFamily: AssetsFont.textBold,
                  fontSize: 20,
                  color: AppColors.textColorBold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)?.translate('noInternetMessage') ??
                    'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AssetsFont.textRegular,
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _checking ? null : _retry,
                  icon: _checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _checking
                        ? (AppLocalizations.of(
                                context,
                              )?.translate('checking') ??
                              'Checking...')
                        : (AppLocalizations.of(context)?.translate('retry') ??
                              'Retry'),
                    style: const TextStyle(
                      fontFamily: AssetsFont.textBold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainAppColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
