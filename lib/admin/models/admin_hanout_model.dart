class AdminHanoutModel {
  const AdminHanoutModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.deliveryFee,
    required this.isOpen,
    required this.showRating,
    this.rating,
    this.ownerId,
    this.ownerName,
    this.ownerPhone,
    this.ownerIsActive,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final double? deliveryFee;
  final bool isOpen;
  final bool showRating;
  final double? rating;
  final String? ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final bool? ownerIsActive;

  factory AdminHanoutModel.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    return AdminHanoutModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      deliveryFee: json['deliveryFee'] == null
          ? null
          : (json['deliveryFee'] as num).toDouble(),
      isOpen: json['isOpen'] as bool? ?? true,
      showRating: json['showRating'] as bool? ?? true,
      rating: json['rating'] == null
          ? null
          : (json['rating'] as num).toDouble(),
      ownerId: owner?['id'] as String?,
      ownerName: owner?['name'] as String?,
      ownerPhone: owner?['phone'] as String?,
      ownerIsActive: owner?['isActive'] as bool?,
    );
  }

  AdminHanoutModel copyWith({
    bool? showRating,
    double? rating,
    double? deliveryFee,
  }) {
    return AdminHanoutModel(
      id: id,
      name: name,
      address: address,
      phone: phone,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      isOpen: isOpen,
      showRating: showRating ?? this.showRating,
      rating: rating ?? this.rating,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      ownerIsActive: ownerIsActive,
    );
  }
}
