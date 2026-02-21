/// Model représentant le carnet (crédit) entre un client et un hanout
class CarnetModel {

  const CarnetModel({
    required this.id,
    required this.clientId,
    required this.hanoutId,
    required this.balance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.activatedAt,
    
  });
  final String id;
  final String clientId;
  final String hanoutId;
  final double balance; // Solde actuel (positif = dette, négatif = crédit)
  final bool isActive; // Si le carnet est activé
  final DateTime? activatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CarnetModel.fromJson(Map<String, dynamic> json) {
    return CarnetModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      hanoutId: json['hanoutId'] as String,
      balance: json['balance'] as double,
      isActive: json['isActive'] as bool,
      activatedAt: json['activatedAt'] != null
          ? DateTime.parse(json['activatedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'hanoutId': hanoutId,
      'balance': balance,
      'isActive': isActive,
      'activatedAt': activatedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Retourne le solde formaté (ex: "250.00 DH")
  String get formattedBalance {
    return '${balance.abs().toStringAsFixed(2)} DH';
  }

  /// Indique si le client a une dette
  bool get hasDebt => balance > 0;

  /// Indique si le client a du crédit
  bool get hasCredit => balance < 0;
}

/// Transaction du carnet
class CarnetTransactionModel {
  final String id;
  final String carnetId;
  final String clientId;
  final String hanoutId;
  final TransactionType type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? orderId; // Si lié à une commande
  final String? description;
  final DateTime createdAt;

  const CarnetTransactionModel({
    required this.id,
    required this.carnetId,
    required this.clientId,
    required this.hanoutId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.orderId,
    this.description,
    required this.createdAt,
  });

  factory CarnetTransactionModel.fromJson(Map<String, dynamic> json) {
    return CarnetTransactionModel(
      id: json['id'] as String,
      carnetId: json['carnetId'] as String,
      clientId: json['clientId'] as String,
      hanoutId: json['hanoutId'] as String,
      type: TransactionType.fromString(json['type'] as String),
      amount: json['amount'] as double,
      balanceBefore: json['balanceBefore'] as double,
      balanceAfter: json['balanceAfter'] as double,
      orderId: json['orderId'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'carnetId': carnetId,
      'clientId': clientId,
      'hanoutId': hanoutId,
      'type': type.value,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'orderId': orderId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Retourne le montant formaté avec signe
  String get formattedAmount {
    final sign = type == TransactionType.credit ? '+' : '-';
    return '$sign${amount.toStringAsFixed(2)} DH';
  }
}

/// Type de transaction
enum TransactionType {
  credit('CREDIT'), // Ajout de dette (achat)
  payment('PAYMENT'); // Paiement (réduction de dette)

  const TransactionType(this.value);
  final String value;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.value == value.toUpperCase(),
      orElse: () => TransactionType.credit,
    );
  }

  String get displayName {
    switch (this) {
      case TransactionType.credit:
        return 'Achat à crédit';
      case TransactionType.payment:
        return 'Paiement';
    }
  }
}

/// Demande d'activation du carnet
class CarnetRequestModel {
  final String id;
  final String clientId;
  final String hanoutId;
  final RequestStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const CarnetRequestModel({
    required this.id,
    required this.clientId,
    required this.hanoutId,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.respondedAt,
  });

  factory CarnetRequestModel.fromJson(Map<String, dynamic> json) {
    return CarnetRequestModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      hanoutId: json['hanoutId'] as String,
      status: RequestStatus.fromString(json['status'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
    );
  }
  

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'hanoutId': hanoutId,
      'status': status.value,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }
}

/// Statut de la demande de carnet
enum RequestStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED');

  const RequestStatus(this.value);
  final String value;

  static RequestStatus fromString(String value) {
    return RequestStatus.values.firstWhere(
      (status) => status.value == value.toUpperCase(),
      orElse: () => RequestStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case RequestStatus.pending:
        return 'En attente';
      case RequestStatus.approved:
        return 'Approuvée';
      case RequestStatus.rejected:
        return 'Refusée';
    }
  }
}

// enum CarnetRequestStatus {
//   pending('PENDING'),
//   approved('APPROVED'),
//   rejected('REJECTED');

//   const CarnetRequestStatus(this.value);
//   final String value;

//   String get displayName {
//     switch (this) {
//       case CarnetRequestStatus.pending:
//         return 'En attente';
//       case CarnetRequestStatus.approved:
//         return 'Approuvée';
//       case CarnetRequestStatus.rejected:
//         return 'Refusée';
//     }
//   }
// }