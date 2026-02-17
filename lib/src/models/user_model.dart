class UserModel {
  final int? userId;
  final String? name;
  final String? mobile;
  final String? email;
  final int? userType;
  final int? cityId;
  final double? latitude;
  final double? longitude;

  UserModel({
    this.userId,
    this.name,
    this.mobile,
    this.email,
    this.userType,
    this.cityId,
    this.latitude,
    this.longitude,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: _parseInt(json['UserId']),
      name: _parseString(json['Name']),
      mobile: _parseString(json['userMobile'] ?? json['Mobile']),
      email: _parseString(json['email']),
      userType: _parseInt(json['userType']),
      cityId: _parseInt(json['cityId']),
      latitude: _parseDouble(json['Latitude']) ?? 0.0,
      longitude: _parseDouble(json['Longitude']) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'Name': name,
      'userMobile': mobile,
      'email': email,
      'userType': userType,
      'cityId': cityId,
      'Latitude': latitude,
      'Longitude': longitude,
    };
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

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }
}
