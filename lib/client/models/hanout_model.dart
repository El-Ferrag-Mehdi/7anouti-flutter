/// Model representant un Hanout (epicerie de quartier)
class HanoutModel {
  final String id;
  final String name;
  final String? description;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String? image;
  final bool isOpen;
  final bool showRating;
  final bool hasCarnet;
  final double? deliveryFee;
  final int? estimatedDeliveryTime;
  final double? rating;
  final int? totalOrders;
  final String ownerId;
  final DateTime createdAt;

  const HanoutModel({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.image,
    required this.isOpen,
    this.showRating = true,
    required this.hasCarnet,
    this.deliveryFee,
    this.estimatedDeliveryTime,
    this.rating,
    this.totalOrders,
    required this.ownerId,
    required this.createdAt,
  });

  factory HanoutModel.fromJson(Map<String, dynamic> json) {
    final latitudeValue = json['latitude'];
    final longitudeValue = json['longitude'];
    final deliveryFeeValue = json['deliveryFee'];
    final ratingValue = json['rating'];
    return HanoutModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String,
      latitude: (latitudeValue as num).toDouble(),
      longitude: (longitudeValue as num).toDouble(),
      phone: json['phone'] as String,
      image: json['image'] as String?,
      isOpen: json['isOpen'] as bool? ?? true,
      showRating: json['showRating'] as bool? ?? true,
      hasCarnet: json['hasCarnet'] as bool? ?? false,
      deliveryFee: deliveryFeeValue == null
          ? null
          : (deliveryFeeValue as num).toDouble(),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] as int?,
      rating: ratingValue == null ? null : (ratingValue as num).toDouble(),
      totalOrders: json['totalOrders'] as int?,
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'image': image,
      'isOpen': isOpen,
      'showRating': showRating,
      'hasCarnet': hasCarnet,
      'deliveryFee': deliveryFee,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'rating': rating,
      'totalOrders': totalOrders,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  HanoutModel copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? image,
    bool? isOpen,
    bool? showRating,
    bool? hasCarnet,
    double? deliveryFee,
    int? estimatedDeliveryTime,
    double? rating,
    int? totalOrders,
    String? ownerId,
    DateTime? createdAt,
  }) {
    return HanoutModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      isOpen: isOpen ?? this.isOpen,
      showRating: showRating ?? this.showRating,
      hasCarnet: hasCarnet ?? this.hasCarnet,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      rating: rating ?? this.rating,
      totalOrders: totalOrders ?? this.totalOrders,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Model pour Hanout avec distance calculee (pour la liste)
class HanoutWithDistance extends HanoutModel {
  final double distanceInMeters;

  const HanoutWithDistance({
    required super.id,
    required super.name,
    super.description,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.phone,
    super.image,
    required super.isOpen,
    super.showRating = true,
    required super.hasCarnet,
    super.deliveryFee,
    super.estimatedDeliveryTime,
    super.rating,
    super.totalOrders,
    required super.ownerId,
    required super.createdAt,
    required this.distanceInMeters,
  });

  String get formattedDistance {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toInt()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  factory HanoutWithDistance.fromHanout(
    HanoutModel hanout,
    double distance,
  ) {
    return HanoutWithDistance(
      id: hanout.id,
      name: hanout.name,
      description: hanout.description,
      address: hanout.address,
      latitude: hanout.latitude,
      longitude: hanout.longitude,
      phone: hanout.phone,
      image: hanout.image,
      isOpen: hanout.isOpen,
      showRating: hanout.showRating,
      hasCarnet: hanout.hasCarnet,
      deliveryFee: hanout.deliveryFee,
      estimatedDeliveryTime: hanout.estimatedDeliveryTime,
      rating: hanout.rating,
      totalOrders: hanout.totalOrders,
      ownerId: hanout.ownerId,
      createdAt: hanout.createdAt,
      distanceInMeters: distance,
    );
  }
}
