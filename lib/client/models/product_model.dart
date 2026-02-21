/// Model représentant une catégorie de produits
class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final int? order;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.order,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      order: json['order'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'order': order,
    };
  }
}

/// Model représentant un produit
class ProductModel {
  final String id;
  final String name;
  final String? description;
  final double? price;
  final String? image;
  final String? categoryId;
  final CategoryModel? category;
  final String hanoutId;
  final bool isAvailable;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.image,
    this.categoryId,
    this.category,
    required this.hanoutId,
    required this.isAvailable,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: json['price'] as double?,
      image: json['image'] as String?,
      categoryId: json['categoryId'] as String?,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      hanoutId: json['hanoutId'] as String,
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'categoryId': categoryId,
      'category': category?.toJson(),
      'hanoutId': hanoutId,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? image,
    String? categoryId,
    CategoryModel? category,
    String? hanoutId,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      hanoutId: hanoutId ?? this.hanoutId,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}