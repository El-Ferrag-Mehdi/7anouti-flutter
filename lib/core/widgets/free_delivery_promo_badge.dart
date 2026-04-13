import 'package:flutter/material.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';

String freeDeliveryPromoLabel(BuildContext context) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return isArabic ? 'توصيل مجاني' : 'Livraison gratuite';
}

class FreeDeliveryPromoBadge extends StatelessWidget {
  const FreeDeliveryPromoBadge({
    super.key,
    this.compact = false,
    this.light = false,
  });

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFE56A00);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 4 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: light ? Colors.white.withOpacity(0.18) : color.withOpacity(0.12),
        borderRadius: AppRadius.round,
        border: Border.all(
          color: light
              ? Colors.white.withOpacity(0.32)
              : color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_offer_rounded,
            size: compact ? 14 : 16,
            color: light ? Colors.white : color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            freeDeliveryPromoLabel(context),
            style: AppTextStyles.caption.copyWith(
              color: light ? Colors.white : color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
