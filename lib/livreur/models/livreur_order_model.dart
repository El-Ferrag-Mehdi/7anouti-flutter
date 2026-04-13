import 'package:sevenouti/client/models/order_model.dart';

class LivreurHanoutSummary {
  const LivreurHanoutSummary({
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

  factory LivreurHanoutSummary.fromJson(Map<String, dynamic> json) {
    return LivreurHanoutSummary(
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
    this.processingMode = OrderProcessingMode.hanout,
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
    this.freeDeliveryPromoApplied = false,
    this.acceptedAt,
    this.readyAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.hanoutDistance,
    this.clientDistance,
  });

  final String id;
  final String clientId;
  final String hanoutId;
  final String freeTextOrder;
  final OrderStatus status;
  final OrderProcessingMode processingMode;
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
  final bool freeDeliveryPromoApplied;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final double? hanoutDistance;
  final double? clientDistance;

  factory LivreurOrderModel.fromJson(Map<String, dynamic> json) {
    return LivreurOrderModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      hanoutId: json['hanoutId'] as String,
      freeTextOrder: json['freeTextOrder'] as String,
      status: OrderStatus.fromString(json['status'] as String),
      processingMode: OrderProcessingMode.fromString(
        json['processingMode'] as String?,
      ),
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
      freeDeliveryPromoApplied:
          json['freeDeliveryPromoApplied'] as bool? ?? false,
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
      hanoutDistance: json['hanoutDistance'] != null
          ? (json['hanoutDistance'] as num).toDouble()
          : null,
      clientDistance: json['clientDistance'] != null
          ? (json['clientDistance'] as num).toDouble()
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

  bool get isDirectLivreurFlow =>
      processingMode == OrderProcessingMode.directLivreur;

  LivreurOrderModel copyWith({
    String? id,
    String? clientId,
    String? hanoutId,
    String? freeTextOrder,
    OrderStatus? status,
    OrderProcessingMode? processingMode,
    DeliveryType? deliveryType,
    PaymentMethod? paymentMethod,
    DateTime? createdAt,
    LivreurHanoutSummary? hanout,
    LivreurClientSummary? client,
    String? clientAddress,
    String? clientAddressFr,
    String? clientAddressAr,
    double? clientLatitude,
    double? clientLongitude,
    String? notes,
    double? totalAmount,
    double? deliveryFee,
    bool? freeDeliveryPromoApplied,
    DateTime? acceptedAt,
    DateTime? readyAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    double? hanoutDistance,
    double? clientDistance,
  }) {
    return LivreurOrderModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      hanoutId: hanoutId ?? this.hanoutId,
      freeTextOrder: freeTextOrder ?? this.freeTextOrder,
      status: status ?? this.status,
      processingMode: processingMode ?? this.processingMode,
      deliveryType: deliveryType ?? this.deliveryType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      hanout: hanout ?? this.hanout,
      client: client ?? this.client,
      clientAddress: clientAddress ?? this.clientAddress,
      clientAddressFr: clientAddressFr ?? this.clientAddressFr,
      clientAddressAr: clientAddressAr ?? this.clientAddressAr,
      clientLatitude: clientLatitude ?? this.clientLatitude,
      clientLongitude: clientLongitude ?? this.clientLongitude,
      notes: notes ?? this.notes,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      freeDeliveryPromoApplied:
          freeDeliveryPromoApplied ?? this.freeDeliveryPromoApplied,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      readyAt: readyAt ?? this.readyAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      hanoutDistance: hanoutDistance ?? this.hanoutDistance,
      clientDistance: clientDistance ?? this.clientDistance,
    );
  }
}
