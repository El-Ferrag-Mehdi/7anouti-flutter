class FirstDeliveryPromoConfigModel {
  const FirstDeliveryPromoConfigModel({
    required this.firstDeliveryFreeEnabled,
    this.updatedAt,
  });

  final bool firstDeliveryFreeEnabled;
  final DateTime? updatedAt;

  factory FirstDeliveryPromoConfigModel.fromJson(Map<String, dynamic> json) {
    return FirstDeliveryPromoConfigModel(
      firstDeliveryFreeEnabled:
          json['firstDeliveryFreeEnabled'] as bool? ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
