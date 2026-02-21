import 'package:sevenouti/client/models/carnet_model.dart';

class HanoutClientSummary {
  const HanoutClientSummary({
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

  factory HanoutClientSummary.fromJson(Map<String, dynamic> json) {
    return HanoutClientSummary(
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

class HanoutCarnetModel {
  const HanoutCarnetModel({
    required this.id,
    required this.clientId,
    required this.hanoutId,
    required this.balance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.activatedAt,
    this.creditLimit,
    this.client,
  });

  final String id;
  final String clientId;
  final String hanoutId;
  final double balance;
  final bool isActive;
  final DateTime? activatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? creditLimit;
  final HanoutClientSummary? client;

  factory HanoutCarnetModel.fromJson(Map<String, dynamic> json) {
    return HanoutCarnetModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      hanoutId: json['hanoutId'] as String,
      balance: (json['balance'] as num).toDouble(),
      isActive: json['isActive'] as bool,
      activatedAt: json['activatedAt'] != null
          ? DateTime.parse(json['activatedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      creditLimit: json['creditLimit'] != null
          ? (json['creditLimit'] as num).toDouble()
          : null,
      client: json['client'] != null
          ? HanoutClientSummary.fromJson(
              json['client'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  String get formattedBalance {
    return '${balance.abs().toStringAsFixed(2)} DH';
  }

  bool get hasDebt => balance > 0;

  bool get isLimitReached {
    if (creditLimit == null) return false;
    return balance >= creditLimit!;
  }

  bool get isLimitNear {
    if (creditLimit == null) return false;
    return balance >= (creditLimit! * 0.8);
  }
}

class HanoutCarnetRequestModel {
  const HanoutCarnetRequestModel({
    required this.id,
    required this.clientId,
    required this.hanoutId,
    required this.status,
    required this.createdAt,
    this.client,
    this.rejectionReason,
    this.respondedAt,
  });

  final String id;
  final String clientId;
  final String hanoutId;
  final RequestStatus status;
  final DateTime createdAt;
  final String? rejectionReason;
  final DateTime? respondedAt;
  final HanoutClientSummary? client;

  factory HanoutCarnetRequestModel.fromJson(Map<String, dynamic> json) {
    return HanoutCarnetRequestModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      hanoutId: json['hanoutId'] as String,
      status: RequestStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      client: json['client'] != null
          ? HanoutClientSummary.fromJson(
              json['client'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
