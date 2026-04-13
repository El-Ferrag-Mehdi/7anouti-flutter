import 'package:flutter/material.dart';
import 'package:sevenouti/client/models/first_delivery_promo_config_model.dart';
import 'package:sevenouti/client/models/first_delivery_promo_status_model.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';

class FirstDeliveryPromoBanner extends StatelessWidget {
  const FirstDeliveryPromoBanner({
    super.key,
    this.status,
    this.config,
    this.compact = false,
  }) : assert(status != null || config != null);

  final FirstDeliveryPromoStatusModel? status;
  final FirstDeliveryPromoConfigModel? config;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isVisible =
        status?.canShowMarketingBanner ??
        (config?.firstDeliveryFreeEnabled ?? false);
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final title = isArabic
        ? 'اول توصيل لك مجاني'
        : 'Votre première livraison gratuite';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.md : AppSpacing.lg,
        vertical: compact ? AppSpacing.sm : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFA41B),
            Color(0xFFFF6B00),
          ],
        ),
        borderRadius: AppRadius.large,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A00).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: compact ? 32 : 36,
            width: compact ? 32 : 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: AppRadius.medium,
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (compact ? AppTextStyles.bodyMedium : AppTextStyles.bodyLarge)
                      .copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
