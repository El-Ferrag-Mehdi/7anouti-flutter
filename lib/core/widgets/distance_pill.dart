import 'package:flutter/material.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/utils/location_cache.dart';
import 'package:sevenouti/utils/location_service.dart';
import 'package:sevenouti/utils/location_utils.dart';

class CurrentDistancePill extends StatefulWidget {
  const CurrentDistancePill({
    required this.targetLatitude,
    required this.targetLongitude,
    this.icon = Icons.near_me,
    this.maxWidth = 200,
    super.key,
  });

  final double? targetLatitude;
  final double? targetLongitude;
  final IconData icon;
  final double maxWidth;

  @override
  State<CurrentDistancePill> createState() => _CurrentDistancePillState();
}

class _CurrentDistancePillState extends State<CurrentDistancePill> {
  static Future<CachedLocation?>? _sharedLocationFuture;
  final _locationService = LocationService();

  bool get _hasTarget =>
      widget.targetLatitude != null && widget.targetLongitude != null;

  Future<CachedLocation?> _loadLocation() async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final cached = await _locationService.getCachedLocation();
    return cached ??
        await _locationService.fetchAndCacheCurrentLocation(
          languageCode: languageCode,
        );
  }

  @override
  void initState() {
    super.initState();
    if (_hasTarget) {
      _sharedLocationFuture ??= _loadLocation();
    }
  }

  @override
  void didUpdateWidget(covariant CurrentDistancePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sharedLocationFuture == null && _hasTarget) {
      _sharedLocationFuture = _loadLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasTarget) return const SizedBox.shrink();

    final future = _sharedLocationFuture ??= _loadLocation();
    return FutureBuilder<CachedLocation?>(
      future: future,
      builder: (context, snapshot) {
        final current = snapshot.data;
        if (current == null) return const SizedBox.shrink();

        final distance = LocationUtils.calculateDistance(
          current.latitude,
          current.longitude,
          widget.targetLatitude!,
          widget.targetLongitude!,
        );
        final distanceText = LocationUtils.formatDistance(distance);

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppRadius.round,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxWidth),
                child: Text(
                  distanceText,
                  style: AppTextStyles.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
