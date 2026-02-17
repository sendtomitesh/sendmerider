class Review {
  final int id;
  final int userId;
  final int hotelId;
  final double rating;
  final String userName;
  final String comment;
  final String reply;
  final String dateTime;

  const Review({
    this.id = 0,
    this.userId = 0,
    this.hotelId = 0,
    this.rating = 0.0,
    this.userName = '',
    this.comment = '',
    this.reply = '',
    this.dateTime = '',
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: _parseInt(json['Id']) ?? 0,
      userId: _parseInt(json['userId']) ?? 0,
      hotelId: _parseInt(json['hotelId']) ?? 0,
      rating: _parseDouble(json['rating']) ?? 0.0,
      userName: _parseString(json['userName']),
      comment: _parseString(json['comment']),
      reply: _parseString(json['reply']),
      dateTime: _parseString(json['dateTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'userId': userId,
      'hotelId': hotelId,
      'rating': rating,
      'userName': userName,
      'comment': comment,
      'reply': reply,
      'dateTime': dateTime,
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

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }
}
