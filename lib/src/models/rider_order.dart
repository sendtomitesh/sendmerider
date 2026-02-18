import 'package:sendme_rider/src/models/order_detail_item.dart';

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

  // Additional fields for detail view
  final double totalAmountForHotel;
  final double payableToHotel;
  final double additionalCharges;
  final double netBill;
  final double cGST;
  final double sGST;
  final double itemTotal;
  final int taxType;
  final int qrPaymentStatus;
  final String qrImage;
  final String prescriptionImage;
  final String outletCity;
  final String outletAddress2;
  final String changeForCash;
  final List<OrderDetailItem>? orderDetail;
  final List<GroceryItem>? groceryItems;
  final List<String>? packageContent;
  final List<OfferDetail>? offers;
  final OrderAddress? address;
  final OrderAddress? pickUpAddress;
  final OrderAddress? dropAddress;
  final List<String>? prescriptionImageList;

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
    this.totalAmountForHotel = 0.0,
    this.payableToHotel = 0.0,
    this.additionalCharges = 0.0,
    this.netBill = 0.0,
    this.cGST = 0.0,
    this.sGST = 0.0,
    this.itemTotal = 0.0,
    this.taxType = 0,
    this.qrPaymentStatus = 0,
    this.qrImage = '',
    this.prescriptionImage = '',
    this.outletCity = '',
    this.outletAddress2 = '',
    this.changeForCash = '',
    this.orderDetail,
    this.groceryItems,
    this.packageContent,
    this.offers,
    this.address,
    this.pickUpAddress,
    this.dropAddress,
    this.prescriptionImageList,
  });

  factory RiderOrder.fromJson(Map<String, dynamic> json) {
    // Parse orderDetail list
    List<OrderDetailItem>? orderDetailList;
    if (json['orderDetail'] != null) {
      orderDetailList = (json['orderDetail'] as List)
          .map((e) => OrderDetailItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse groceryItems list
    List<GroceryItem>? groceryItemsList;
    if (json['GroceryItemDetail'] != null) {
      groceryItemsList = (json['GroceryItemDetail'] as List)
          .map((e) => GroceryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse packageContent
    List<String>? packageContentList;
    if (json['packageContent'] != null) {
      packageContentList = (json['packageContent'] as List).cast<String>();
    }

    // Parse offers
    List<OfferDetail>? offersList;
    if (json['Offers'] != null) {
      offersList = (json['Offers'] as List)
          .map((e) => OfferDetail.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse prescription image list
    List<String>? prescriptionImageListParsed;
    if (json['prescription_imageList'] != null) {
      prescriptionImageListParsed = (json['prescription_imageList'] as List)
          .cast<String>();
    }

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
      totalAmountForHotel: _parseDouble(json['totalAmountForHotel']) ?? 0.0,
      payableToHotel: _parseDouble(json['payableToHotel']) ?? 0.0,
      additionalCharges: _parseDouble(json['additionalCharges']) ?? 0.0,
      netBill: _parseDouble(json['NetBill']) ?? 0.0,
      cGST: _parseDouble(json['CGST']) ?? 0.0,
      sGST: _parseDouble(json['SGST']) ?? 0.0,
      itemTotal: _parseDouble(json['itemTotal']) ?? 0.0,
      taxType: _parseInt(json['TaxType']) ?? 0,
      qrPaymentStatus: _parseInt(json['QRPaymentStatus']) ?? 0,
      qrImage: _parseString(json['QRImage']),
      prescriptionImage: _parseString(json['prescription_image']),
      outletCity: _parseString(json['outletCity']),
      outletAddress2: _parseString(json['outletAddress']),
      changeForCash: _parseString(json['changesForCash']),
      orderDetail: orderDetailList,
      groceryItems: groceryItemsList,
      packageContent: packageContentList,
      offers: offersList,
      address: json['Address'] != null
          ? OrderAddress.fromJson(json['Address'] as Map<String, dynamic>)
          : null,
      pickUpAddress: json['pickUpAddress'] != null
          ? OrderAddress.fromJson(json['pickUpAddress'] as Map<String, dynamic>)
          : null,
      dropAddress: json['dropAddress'] != null
          ? OrderAddress.fromJson(json['dropAddress'] as Map<String, dynamic>)
          : null,
      prescriptionImageList: prescriptionImageListParsed,
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
    double? totalAmountForHotel,
    double? additionalCharges,
    String? qrImage,
    List<OrderDetailItem>? orderDetail,
    List<GroceryItem>? groceryItems,
    List<String>? packageContent,
    List<OfferDetail>? offers,
    OrderAddress? address,
    OrderAddress? pickUpAddress,
    OrderAddress? dropAddress,
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
      totalAmountForHotel: totalAmountForHotel ?? this.totalAmountForHotel,
      payableToHotel: this.payableToHotel,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      netBill: this.netBill,
      cGST: this.cGST,
      sGST: this.sGST,
      itemTotal: this.itemTotal,
      taxType: this.taxType,
      qrPaymentStatus: this.qrPaymentStatus,
      qrImage: qrImage ?? this.qrImage,
      prescriptionImage: this.prescriptionImage,
      outletCity: this.outletCity,
      outletAddress2: this.outletAddress2,
      changeForCash: this.changeForCash,
      orderDetail: orderDetail ?? this.orderDetail,
      groceryItems: groceryItems ?? this.groceryItems,
      packageContent: packageContent ?? this.packageContent,
      offers: offers ?? this.offers,
      address: address ?? this.address,
      pickUpAddress: pickUpAddress ?? this.pickUpAddress,
      dropAddress: dropAddress ?? this.dropAddress,
      prescriptionImageList: this.prescriptionImageList,
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
