import 'package:sevenouti/client/models/business_category_model.dart';

/// Model representant une commande
class OrderModel {
  final String id;
  final String clientId;
  final String hanoutId;
  final String? hanoutName;
  final String? hanoutAddress;
  final String? hanoutPhone;
  final String? businessCategoryId;
  final BusinessCategoryModel? businessCategory;
  final String? livreurId;
  final String? livreurName;
  final String? livreurNameAr;
  final String? livreurPhone;
  final String freeTextOrder;
  final List<OrderItem>? items;
  final OrderStatus status;
  final OrderProcessingMode processingMode;
  final DeliveryType deliveryType;
  final PaymentMethod paymentMethod;
  final double? deliveryFee;
  final double? originalDeliveryFee;
  final bool freeDeliveryPromoApplied;
  final double? freeDeliveryPromoAmount;
  final String? freeDeliveryPromoState;
  final double? totalAmount;
  final String? clientAddress;
  final String? clientAddressFr;
  final String? clientAddressAr;
  final double? clientLatitude;
  final double? clientLongitude;
  final String? notes;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final bool willBeProcessedWhenOpen;

  const OrderModel({
    required this.id,
    required this.clientId,
    required this.hanoutId,
    this.hanoutName,
    this.hanoutAddress,
    this.hanoutPhone,
    this.businessCategoryId,
    this.businessCategory,
    this.livreurId,
    this.livreurName,
    this.livreurNameAr,
    this.livreurPhone,
    required this.freeTextOrder,
    this.items,
    required this.status,
    this.processingMode = OrderProcessingMode.hanout,
    required this.deliveryType,
    required this.paymentMethod,
    this.deliveryFee,
    this.originalDeliveryFee,
    this.freeDeliveryPromoApplied = false,
    this.freeDeliveryPromoAmount,
    this.freeDeliveryPromoState,
    this.totalAmount,
    this.clientAddress,
    this.clientAddressFr,
    this.clientAddressAr,
    this.clientLatitude,
    this.clientLongitude,
    this.notes,
    required this.createdAt,
    this.acceptedAt,
    this.readyAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
    this.willBeProcessedWhenOpen = false,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final hanout = json['hanout'] as Map<String, dynamic>?;
    final livreur = json['livreur'] as Map<String, dynamic>?;

    return OrderModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      hanoutId: json['hanoutId'] as String,
      hanoutName: hanout?['name'] as String?,
      hanoutAddress: hanout?['address'] as String?,
      hanoutPhone: hanout?['phone'] as String?,
      businessCategoryId: hanout?['businessCategoryId'] as String?,
      businessCategory: hanout?['businessCategory'] != null
          ? BusinessCategoryModel.fromJson(
              hanout!['businessCategory'] as Map<String, dynamic>,
            )
          : null,
      livreurId: json['livreurId'] as String?,
      livreurName: livreur?['nameFr'] as String? ?? livreur?['name'] as String?,
      livreurNameAr: livreur?['nameAr'] as String?,
      livreurPhone: livreur?['phone'] as String?,
      freeTextOrder: json['freeTextOrder'] as String,
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
                .toList()
          : null,
      status: OrderStatus.fromString(json['status'] as String),
      processingMode: OrderProcessingMode.fromString(
        json['processingMode'] as String?,
      ),
      deliveryType: DeliveryType.fromString(json['deliveryType'] as String),
      paymentMethod: PaymentMethod.fromString(json['paymentMethod'] as String),
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble(),
      originalDeliveryFee: (json['originalDeliveryFee'] as num?)?.toDouble(),
      freeDeliveryPromoApplied:
          json['freeDeliveryPromoApplied'] as bool? ?? false,
      freeDeliveryPromoAmount: (json['freeDeliveryPromoAmount'] as num?)
          ?.toDouble(),
      freeDeliveryPromoState: json['freeDeliveryPromoState'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      clientAddress: json['clientAddress'] as String?,
      clientAddressFr: json['clientAddressFr'] as String?,
      clientAddressAr: json['clientAddressAr'] as String?,
      clientLatitude: (json['clientLatitude'] as num?)?.toDouble(),
      clientLongitude: (json['clientLongitude'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
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
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      willBeProcessedWhenOpen:
          json['willBeProcessedWhenOpen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'hanoutId': hanoutId,
      'hanout': {
        'name': hanoutName,
        'address': hanoutAddress,
        'phone': hanoutPhone,
        'businessCategoryId': businessCategoryId,
        'businessCategory': businessCategory?.toJson(),
      },
      'livreurId': livreurId,
      'livreur': {
        'name': livreurName,
        'nameAr': livreurNameAr,
        'phone': livreurPhone,
      },
      'freeTextOrder': freeTextOrder,
      'items': items?.map((item) => item.toJson()).toList(),
      'status': status.value,
      'processingMode': processingMode.value,
      'deliveryType': deliveryType.value,
      'paymentMethod': paymentMethod.value,
      'deliveryFee': deliveryFee,
      'originalDeliveryFee': originalDeliveryFee,
      'freeDeliveryPromoApplied': freeDeliveryPromoApplied,
      'freeDeliveryPromoAmount': freeDeliveryPromoAmount,
      'freeDeliveryPromoState': freeDeliveryPromoState,
      'totalAmount': totalAmount,
      'clientAddress': clientAddress,
      'clientAddressFr': clientAddressFr,
      'clientAddressAr': clientAddressAr,
      'clientLatitude': clientLatitude,
      'clientLongitude': clientLongitude,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'readyAt': readyAt?.toIso8601String(),
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'willBeProcessedWhenOpen': willBeProcessedWhenOpen,
    };
  }

  bool get isDirectLivreurFlow =>
      processingMode == OrderProcessingMode.directLivreur;
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double? unitPrice;
  final double? totalPrice;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unitPrice,
    this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: json['unitPrice'] as double?,
      totalPrice: json['totalPrice'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}

enum OrderStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  preparing('PREPARING'),
  ready('READY'),
  pickedUp('PICKED_UP'),
  delivering('DELIVERING'),
  delivered('DELIVERED'),
  cancelled('CANCELLED');

  const OrderStatus(this.value);
  final String value;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value.toUpperCase(),
      orElse: () => OrderStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.accepted:
        return 'Acceptee';
      case OrderStatus.preparing:
        return 'En preparation';
      case OrderStatus.ready:
        return 'Prete';
      case OrderStatus.pickedUp:
        return 'Recuperee';
      case OrderStatus.delivering:
        return 'En livraison';
      case OrderStatus.delivered:
        return 'Livree';
      case OrderStatus.cancelled:
        return 'Annulee';
    }
  }
}

enum OrderProcessingMode {
  hanout('HANOUT'),
  directLivreur('DIRECT_LIVREUR');

  const OrderProcessingMode(this.value);
  final String value;

  static OrderProcessingMode fromString(String? value) {
    return OrderProcessingMode.values.firstWhere(
      (mode) => mode.value == value?.toUpperCase(),
      orElse: () => OrderProcessingMode.hanout,
    );
  }
}

enum DeliveryType {
  pickup('PICKUP'),
  delivery('DELIVERY');

  const DeliveryType(this.value);
  final String value;

  static DeliveryType fromString(String value) {
    return DeliveryType.values.firstWhere(
      (type) => type.value == value.toUpperCase(),
      orElse: () => DeliveryType.delivery,
    );
  }

  String get displayName {
    switch (this) {
      case DeliveryType.pickup:
        return 'Je collecte';
      case DeliveryType.delivery:
        return 'Livraison';
    }
  }
}

enum PaymentMethod {
  cash('CASH'),
  carnet('CARNET');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value.toUpperCase(),
      orElse: () => PaymentMethod.cash,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Especes';
      case PaymentMethod.carnet:
        return 'Carnet';
    }
  }
}
