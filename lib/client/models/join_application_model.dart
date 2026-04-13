import 'package:sevenouti/client/models/business_category_model.dart';

enum JoinApplicationType {
  livreur('LIVREUR'),
  hanout('HANOUT');

  const JoinApplicationType(this.value);

  final String value;

  static JoinApplicationType fromString(String value) {
    return JoinApplicationType.values.firstWhere(
      (type) => type.value == value.toUpperCase(),
      orElse: () => JoinApplicationType.livreur,
    );
  }
}

enum JoinApplicationStatus {
  pending('PENDING'),
  contacted('CONTACTED'),
  archived('ARCHIVED');

  const JoinApplicationStatus(this.value);

  final String value;

  static JoinApplicationStatus fromString(String value) {
    return JoinApplicationStatus.values.firstWhere(
      (status) => status.value == value.toUpperCase(),
      orElse: () => JoinApplicationStatus.pending,
    );
  }
}

class JoinApplicationModel {
  const JoinApplicationModel({
    required this.id,
    required this.type,
    required this.status,
    required this.nameFr,
    required this.nameAr,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
    this.businessCategoryId,
    this.businessCategoryName,
    this.businessCategoryNameAr,
    this.deliveryZoneFr,
    this.deliveryZoneAr,
    this.addressFr,
    this.addressAr,
    this.installationId,
    this.businessCategory,
  });

  final String id;
  final JoinApplicationType type;
  final JoinApplicationStatus status;
  final String nameFr;
  final String nameAr;
  final String phone;
  final String? businessCategoryId;
  final String? businessCategoryName;
  final String? businessCategoryNameAr;
  final String? deliveryZoneFr;
  final String? deliveryZoneAr;
  final String? addressFr;
  final String? addressAr;
  final String? installationId;
  final BusinessCategoryModel? businessCategory;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory JoinApplicationModel.fromJson(Map<String, dynamic> json) {
    return JoinApplicationModel(
      id: json['id'] as String,
      type: JoinApplicationType.fromString(json['type'] as String? ?? ''),
      status: JoinApplicationStatus.fromString(
        json['status'] as String? ?? '',
      ),
      nameFr: json['nameFr'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      businessCategoryId: json['businessCategoryId'] as String?,
      businessCategoryName: json['businessCategoryName'] as String?,
      businessCategoryNameAr: json['businessCategoryNameAr'] as String?,
      deliveryZoneFr: json['deliveryZoneFr'] as String?,
      deliveryZoneAr: json['deliveryZoneAr'] as String?,
      addressFr: json['addressFr'] as String?,
      addressAr: json['addressAr'] as String?,
      installationId: json['installationId'] as String?,
      businessCategory: json['businessCategory'] is Map<String, dynamic>
          ? BusinessCategoryModel.fromJson(
              json['businessCategory'] as Map<String, dynamic>,
            )
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
