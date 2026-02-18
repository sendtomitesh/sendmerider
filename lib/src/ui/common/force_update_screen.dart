import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sendme_rider/flutter_project_imports.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.system_update_rounded,
                  size: 80,
                  color: AppColors.mainAppColor,
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)?.translate('forceUpdateTitle') ??
                      'Update Required',
                  style: const TextStyle(
                    fontFamily: AssetsFont.textBold,
                    fontSize: 24,
                    color: AppColors.textColorBold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(
                        context,
                      )?.translate('forceUpdateMessage') ??
                      'A new version of the app is available. Please update to continue.',
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
                  child: ElevatedButton(
                    onPressed: _openStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainAppColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.translate('updateNow') ??
                          'Update Now',
                      style: const TextStyle(
                        fontFamily: AssetsFont.textBold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openStore() async {
    final url = Platform.isIOS
        ? 'https://apps.apple.com/app/${GlobalConstants.packageName}'
        : 'https://play.google.com/store/apps/details?id=${GlobalConstants.packageName}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
