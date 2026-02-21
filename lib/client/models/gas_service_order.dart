import 'package:flutter/material.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';

enum GasServiceStatus {
  pending,
  enRoute,
  arrive,
  recupereVide,
  vaAuHanout,
  retourMaison,
  livre,
  cancelled,
  rejected,
}

extension GasServiceStatusX on GasServiceStatus {
  static GasServiceStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return GasServiceStatus.pending;
      case 'EN_ROUTE':
        return GasServiceStatus.enRoute;
      case 'ARRIVE':
        return GasServiceStatus.arrive;
      case 'RECUPERE_VIDE':
        return GasServiceStatus.recupereVide;
      case 'VA_AU_HANOUT':
        return GasServiceStatus.vaAuHanout;
      case 'RETOUR_MAISON':
        return GasServiceStatus.retourMaison;
      case 'LIVRE':
        return GasServiceStatus.livre;
      case 'CANCELLED':
        return GasServiceStatus.cancelled;
      case 'REJECTED':
        return GasServiceStatus.rejected;
      default:
        return GasServiceStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case GasServiceStatus.pending:
        return 'PENDING';
      case GasServiceStatus.enRoute:
        return 'EN_ROUTE';
      case GasServiceStatus.arrive:
        return 'ARRIVE';
      case GasServiceStatus.recupereVide:
        return 'RECUPERE_VIDE';
      case GasServiceStatus.vaAuHanout:
        return 'VA_AU_HANOUT';
      case GasServiceStatus.retourMaison:
        return 'RETOUR_MAISON';
      case GasServiceStatus.livre:
        return 'LIVRE';
      case GasServiceStatus.cancelled:
        return 'CANCELLED';
      case GasServiceStatus.rejected:
        return 'REJECTED';
    }
  }

  String get displayName {
    switch (this) {
      case GasServiceStatus.pending:
        return 'En attente';
      case GasServiceStatus.enRoute:
        return 'En route';
      case GasServiceStatus.arrive:
        return 'Arrivé';
      case GasServiceStatus.recupereVide:
        return 'Bouteille récupérée';
      case GasServiceStatus.vaAuHanout:
        return 'Vers le hanout';
      case GasServiceStatus.retourMaison:
        return 'Retour maison';
      case GasServiceStatus.livre:
        return 'Livré';
      case GasServiceStatus.cancelled:
        return 'Annulé';
      case GasServiceStatus.rejected:
        return 'Refusé';
    }
  }

  String get message {
    switch (this) {
      case GasServiceStatus.pending:
        return 'En attente d\'un livreur.';
      case GasServiceStatus.enRoute:
        return 'Le livreur est en route vers votre domicile.';
      case GasServiceStatus.arrive:
        return 'Le livreur est arrivé pour récupérer la bouteille vide.';
      case GasServiceStatus.recupereVide:
        return 'La bouteille vide est récupérée.';
      case GasServiceStatus.vaAuHanout:
        return 'Le livreur va au hanout pour récupérer une nouvelle bouteille.';
      case GasServiceStatus.retourMaison:
        return 'Le livreur revient vers votre domicile.';
      case GasServiceStatus.livre:
        return 'La nouvelle bouteille a été livrée.';
      case GasServiceStatus.cancelled:
        return 'La demande a été annulée.';
      case GasServiceStatus.rejected:
        return 'La demande a été refusée.';
    }
  }

  Color get color {
    switch (this) {
      case GasServiceStatus.livre:
        return AppColors.success;
      case GasServiceStatus.cancelled:
      case GasServiceStatus.rejected:
        return AppColors.error;
      case GasServiceStatus.pending:
      case GasServiceStatus.enRoute:
      case GasServiceStatus.arrive:
      case GasServiceStatus.recupereVide:
      case GasServiceStatus.vaAuHanout:
      case GasServiceStatus.retourMaison:
        return AppColors.warning;
    }
  }

  IconData get icon {
    switch (this) {
      case GasServiceStatus.pending:
        return Icons.hourglass_top;
      case GasServiceStatus.enRoute:
        return Icons.delivery_dining;
      case GasServiceStatus.arrive:
        return Icons.location_on;
      case GasServiceStatus.recupereVide:
        return Icons.sync_alt;
      case GasServiceStatus.vaAuHanout:
        return Icons.store;
      case GasServiceStatus.retourMaison:
        return Icons.home_filled;
      case GasServiceStatus.livre:
        return Icons.check_circle;
      case GasServiceStatus.cancelled:
        return Icons.cancel;
      case GasServiceStatus.rejected:
        return Icons.block;
    }
  }
}

class GasServiceOrder {
  const GasServiceOrder({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.price,
    required this.serviceFee,
    this.clientAddress,
    this.livreurPhone,
    this.clientLatitude,
    this.clientLongitude,
    this.notes,
    this.acceptedAt,
    this.arrivedAt,
    this.pickedUpAt,
    this.atHanoutAt,
    this.returnHomeAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  final String id;
  final DateTime createdAt;
  final GasServiceStatus status;
  final double price;
  final double serviceFee;
  final String? clientAddress;
  final String? livreurPhone;
  final double? clientLatitude;
  final double? clientLongitude;
  final String? notes;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? pickedUpAt;
  final DateTime? atHanoutAt;
  final DateTime? returnHomeAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  double get total => price + serviceFee;

  factory GasServiceOrder.fromJson(Map<String, dynamic> json) {
    return GasServiceOrder(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: GasServiceStatusX.fromString(json['status'] as String),
      price: (json['price'] as num).toDouble(),
      serviceFee: (json['serviceFee'] as num).toDouble(),
      clientAddress: json['clientAddress'] as String?,
      clientLatitude: json['clientLatitude'] != null
          ? (json['clientLatitude'] as num).toDouble()
          : null,
      clientLongitude: json['clientLongitude'] != null
          ? (json['clientLongitude'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
      livreurPhone: json['livreurPhone'] as String?,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      arrivedAt: json['arrivedAt'] != null
          ? DateTime.parse(json['arrivedAt'] as String)
          : null,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.parse(json['pickedUpAt'] as String)
          : null,
      atHanoutAt: json['atHanoutAt'] != null
          ? DateTime.parse(json['atHanoutAt'] as String)
          : null,
      returnHomeAt: json['returnHomeAt'] != null
          ? DateTime.parse(json['returnHomeAt'] as String)
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
      'createdAt': createdAt.toIso8601String(),
      'status': status.value,
      'price': price,
      'serviceFee': serviceFee,
      'clientAddress': clientAddress,
      'clientLatitude': clientLatitude,
      'clientLongitude': clientLongitude,
      'notes': notes,
      'livreurPhone': livreurPhone,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'arrivedAt': arrivedAt?.toIso8601String(),
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'atHanoutAt': atHanoutAt?.toIso8601String(),
      'returnHomeAt': returnHomeAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
    };
  }

  GasServiceOrder copyWith({
    GasServiceStatus? status,
    DateTime? acceptedAt,
    DateTime? arrivedAt,
    DateTime? pickedUpAt,
    DateTime? atHanoutAt,
    DateTime? returnHomeAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? livreurPhone,
  }) {
    return GasServiceOrder(
      id: id,
      createdAt: createdAt,
      status: status ?? this.status,
      price: price,
      serviceFee: serviceFee,
      clientAddress: clientAddress,
      clientLatitude: clientLatitude,
      clientLongitude: clientLongitude,
      notes: notes,
      livreurPhone: livreurPhone ?? this.livreurPhone,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      atHanoutAt: atHanoutAt ?? this.atHanoutAt,
      returnHomeAt: returnHomeAt ?? this.returnHomeAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
