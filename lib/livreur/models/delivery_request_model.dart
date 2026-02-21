import 'package:sevenouti/client/models/order_model.dart';

class LivreurDeliveryOrderInfo {
  const LivreurDeliveryOrderInfo({
    required this.id,
    required this.freeTextOrder,
    required this.status,
    required this.deliveryType,
    this.clientAddress,
    this.clientAddressFr,
    this.clientAddressAr,
    this.clientLatitude,
    this.clientLongitude,
    this.notes,
  });

  final String id;
  final String freeTextOrder;
  final OrderStatus status;
  final DeliveryType deliveryType;
  final String? clientAddress;
  final String? clientAddressFr;
  final String? clientAddressAr;
  final double? clientLatitude;
  final double? clientLongitude;
  final String? notes;

  factory LivreurDeliveryOrderInfo.fromJson(Map<String, dynamic> json) {
    return LivreurDeliveryOrderInfo(
      id: json['id'] as String,
      freeTextOrder: json['freeTextOrder'] as String,
      status: OrderStatus.fromString(json['status'] as String),
      deliveryType: DeliveryType.fromString(json['deliveryType'] as String),
      clientAddress: json['clientAddress'] as String?,
      clientAddressFr: json['clientAddressFr'] as String?,
      clientAddressAr: json['clientAddressAr'] as String?,
      clientLatitude: json['clientLatitude'] != null
          ? (json['clientLatitude'] as num).toDouble()
          : null,
      clientLongitude: json['clientLongitude'] != null
          ? (json['clientLongitude'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
    );
  }

  String? displayClientAddress({required bool preferArabic}) {
    if (preferArabic) {
      final arabic = clientAddressAr?.trim();
      if (arabic != null && arabic.isNotEmpty) return arabic;
    }
    final french = clientAddressFr?.trim();
    if (french != null && french.isNotEmpty) return french;
    final fallback = clientAddress?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }
}

class LivreurHanoutInfo {
  const LivreurHanoutInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final double? latitude;
  final double? longitude;

  factory LivreurHanoutInfo.fromJson(Map<String, dynamic> json) {
    return LivreurHanoutInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }
}

class LivreurDeliveryRequestModel {
  const LivreurDeliveryRequestModel({
    required this.id,
    required this.status,
    required this.orderId,
    required this.hanoutId,
    required this.createdAt,
    this.order,
    this.hanout,
    this.distance,
  });

  final String id;
  final String status;
  final String orderId;
  final String hanoutId;
  final DateTime createdAt;
  final LivreurDeliveryOrderInfo? order;
  final LivreurHanoutInfo? hanout;
  final double? distance;

  factory LivreurDeliveryRequestModel.fromJson(Map<String, dynamic> json) {
    return LivreurDeliveryRequestModel(
      id: json['id'] as String,
      status: json['status'] as String,
      orderId: json['orderId'] as String,
      hanoutId: json['hanoutId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      order: json['order'] != null
          ? LivreurDeliveryOrderInfo.fromJson(
              json['order'] as Map<String, dynamic>,
            )
          : null,
      hanout: json['hanout'] != null
          ? LivreurHanoutInfo.fromJson(
              json['hanout'] as Map<String, dynamic>,
            )
          : null,
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
    );
  }
}
