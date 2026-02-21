import 'package:flutter/material.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';

/// Card de base de l'application
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation = 0,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
        boxShadow: elevation > 0 ? AppShadows.card : AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.large,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.large,
          child: Padding(
            padding: padding ?? AppSpacing.cardPadding,
            child: child,
          ),
        ),
      ),
    );

    return card;
  }
}

/// Card pour afficher un Hanout
class HanoutCard extends StatelessWidget {
  const HanoutCard({
    required this.name,
    required this.address,
    required this.distance,
    this.imageUrl,
    this.rating,
    this.isOpen = true,
    this.hasCarnet = false,
    this.onTap,
    super.key,
  });

  final String name;
  final String address;
  final String distance;
  final String? imageUrl;
  final double? rating;
  final bool isOpen;
  final bool hasCarnet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.medium,
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: AppRadius.medium,
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.store,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.store,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom + statut
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.h4,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? AppColors.success.withOpacity(0.15)
                            : AppColors.error.withOpacity(0.15),
                        borderRadius: AppRadius.round,
                        border: Border.all(
                          color: isOpen ? AppColors.success : AppColors.error,
                        ),
                      ),
                      child: Text(
                        isOpen ? 'Ouvert' : 'Fermé',
                        style: AppTextStyles.caption.copyWith(
                          color: isOpen ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Adresse
                Text(
                  address,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Distance + rating + carnet
                Row(
                  children: [
                    // Distance
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Rating
                    if (rating != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.star,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating!.toStringAsFixed(1),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],

                    // Carnet disponible
                    if (hasCarnet) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.25),
                          borderRadius: AppRadius.round,
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.book,
                              size: 12,
                              color: AppColors.brown,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Carnet',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.brown,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
