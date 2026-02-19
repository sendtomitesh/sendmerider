import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sendme_rider/src/api/api_path.dart';
import 'package:sendme_rider/src/common/global_constants.dart';
import 'package:sendme_rider/src/controllers/theme_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sendme_rider/src/models/review.dart';
import 'package:sendme_rider/src/models/rider_order.dart';
import 'package:sendme_rider/src/models/rider_profile.dart';
import 'package:sendme_rider/src/models/user_model.dart';
import 'package:sendme_rider/src/resources/preferences_helper.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

class RiderApiService {
  final http.Client _client;

  RiderApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Safely parse pagination which may come as a Map or a JSON-encoded String.
  Map<String, dynamic>? _parsePagination(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return null;
  }

  Map<String, dynamic> _baseParams() => {
    'deviceId': GlobalConstants.deviceId,
    'deviceType': '${GlobalConstants.deviceType}',
    'version': GlobalConstants.appVersion,
  };

  /// Build auth headers matching the customer app's apiCall pattern.
  Future<Map<String, String>> _authHeaders() async {
    String basicAuth = 'Basic ${base64Encode(utf8.encode('SendMe'))}';
    try {
      final userData = await PreferencesHelper.readStringPref(
        PreferencesHelper.prefRiderData,
      );
      if (userData != null && userData.isNotEmpty) {
        final jsonData = jsonDecode(userData) as Map<String, dynamic>;
        final rest = jsonData['Data'];
        if (rest != null) {
          final u = UserModel.fromJson(rest as Map<String, dynamic>);
          final now = DateTime.now();
          final password = '${u.userId}*${u.userType ?? 0}*${now.minute}';
          basicAuth =
              'Basic ${base64Encode(utf8.encode('${u.mobile}:$password'))}';
        }
      }
    } catch (e) {
      debugPrint('RiderApiService._authHeaders error: $e');
    }
    return {'authorization': basicAuth, 'referer': 'https://sendme.today/'};
  }

  /// Build extra URL params that the customer app's apiCall appends to GET requests.
  Future<String> _extraGetParams() async {
    String phone = '';
    String userName = '';
    int? userId;
    int? cityId;
    try {
      final userData = await PreferencesHelper.readStringPref(
        PreferencesHelper.prefRiderData,
      );
      if (userData != null && userData.isNotEmpty) {
        final jsonData = jsonDecode(userData) as Map<String, dynamic>;
        final rest = jsonData['Data'];
        if (rest != null) {
          final u = UserModel.fromJson(rest as Map<String, dynamic>);
          phone = u.mobile ?? '';
          userName = u.name ?? '';
          userId = u.userId;
          cityId = u.cityId;
        }
      }
    } catch (_) {}
    return '&adminId=$userId'
        '&phoneNumberLogs=$phone'
        '&userNameLogs=${Uri.encodeComponent(userName)}'
        '&cityIdLogs=$cityId'
        '&requestfrom=app'
        '&userLatitude=${GlobalConstants.userAddressLatitude ?? 0.0}'
        '&userLongitude=${GlobalConstants.userAddressLongitude ?? 0.0}'
        '&packageName=${ThemeUI.appPackageName}'
        '&password=${ThemeUI.appPassword}';
  }

  /// Build extra POST params matching the customer app's apiCall pattern.
  Future<Map<String, String>> _extraPostParams() async {
    String phone = '';
    String userName = '';
    int? userId;
    int? cityId;
    try {
      final userData = await PreferencesHelper.readStringPref(
        PreferencesHelper.prefRiderData,
      );
      if (userData != null && userData.isNotEmpty) {
        final jsonData = jsonDecode(userData) as Map<String, dynamic>;
        final rest = jsonData['Data'];
        if (rest != null) {
          final u = UserModel.fromJson(rest as Map<String, dynamic>);
          phone = u.mobile ?? '';
          userName = u.name ?? '';
          userId = u.userId;
          cityId = u.cityId;
        }
      }
    } catch (_) {}
    return {
      'adminId': '$userId',
      'phoneNumberLogs': phone,
      'userNameLogs': userName,
      'cityIdLogs': '$cityId',
      'requestfrom': 'app',
      'userLatitude': '${GlobalConstants.userAddressLatitude ?? 0.0}',
      'userLongitude': '${GlobalConstants.userAddressLongitude ?? 0.0}',
      'packageName': ThemeUI.appPackageName,
      'password': ThemeUI.appPassword,
    };
  }

  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> params,
  ) async {
    try {
      final headers = await _authHeaders();
      headers['Content-Type'] = 'application/json';
      final extraParams = await _extraPostParams();
      final fullParams = {...params, ...extraParams};
      debugPrint('RiderApiService._post url: $url');
      debugPrint('RiderApiService._post params: $fullParams');
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(fullParams),
      );
      debugPrint('RiderApiService._post response body: ${response.body}');
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (data['Status'] == 1) return data;
      throw ApiException(
        data['Message'] as String? ??
            data['errorMessage'] as String? ??
            'Unknown error',
      );
    } on SocketException {
      throw const ApiException('No internet connection');
    } on TimeoutException {
      throw const ApiException('Request timed out');
    }
  }

  Future<Map<String, dynamic>> _get(String url) async {
    try {
      final headers = await _authHeaders();
      final extraParams = await _extraGetParams();
      final fullUrl = '$url$extraParams';
      debugPrint('RiderApiService._get fullUrl: $fullUrl');
      final response = await _client.get(Uri.parse(fullUrl), headers: headers);
      debugPrint('RiderApiService._get response body: ${response.body}');
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (data['Status'] == 1) return data;
      throw ApiException(
        data['Message'] as String? ??
            data['errorMessage'] as String? ??
            'Unknown error',
      );
    } on SocketException {
      throw const ApiException('No internet connection');
    } on TimeoutException {
      throw const ApiException('Request timed out');
    }
  }

  /// Fetch rider profile via SwitchUser API.
  /// The login saves the user (UserId), but the orders API needs the Rider Id.
  /// SwitchUser with userType=Rider returns the actual Rider object.
  Future<RiderProfile> fetchRiderProfile({required String mobile}) async {
    final url =
        '${ApiPath.switchUser}'
        'userType=${GlobalConstants.rider}'
        '&mobileNumber=$mobile'
        '&deviceType=${GlobalConstants.deviceType}'
        '&version=${GlobalConstants.appVersion}'
        '&deviceId=${GlobalConstants.deviceId}';
    debugPrint('RiderApiService.fetchRiderProfile URL: $url');
    final data = await _get(url);
    debugPrint('RiderApiService.fetchRiderProfile response: $data');
    final riderData = data['Data'] as Map<String, dynamic>;
    return RiderProfile.fromJson(riderData);
  }

  /// Fetch rider profile with full API response for force update / blocked checks.
  Future<({RiderProfile profile, Map<String, dynamic> rawResponse})>
  fetchRiderProfileWithMeta({required String mobile}) async {
    final url =
        '${ApiPath.switchUser}'
        'userType=${GlobalConstants.rider}'
        '&mobileNumber=$mobile'
        '&deviceType=${GlobalConstants.deviceType}'
        '&version=${GlobalConstants.appVersion}'
        '&deviceId=${GlobalConstants.deviceId}';
    final data = await _get(url);
    final riderData = data['Data'] as Map<String, dynamic>;
    return (profile: RiderProfile.fromJson(riderData), rawResponse: data);
  }

  Future<
    ({
      List<RiderOrder> orders,
      int totalPages,
      Map<String, dynamic>? pagination,
    })
  >
  getRiderOrders({
    required int riderId,
    required int dateType,
    int pageIndex = 0,
    Map<String, dynamic>? pagination,
  }) async {
    final now = DateFormat('MM/dd/yyyy').format(DateTime.now());
    final params = {
      'pageIndex': '$pageIndex',
      'pagination': jsonEncode(pagination ?? {}),
      'dateType': '$dateType',
      'fromDate': dateType == 0 ? now : '',
      'toDate': dateType == 0 ? now : '',
      'outletId': '0',
      'riderId': '$riderId',
      'isAdmin': '1',
      'userType': '${GlobalConstants.rider}',
      'isRider': '1',
      ..._baseParams(),
    };

    debugPrint('RiderApiService.getRiderOrders params: $params');
    final data = await _post(ApiPath.getOrderList, params);
    debugPrint(
      'RiderApiService.getRiderOrders response Status: ${data['Status']}, TotalPage: ${data['TotalPage']}, Data length: ${(data['Data'] as List?)?.length}',
    );
    final List<dynamic> dataList = data['Data'] as List<dynamic>? ?? [];
    final orders = dataList
        .map((e) => RiderOrder.fromJson(e as Map<String, dynamic>))
        .toList();
    final totalPages = (data['TotalPage'] as num?)?.toInt() ?? 0;
    final paginationCursor = _parsePagination(data['pagination']);

    return (
      orders: orders,
      totalPages: totalPages,
      pagination: paginationCursor,
    );
  }

  Future<RiderOrder> getRiderOrderDetail({
    required int orderId,
    int outletId = 0,
    int riderId = 0,
  }) async {
    final url =
        '${ApiPath.getHotelsOrderDetail}'
        'orderId=$orderId'
        '&outletId=$outletId'
        '&riderId=$riderId'
        '&isAdmin=1'
        '&userType=${GlobalConstants.rider}'
        '&isRider=1'
        '&deviceId=${GlobalConstants.deviceId}'
        '&deviceType=${GlobalConstants.deviceType}'
        '&version=${GlobalConstants.appVersion}';
    final data = await _get(url);
    return RiderOrder.fromJson(data['Data'] as Map<String, dynamic>);
  }

  Future<bool> updateOrderStatus({
    required int orderId,
    required int newStatus,
    required int riderId,
  }) async {
    final url =
        '${ApiPath.orderStatusUpdates}'
        'userId=$riderId'
        '&orderId=$orderId'
        '&userType=${GlobalConstants.rider}'
        '&orderStatus=$newStatus'
        '&actionType=1'
        '&deviceId=${GlobalConstants.deviceId}'
        '&deviceType=${GlobalConstants.deviceType}'
        '&version=${GlobalConstants.appVersion}';
    await _get(url);
    return true;
  }

  Future<bool> updateRiderAvailability({
    required RiderProfile rider,
    required int status,
  }) async {
    final params = {
      'id': '${rider.id}',
      'name': rider.name,
      'email': rider.email,
      'contact': rider.contact,
      'latitude': '${rider.latitude}',
      'longitude': '${rider.longitude}',
      'status': '$status',
      'isUpdateFromRiderApp': '1',
      'userType': '${GlobalConstants.rider}',
      ..._baseParams(),
    };
    await _post(ApiPath.updateRider, params);
    return true;
  }

  Future<List<Map<String, dynamic>>> getRiderReportSummary({
    required int riderId,
    required String fromDate,
    required String toDate,
    required int paymentMode,
  }) async {
    final url =
        '${ApiPath.getTotalBillAmountForReports}'
        'paymentMode=$paymentMode'
        '&fromDate=$fromDate'
        '&toDate=$toDate'
        '&outletId=0'
        '&riderId=$riderId'
        '&deliveryType=0'
        '&deliveryManageByType=0'
        '&pageIndex=0'
        '&userType=${GlobalConstants.rider}'
        '&isAdmin=1';
    final data = await _get(url);
    final list = data['Data'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<({List<Map<String, dynamic>> entries, int totalPages})>
  getRiderReport({
    required int riderId,
    required String fromDate,
    required String toDate,
    required int paymentMode,
    int pageIndex = 0,
  }) async {
    final url =
        '${ApiPath.getReports}'
        'paymentMode=$paymentMode'
        '&fromDate=$fromDate'
        '&toDate=$toDate'
        '&outletId=0'
        '&riderId=$riderId'
        '&deliveryType=0'
        '&deliveryManageByType=0'
        '&pageIndex=$pageIndex'
        '&userType=${GlobalConstants.rider}'
        '&isAdmin=1';
    final data = await _get(url);
    final list = data['Data'] as List<dynamic>? ?? [];
    final totalPages = (data['TotalPage'] as num?)?.toInt() ?? 0;
    return (entries: list.cast<Map<String, dynamic>>(), totalPages: totalPages);
  }

  Future<
    ({
      List<Review> reviews,
      Map<String, dynamic>? pagination,
      double averageRating,
    })
  >
  getRiderReviews({
    required int riderId,
    Map<String, dynamic>? pagination,
  }) async {
    final params = {
      'riderId': '$riderId',
      'pagination': jsonEncode(pagination ?? {}),
      'userType': '${GlobalConstants.rider}',
      ..._baseParams(),
    };
    final data = await _post(ApiPath.getRatingsAndReviewsForRider, params);
    final list = data['Data'] as List<dynamic>? ?? [];
    final reviews = list
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
    final paginationCursor = _parsePagination(data['pagination']);
    final averageRating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
    return (
      reviews: reviews,
      pagination: paginationCursor,
      averageRating: averageRating,
    );
  }

  /// Upload bill image for an order.
  Future<String> uploadBill({
    required int orderId,
    required XFile imageFile,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final params = {
      'bucket': GlobalConstants.bucket,
      'imageURL': 'data:image/jpeg;base64,$base64Image',
      'OrderId': '$orderId',
      'userType': '${GlobalConstants.rider}',
      ..._baseParams(),
    };
    final data = await _post(ApiPath.uploadBill, params);
    return data['Message'] as String? ?? 'Bill uploaded';
  }

  /// Upload QR payment proof image for an order.
  Future<String> uploadQRPayment({
    required int orderId,
    required XFile imageFile,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final params = {
      'bucket': GlobalConstants.bucket,
      'imageURL': 'data:image/jpeg;base64,$base64Image',
      'OrderId': '$orderId',
      ..._baseParams(),
    };
    final data = await _post(ApiPath.uploadQRPayment, params);
    return data['Message'] as String? ?? 'Payment proof uploaded';
  }

  /// Get dynamic QR code for an order.
  Future<String> getDynamicQR({
    required int orderId,
    required int riderId,
  }) async {
    final params = {
      'OrderId': '$orderId',
      'riderId': '$riderId',
      ..._baseParams(),
    };
    final data = await _post(ApiPath.getDynamicQR, params);
    return data['QRString'] as String? ?? '';
  }

  /// Fire-and-forget authenticated GET request
  Future<void> fireAndForgetGet({required String url}) async {
    try {
      final headers = await _authHeaders();
      final extraParams = await _extraGetParams();
      final fullUrl = '$url$extraParams';
      debugPrint('RiderApiService.fireAndForgetGet: $fullUrl');
      final response = await _client.get(Uri.parse(fullUrl), headers: headers);
      debugPrint('RiderApiService.fireAndForgetGet -> ${response.statusCode}');
    } catch (e) {
      debugPrint('RiderApiService.fireAndForgetGet error: $e');
    }
  }

  /// Register device token for push notifications.
  Future<void> registerDeviceToken({required String url}) async {
    await _get(url);
  }
}
