class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.clientId,
    this.orderId,
    this.gasRequestId,
    this.hanoutId,
    this.livreurId,
    this.hanoutRating,
    this.hanoutComment,
    this.livreurRating,
    this.livreurComment,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clientId;
  final String? orderId;
  final String? gasRequestId;
  final String? hanoutId;
  final String? livreurId;
  final int? hanoutRating;
  final String? hanoutComment;
  final int? livreurRating;
  final String? livreurComment;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final legacyRating = json['rating'] as int?;
    final legacyComment = json['comment'] as String?;
    return ReviewModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      orderId: json['orderId'] as String?,
      gasRequestId: json['gasRequestId'] as String?,
      hanoutId: json['hanoutId'] as String?,
      livreurId: json['livreurId'] as String?,
      hanoutRating: (json['hanoutRating'] as int?) ?? legacyRating,
      hanoutComment: (json['hanoutComment'] as String?) ?? legacyComment,
      livreurRating: json['livreurRating'] as int?,
      livreurComment: json['livreurComment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
