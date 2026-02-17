class RiderProfile {
  final int id;
  final String name;
  final String email;
  final String contact;
  final int status; // 0=available, 1=unavailable
  final double latitude;
  final double longitude;
  final String imageUrl;
  final double averageRatings;

  const RiderProfile({
    this.id = 0,
    this.name = '',
    this.email = '',
    this.contact = '',
    this.status = 0,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.imageUrl = '',
    this.averageRatings = 0.0,
  });

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    return RiderProfile(
      id: _parseInt(json['Id']) ?? 0,
      name: _parseString(json['Name']),
      email: _parseString(json['Email']),
      contact: _parseString(json['Contact']),
      status: _parseInt(json['Status']) ?? 0,
      latitude: _parseDouble(json['Latitude']) ?? 0.0,
      longitude: _parseDouble(json['Longitude']) ?? 0.0,
      imageUrl: _parseString(json['imageUrl']),
      averageRatings: _parseDouble(json['averageRatings']) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Email': email,
      'Contact': contact,
      'Status': status,
      'Latitude': latitude,
      'Longitude': longitude,
      'imageUrl': imageUrl,
      'averageRatings': averageRatings,
    };
  }

  RiderProfile copyWith({
    int? id,
    String? name,
    String? email,
    String? contact,
    int? status,
    double? latitude,
    double? longitude,
    String? imageUrl,
    double? averageRatings,
  }) {
    return RiderProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      contact: contact ?? this.contact,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      averageRatings: averageRatings ?? this.averageRatings,
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
