import 'package:sevenouti/client/models/order_model.dart';

class LivreurDeliveryClientInfo {
  const LivreurDeliveryClientInfo({
    required this.id,
    required this.name,
    required this.nameFr,
    this.nameAr,
    required this.phone,
    this.address,
  });

  final String id;
  final String name;
  final String nameFr;
  final String? nameAr;
  final String phone;
  final String? address;

  factory LivreurDeliveryClientInfo.fromJson(Map<String, dynamic> json) {
    return LivreurDeliveryClientInfo(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? (json['nameFr'] as String? ?? ''),
      nameFr: (json['nameFr'] as String?) ?? (json['name'] as String? ?? ''),
      nameAr: json['nameAr'] as String?,
      phone: json['phone'] as String,
      address: json['address'] as String?,
    );
  }

  String displayName({required bool preferArabic}) {
    if (preferArabic) {
      final arabic = nameAr?.trim();
      if (arabic != null && arabic.isNotEmpty) return arabic;
    }
    final french = nameFr.trim();
    if (french.isNotEmpty) return french;
    return name;
  }
}

class LivreurDeliveryOrderInfo {
  const LivreurDeliveryOrderInfo({
    required this.id,
    required this.freeTextOrder,
    required this.status,
    this.processingMode = OrderProcessingMode.hanout,
    required this.deliveryType,
    this.paymentMethod = PaymentMethod.cash,
    this.clientAddress,
    this.clientAddressFr,
    this.clientAddressAr,
    this.clientLatitude,
    this.clientLongitude,
    this.notes,
    this.createdAt,
    this.client,
  });

  final String id;
  final String freeTextOrder;
  final OrderStatus status;
  final OrderProcessingMode processingMode;
  final DeliveryType deliveryType;
  final PaymentMethod paymentMethod;
  final String? clientAddress;
  final String? clientAddressFr;
  final String? clientAddressAr;
  final double? clientLatitude;
  final double? clientLongitude;
  final String? notes;
  final DateTime? createdAt;
  final LivreurDeliveryClientInfo? client;

  factory LivreurDeliveryOrderInfo.fromJson(Map<String, dynamic> json) {
    return LivreurDeliveryOrderInfo(
      id: json['id'] as String,
      freeTextOrder: json['freeTextOrder'] as String,
      status: OrderStatus.fromString(json['status'] as String),
      processingMode: OrderProcessingMode.fromString(
        json['processingMode'] as String?,
      ),
      deliveryType: DeliveryType.fromString(json['deliveryType'] as String),
      paymentMethod: PaymentMethod.fromString(
        json['paymentMethod'] as String? ?? 'CASH',
      ),
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      client: json['client'] != null
          ? LivreurDeliveryClientInfo.fromJson(
              json['client'] as Map<String, dynamic>,
            )
          : null,
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

  bool get isDirectLivreurFlow =>
      processingMode == OrderProcessingMode.directLivreur;
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
    this.hanoutDistance,
    this.clientDistance,
  });

  final String id;
  final String status;
  final String orderId;
  final String hanoutId;
  final DateTime createdAt;
  final LivreurDeliveryOrderInfo? order;
  final LivreurHanoutInfo? hanout;
  final double? distance;
  final double? hanoutDistance;
  final double? clientDistance;

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
      hanoutDistance: json['hanoutDistance'] != null
          ? (json['hanoutDistance'] as num).toDouble()
          : null,
      clientDistance: json['clientDistance'] != null
          ? (json['clientDistance'] as num).toDouble()
          : null,
    );
  }
}
