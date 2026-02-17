class RiderOrder {
  final int orderId;
  final int orderStatus;
  final int paymentMode;
  final String paymentType;
  final String hotelName;
  final int hotelId;
  final String hotelAddress;
  final String userName;
  final String userArea;
  final String contactNo;
  final String mobile;
  final String orderOn;
  final String deliveryOn;
  final String deliveredAt;
  final double totalBill;
  final double deliveryCharge;
  final String currency;
  final int riderId;
  final String riderName;
  final int isPickUpAndDropOrder;
  final int deliveryType;
  final double outletLatitude;
  final double outletLongitude;
  final double userLatitude;
  final double userLongitude;
  final String slot;
  final String remarks;
  final int isRiderGoing;

  const RiderOrder({
    this.orderId = 0,
    this.orderStatus = 0,
    this.paymentMode = 0,
    this.paymentType = '',
    this.hotelName = '',
    this.hotelId = 0,
    this.hotelAddress = '',
    this.userName = '',
    this.userArea = '',
    this.contactNo = '',
    this.mobile = '',
    this.orderOn = '',
    this.deliveryOn = '',
    this.deliveredAt = '',
    this.totalBill = 0.0,
    this.deliveryCharge = 0.0,
    this.currency = '',
    this.riderId = 0,
    this.riderName = '',
    this.isPickUpAndDropOrder = 0,
    this.deliveryType = 0,
    this.outletLatitude = 0.0,
    this.outletLongitude = 0.0,
    this.userLatitude = 0.0,
    this.userLongitude = 0.0,
    this.slot = '',
    this.remarks = '',
    this.isRiderGoing = 0,
  });

  factory RiderOrder.fromJson(Map<String, dynamic> json) {
    return RiderOrder(
      orderId: _parseInt(json['orderId']) ?? 0,
      orderStatus: _parseInt(json['orderStatus']) ?? 0,
      paymentMode: _parseInt(json['paymentMode']) ?? 0,
      paymentType: _parseString(json['paymentType']),
      hotelName: _parseString(json['hotelName']),
      hotelId: _parseInt(json['hotelId']) ?? 0,
      hotelAddress: _parseString(json['hotelAddress']),
      userName: _parseString(json['userName']),
      userArea: _parseString(json['userArea']),
      contactNo: _parseString(json['ContactNo']),
      mobile: _parseString(json['mobile']),
      orderOn: _parseString(json['orderOn']),
      deliveryOn: _parseString(json['deliveryOn']),
      deliveredAt: _parseString(json['orderDeliveredDate']),
      totalBill: _parseDouble(json['totalBill']) ?? 0.0,
      deliveryCharge:
          _parseDouble(json['deliveryCharge'] ?? json['DeliveryCharge']) ?? 0.0,
      currency: _parseString(json['currency']),
      riderId: _parseInt(json['riderId']) ?? 0,
      riderName: _parseString(json['riderName']),
      isPickUpAndDropOrder: _parseInt(json['isPickUpAndDropOrder']) ?? 0,
      deliveryType: _parseInt(json['deliveryType']) ?? 0,
      outletLatitude: _parseDouble(json['outletLatitude']) ?? 0.0,
      outletLongitude: _parseDouble(json['outletLongitude']) ?? 0.0,
      userLatitude: _parseDouble(json['userLatitude']) ?? 0.0,
      userLongitude: _parseDouble(json['userLongitude']) ?? 0.0,
      slot: _parseString(json['Slot'] ?? json['slot']),
      remarks: _parseString(json['remarks']),
      isRiderGoing: _parseInt(json['isRiderGoing']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'orderStatus': orderStatus,
      'paymentMode': paymentMode,
      'paymentType': paymentType,
      'hotelName': hotelName,
      'hotelId': hotelId,
      'hotelAddress': hotelAddress,
      'userName': userName,
      'userArea': userArea,
      'ContactNo': contactNo,
      'mobile': mobile,
      'orderOn': orderOn,
      'deliveryOn': deliveryOn,
      'orderDeliveredDate': deliveredAt,
      'totalBill': totalBill,
      'deliveryCharge': deliveryCharge,
      'currency': currency,
      'riderId': riderId,
      'riderName': riderName,
      'isPickUpAndDropOrder': isPickUpAndDropOrder,
      'deliveryType': deliveryType,
      'outletLatitude': outletLatitude,
      'outletLongitude': outletLongitude,
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
      'Slot': slot,
      'remarks': remarks,
      'isRiderGoing': isRiderGoing,
    };
  }

  RiderOrder copyWith({
    int? orderId,
    int? orderStatus,
    int? paymentMode,
    String? paymentType,
    String? hotelName,
    int? hotelId,
    String? hotelAddress,
    String? userName,
    String? userArea,
    String? contactNo,
    String? mobile,
    String? orderOn,
    String? deliveryOn,
    String? deliveredAt,
    double? totalBill,
    double? deliveryCharge,
    String? currency,
    int? riderId,
    String? riderName,
    int? isPickUpAndDropOrder,
    int? deliveryType,
    double? outletLatitude,
    double? outletLongitude,
    double? userLatitude,
    double? userLongitude,
    String? slot,
    String? remarks,
    int? isRiderGoing,
  }) {
    return RiderOrder(
      orderId: orderId ?? this.orderId,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentMode: paymentMode ?? this.paymentMode,
      paymentType: paymentType ?? this.paymentType,
      hotelName: hotelName ?? this.hotelName,
      hotelId: hotelId ?? this.hotelId,
      hotelAddress: hotelAddress ?? this.hotelAddress,
      userName: userName ?? this.userName,
      userArea: userArea ?? this.userArea,
      contactNo: contactNo ?? this.contactNo,
      mobile: mobile ?? this.mobile,
      orderOn: orderOn ?? this.orderOn,
      deliveryOn: deliveryOn ?? this.deliveryOn,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      totalBill: totalBill ?? this.totalBill,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      currency: currency ?? this.currency,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      isPickUpAndDropOrder: isPickUpAndDropOrder ?? this.isPickUpAndDropOrder,
      deliveryType: deliveryType ?? this.deliveryType,
      outletLatitude: outletLatitude ?? this.outletLatitude,
      outletLongitude: outletLongitude ?? this.outletLongitude,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      slot: slot ?? this.slot,
      remarks: remarks ?? this.remarks,
      isRiderGoing: isRiderGoing ?? this.isRiderGoing,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }
}
