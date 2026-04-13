class BusinessCategoryModel {
  final String id;
  final String name;
  final String? nameAr;
  final String? slug;
  final String? icon;
  final int? order;
  final bool isDefault;
  final int? hanoutsCount;

  const BusinessCategoryModel({
    required this.id,
    required this.name,
    this.nameAr,
    this.slug,
    this.icon,
    this.order,
    this.isDefault = false,
    this.hanoutsCount,
  });

  factory BusinessCategoryModel.fromJson(Map<String, dynamic> json) {
    return BusinessCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
      slug: json['slug'] as String?,
      icon: json['icon'] as String?,
      order: json['order'] as int?,
      isDefault: json['isDefault'] as bool? ?? false,
      hanoutsCount: json['hanoutsCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
      'slug': slug,
      'icon': icon,
      'order': order,
      'isDefault': isDefault,
      'hanoutsCount': hanoutsCount,
    };
  }

  String get displayIcon {
    final value = icon?.trim();
    if (value == null || value.isEmpty) {
      return '🏪';
    }
    return value;
  }

  String displayName({required bool preferArabic}) {
    if (preferArabic) {
      final arabic = nameAr?.trim();
      if (arabic != null && arabic.isNotEmpty) {
        return arabic;
      }
    }
    return name;
  }
}
