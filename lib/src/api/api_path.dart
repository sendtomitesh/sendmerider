import 'package:sendme_rider/src/controllers/theme_ui.dart';

class ApiPath {
  static const String slsServerPath = 'https://sls.sendme.today/';

  ///###################################---- Static Links ----###################################///

  static const String imageURL =
      'https://s3.ap-south-1.amazonaws.com/sendme-images/Images/';
  static const String googleMaps = 'https://www.google.com/maps/search';
  static const String paymentServerPath = 'sendme.today';

  static String get termsAndConditions => ThemeUI.termsAndConditionsLink;
  static String get privacyPolicy => ThemeUI.privacyPolicyLink;
  static String get whatsappLink => ThemeUI.whatsappLink;

  ///###################################---- Common APIs ----###################################///

  static final String saveOTP = '${slsServerPath}SaveOTP?';
  static final String sendOTP = '${slsServerPath}SendOTP?';
  static final String verifyOTP = '${slsServerPath}verifyOTP?';
  static final String userRegistration = '${slsServerPath}userRegistration';
  static final String getCountryList = '${slsServerPath}getcountrylist?';
  static final String getCityList = '${slsServerPath}getcitylist?';
  static final String updateUserToken = '${slsServerPath}UpdateUserToken?';
  static final String switchUser = '${slsServerPath}SwitchUser?';
  static final String uploadToS3 = '${slsServerPath}UploadToS3';
  static final String getAppConfiguration =
      '${slsServerPath}GetAppConfiguration';
  static final String findLocation = '${slsServerPath}findLocation';

  ///###################################---- Rider APIs ----###################################///

  static final String saveRiderLocation = '${slsServerPath}saveriderlocation?';
  static final String updateRider = '${slsServerPath}UpdateRider';
  static final String getRatingsAndReviewsForRider =
      '${slsServerPath}GetRatingsAndReviewsForRider';
  static final String getGeoPointByRiderId =
      '${slsServerPath}GetGeoPointByRiderId?';
  static final String getCustomerInfo = '${slsServerPath}getcustomerinfo?';
  static final String uploadBill = '${slsServerPath}UploadBill';
  static final String uploadQRPayment = '${slsServerPath}UploadQRPayment';
  static final String getDynamicQR = '${slsServerPath}GetDynamicQR';
  static final String getOrderList = '${slsServerPath}GetOrderList';
  static final String getHotelsOrderDetail =
      '${slsServerPath}GetHotelsOrderDetail?';
  static final String orderStatusUpdates =
      '${slsServerPath}OrderStatusUpdates?';
  static final String getRiderEarnings = '${slsServerPath}GetRiderEarnings';
  static final String getRiderProfile = '${slsServerPath}GetRiderProfile';
  static final String getReports = '${slsServerPath}GetReports?';
  static final String getTotalBillAmountForReports =
      '${slsServerPath}GetTotalBillAmountForReport?';
}
