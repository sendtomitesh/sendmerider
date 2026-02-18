/// Represents a single item in an order (from orderDetail JSON array).
class OrderDetailItem {
  final String name;
  final String subItemName;
  final int qty;
  final double price;
  final double totalAmount;

  const OrderDetailItem({
    this.name = '',
    this.subItemName = '',
    this.qty = 0,
    this.price = 0.0,
    this.totalAmount = 0.0,
  });

  factory OrderDetailItem.fromJson(Map<String, dynamic> json) {
    return OrderDetailItem(
      name: _str(json['name']),
      subItemName: _str(json['subItemName']),
      qty: _int(json['qty']),
      price: _dbl(json['price']),
      totalAmount: _dbl(json['totalAmount']),
    );
  }

  static String _str(dynamic v) => v?.toString() ?? '';
  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _dbl(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

/// Represents a grocery item in an order.
class GroceryItem {
  final String itemName;
  final String qty;
  final String unit;
  final double price;

  const GroceryItem({
    this.itemName = '',
    this.qty = '',
    this.unit = '',
    this.price = 0.0,
  });

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      itemName: json['itemName']?.toString() ?? '',
      qty: json['qty']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      price: OrderDetailItem._dbl(json['price']),
    );
  }
}

/// Represents an offer applied to an order.
class OfferDetail {
  final String title;
  final int offerType;
  final double mainDiscountAmount;
  final String itemFree;

  const OfferDetail({
    this.title = '',
    this.offerType = 0,
    this.mainDiscountAmount = 0.0,
    this.itemFree = '',
  });

  factory OfferDetail.fromJson(Map<String, dynamic> json) {
    return OfferDetail(
      title: json['title']?.toString() ?? '',
      offerType: OrderDetailItem._int(json['offerType']),
      mainDiscountAmount: OrderDetailItem._dbl(json['mainDiscountAmount']),
      itemFree: json['itemFree']?.toString() ?? '',
    );
  }
}

/// Represents an address (delivery address, pickup address, drop address).
class OrderAddress {
  final String address;
  final String landMark;
  final String? floor;
  final String userName;
  final String userContact;
  final double latitude;
  final double longitude;

  const OrderAddress({
    this.address = '',
    this.landMark = '',
    this.floor,
    this.userName = '',
    this.userContact = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      address: json['Address']?.toString() ?? json['address']?.toString() ?? '',
      landMark:
          json['LandMark']?.toString() ?? json['landMark']?.toString() ?? '',
      floor: json['Floor']?.toString() ?? json['floor']?.toString(),
      userName: json['userName']?.toString() ?? '',
      userContact: json['userContact']?.toString() ?? '',
      latitude: OrderDetailItem._dbl(json['Latitude'] ?? json['latitude']),
      longitude: OrderDetailItem._dbl(json['Longitude'] ?? json['longitude']),
    );
  }
}
