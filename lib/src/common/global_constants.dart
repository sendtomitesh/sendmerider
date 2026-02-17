import 'dart:async';

class GlobalConstants {
  // Firebase
  static String? firebaseToken = '';

  // Device info
  static String appVersion = '';
  static String deviceId = '';
  static int? deviceType;

  // App state
  static bool isLiveApp = true;

  // User address / location
  static double? userAddressLatitude = 0.0;
  static double? userAddressLongitude = 0.0;

  // Force update
  static int forceUpdate = 1;
  static bool? isForceUpdate = false;
  static String? liveAppVersion = '';
  static String packageName = '';

  // Notification
  static StreamController<String> streamController =
      StreamController.broadcast();
  static int notificationCount = 1;

  // Order statuses
  static const int orderPending = 1;
  static const int userCancelled = 2;
  static const int hotelCancelled = 3;
  static const int adminCancelled = 3;
  static const int sendmeCancelled = 4;
  static const int hotelAccepted = 5;
  static const int adminAccepted = 5;
  static const int sendmeAccepted = 6;
  static const int orderPicked = 7;
  static const int orderDelivered = 8;
  static const int riderGoing = 9;
  static const int riderNotAssign = 10;
  static const int orderPrepared = 11;
  static const int orderUndelivered = -8;
  static const int testOrder = -1;
  static const int pickupAndDrop = -2;
  static const int noteOrder = -3;

  // Delivery types
  static const int homeDelivery = 1;
  static const int takeAway = 2;
  static const int bothDeliveryType = 0;

  // Payment modes
  static const int cash = 1;
  static const int onlinePayment = 2;
  static const int directTransfer = 3;

  // User types
  static const int customer = 0;
  static const int outlet = 1;
  static const int rider = 2;
  static const int cityManager = 3;
  static const int countryFranchiser = 4;
  static const int deliveryPartner = 5;
  static const int superAdmin = 7;

  // Google Maps
  static const String googleMapKey = 'AIzaSyAE8GmmdV5IqCzdKOhok_eZX6AvHR-7L14';

  // Image bucket
  static const String bucket = 'sendme-images';
}
