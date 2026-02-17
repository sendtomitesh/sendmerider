import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sendme_rider/src/models/user_model.dart';

class PreferencesHelper {
  static const String prefRiderData = 'RiderData';

  static Future<String?> readStringPref(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<bool> saveStringPref(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  static Future<bool> isLoggedIn() async {
    try {
      final data = await readStringPref(prefRiderData);
      if (data == null || data.isEmpty) return false;
      final json = jsonDecode(data) as Map<String, dynamic>;
      return json['Data'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<UserModel?> getSavedRider() async {
    try {
      final data = await readStringPref(prefRiderData);
      debugPrint(
        'PreferencesHelper.getSavedRider raw data: ${data?.substring(0, data.length > 200 ? 200 : data.length)}',
      );
      if (data == null || data.isEmpty) return null;
      final json = jsonDecode(data) as Map<String, dynamic>;
      final userData = json['Data'];
      debugPrint(
        'PreferencesHelper.getSavedRider userData keys: ${(userData as Map?)?.keys}',
      );
      if (userData == null) return null;
      return UserModel.fromJson(userData as Map<String, dynamic>);
    } catch (e) {
      debugPrint('PreferencesHelper.getSavedRider error: $e');
      return null;
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefRiderData);
  }
}
