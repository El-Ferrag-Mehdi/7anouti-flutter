/// Model représentant une commande
class OrderModel {
  final String id;
  final String clientId;
  final String hanoutId;
  final String? livreurId;
  final String freeTextOrder; // Commande en texte libre
  final List<OrderItem>? items; // Items structurés (optionnel)
  final OrderStatus status;
  final DeliveryType deliveryType;
  final PaymentMethod paymentMethod;
  final double? deliveryFee;
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

  const OrderModel({
    required this.id,
    required this.clientId,
    required this.hanoutId,
    this.livreurId,
    required this.freeTextOrder,
    this.items,
    required this.status,
    required this.deliveryType,
    required this.paymentMethod,
    this.deliveryFee,
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
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      hanoutId: json['hanoutId'] as String,
      livreurId: json['livreurId'] as String?,
      freeTextOrder: json['freeTextOrder'] as String,
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
                .toList()
          : null,
      status: OrderStatus.fromString(json['status'] as String),
      deliveryType: DeliveryType.fromString(json['deliveryType'] as String),
      paymentMethod: PaymentMethod.fromString(json['paymentMethod'] as String),
      deliveryFee: json['deliveryFee'] as double?,
      totalAmount: json['totalAmount'] as double?,
      clientAddress: json['clientAddress'] as String?,
      clientAddressFr: json['clientAddressFr'] as String?,
      clientAddressAr: json['clientAddressAr'] as String?,
      clientLatitude: json['clientLatitude'] as double?,
      clientLongitude: json['clientLongitude'] as double?,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'hanoutId': hanoutId,
      'livreurId': livreurId,
      'freeTextOrder': freeTextOrder,
      'items': items?.map((item) => item.toJson()).toList(),
      'status': status.value,
      'deliveryType': deliveryType.value,
      'paymentMethod': paymentMethod.value,
      'deliveryFee': deliveryFee,
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
    };
  }
}

/// Item individuel dans une commande (optionnel)
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

/// Statut de la commande
enum OrderStatus {
  pending('PENDING'), // En attente d'acceptation
  accepted('ACCEPTED'), // Acceptée par le hanout
  preparing('PREPARING'), // En préparation
  ready('READY'), // Prête pour collecte/livraison
  pickedUp('PICKED_UP'), // Récupérée par le livreur
  delivering('DELIVERING'), // En cours de livraison
  delivered('DELIVERED'), // Livrée
  cancelled('CANCELLED'); // Annulée

  const OrderStatus(this.value);
  final String value;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value.toUpperCase(),
      orElse: () => OrderStatus.pending,
    );
  }

  /// Retourne la couleur associée au statut
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.accepted:
        return 'Acceptée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.ready:
        return 'Prête';
      case OrderStatus.pickedUp:
        return 'Récupérée';
      case OrderStatus.delivering:
        return 'En livraison';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }
}

/// Type de livraison
enum DeliveryType {
  pickup('PICKUP'), // Collecte par le client
  delivery('DELIVERY'); // Livraison

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

/// Méthode de paiement
enum PaymentMethod {
  cash('CASH'), // Espèces
  carnet('CARNET'); // Crédit (ajouté au carnet)

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
        return 'Espèces';
      case PaymentMethod.carnet:
        return 'Carnet';
    }
  }
}
