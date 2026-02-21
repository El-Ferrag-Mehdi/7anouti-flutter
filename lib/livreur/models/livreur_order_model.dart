import 'package:sevenouti/client/models/order_model.dart';

class LivreurHanoutSummary {
  const LivreurHanoutSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
  });

  final String id;
  final String name;
  final String address;
  final String phone;

  factory LivreurHanoutSummary.fromJson(Map<String, dynamic> json) {
    return LivreurHanoutSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
    );
  }
}

class LivreurClientSummary {
  const LivreurClientSummary({
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

  factory LivreurClientSummary.fromJson(Map<String, dynamic> json) {
    return LivreurClientSummary(
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

class LivreurOrderModel {
  const LivreurOrderModel({
    required this.id,
    required this.clientId,
    required this.hanoutId,
    required this.freeTextOrder,
    required this.status,
    required this.deliveryType,
    required this.paymentMethod,
    required this.createdAt,
    this.hanout,
    this.client,
    this.clientAddress,
    this.clientAddressFr,
    this.clientAddressAr,
    this.clientLatitude,
    this.clientLongitude,
    this.notes,
    this.totalAmount,
    this.deliveryFee,
    this.acceptedAt,
    this.readyAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  final String id;
  final String clientId;
  final String hanoutId;
  final String freeTextOrder;
  final OrderStatus status;
  final DeliveryType deliveryType;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final LivreurHanoutSummary? hanout;
  final LivreurClientSummary? client;
  final String? clientAddress;
  final String? clientAddressFr;
  final String? clientAddressAr;
  final double? clientLatitude;
  final double? clientLongitude;
  final String? notes;
  final double? totalAmount;
  final double? deliveryFee;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  factory LivreurOrderModel.fromJson(Map<String, dynamic> json) {
    return LivreurOrderModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      hanoutId: json['hanoutId'] as String,
      freeTextOrder: json['freeTextOrder'] as String,
      status: OrderStatus.fromString(json['status'] as String),
      deliveryType: DeliveryType.fromString(json['deliveryType'] as String),
      paymentMethod: PaymentMethod.fromString(json['paymentMethod'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
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
      totalAmount: json['totalAmount'] != null
          ? (json['totalAmount'] as num).toDouble()
          : null,
      deliveryFee: json['deliveryFee'] != null
          ? (json['deliveryFee'] as num).toDouble()
          : null,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      readyAt: json['readyAt'] != null
          ? DateTime.parse(json['readyAt'] as String)
          : null,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.parse(json['pickedUpAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      hanout: json['hanout'] != null
          ? LivreurHanoutSummary.fromJson(
              json['hanout'] as Map<String, dynamic>,
            )
          : null,
      client: json['client'] != null
          ? LivreurClientSummary.fromJson(
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
}
