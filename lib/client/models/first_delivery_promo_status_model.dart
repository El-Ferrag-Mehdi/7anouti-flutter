import 'package:sevenouti/client/models/first_delivery_promo_config_model.dart';

class FirstDeliveryPromoStatusModel extends FirstDeliveryPromoConfigModel {
  const FirstDeliveryPromoStatusModel({
    required super.firstDeliveryFreeEnabled,
    required this.eligible,
    this.reason,
    super.updatedAt,
  });

  final bool eligible;
  final String? reason;

  bool get canShowMarketingBanner => firstDeliveryFreeEnabled && eligible;

  factory FirstDeliveryPromoStatusModel.fromJson(Map<String, dynamic> json) {
    return FirstDeliveryPromoStatusModel(
      firstDeliveryFreeEnabled: json['active'] as bool? ?? false,
      eligible: json['eligible'] as bool? ?? false,
      reason: json['reason'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
