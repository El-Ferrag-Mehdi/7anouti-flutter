import 'package:flutter/material.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/l10n/client_l10n.dart';
import 'package:sevenouti/client/models/models.dart';
import 'package:sevenouti/client/models/gas_service_order.dart';
import 'package:sevenouti/client/repository/repositories.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/buttons.dart'
    hide IconButton, TextButton;
import 'package:sevenouti/core/widgets/modern_sheet.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/utils/date_utils.dart' as app_date;
import 'package:sevenouti/utils/phone_launcher.dart';

class GasServiceTrackingPage extends StatefulWidget {
  const GasServiceTrackingPage({required this.order, super.key});

  final GasServiceOrder order;

  @override
  State<GasServiceTrackingPage> createState() => _GasServiceTrackingPageState();
}

class _GasServiceTrackingPageState extends State<GasServiceTrackingPage> {
  late GasServiceOrder _order;
  late GasServiceRepository _repository;
  ReviewModel? _review;
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _repository = GasServiceRepository(ApiService());
    _loadExistingReview();
  }

  @override
  Widget build(BuildContext context) {
    final status = _order.status;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.clientGasServiceTitle),
        actions: [
          IconButton(
            onPressed: _refreshOrder,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'contact',
                child: Row(
                  children: [
                    Icon(Icons.phone),
                    SizedBox(width: 8),
                    Text(context.l10n.clientCommonContactDriver),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildStatusHeader(status),
              _buildTimeline(),
              _buildServiceDetails(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildStatusHeader(GasServiceStatus status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            status.color.withOpacity(0.95),
            status.color,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                status.icon,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.gasStatusLabel(status),
              style: AppTextStyles.h2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.gasStatusMessage(status),
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.large,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.clientOrderTrackingDetailedTracking, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.md),
            _buildTimelineStep(
              title: context.l10n.clientGasStatusPending,
              time: _order.createdAt,
              isCompleted: _isStatusReached(GasServiceStatus.pending),
              isActive: _order.status == GasServiceStatus.pending,
            ),
            _buildTimelineStep(
              title: context.l10n.clientGasStatusEnRoute,
              time: _order.acceptedAt,
              isCompleted: _isStatusReached(GasServiceStatus.enRoute),
              isActive: _order.status == GasServiceStatus.enRoute,
            ),
            _buildTimelineStep(
              title: context.l10n.clientGasStatusArrive,
              time: _order.arrivedAt,
              isCompleted: _isStatusReached(GasServiceStatus.arrive),
              isActive: _order.status == GasServiceStatus.arrive,
            ),
            _buildTimelineStep(
              title: context.l10n.clientGasStatusPickedEmpty,
              time: _order.pickedUpAt,
              isCompleted: _isStatusReached(GasServiceStatus.recupereVide),
              isActive: _order.status == GasServiceStatus.recupereVide,
            ),
            _buildTimelineStep(
              title: context.l10n.clientGasStatusToHanout,
              time: _order.atHanoutAt,
              isCompleted: _isStatusReached(GasServiceStatus.vaAuHanout),
              isActive: _order.status == GasServiceStatus.vaAuHanout,
            ),
            _buildTimelineStep(
              title: context.l10n.clientGasStatusReturnHome,
              time: _order.returnHomeAt,
              isCompleted: _isStatusReached(GasServiceStatus.retourMaison),
              isActive: _order.status == GasServiceStatus.retourMaison,
            ),
            _buildTimelineStep(
              title: context.l10n.clientGasStatusDelivered,
              time: _order.deliveredAt,
              isCompleted: _isStatusReached(GasServiceStatus.livre),
              isActive: _order.status == GasServiceStatus.livre,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required DateTime? time,
    required bool isCompleted,
    required bool isActive,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted || isActive
                    ? AppColors.primary
                    : AppColors.border,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isActive ? AppShadows.card : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? AppColors.primary : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: isActive || isCompleted
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isCompleted || isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                if (time != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    app_date.DateUtils.formatDateTime(time),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.clientGasDetailsTitle, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.large,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(context.l10n.clientGasServiceLabel, context.l10n.clientGasBottleTitle),
                const Divider(height: AppSpacing.lg),
                if (_order.clientAddress != null)
                  _detailRow(context.l10n.clientOrderTrackingAddress, _order.clientAddress!),
                const Divider(height: AppSpacing.lg),
                _detailRow(context.l10n.clientGasBottleTitle, '${_order.price} DH'),
                const Divider(height: AppSpacing.lg),
                _detailRow(context.l10n.clientCommonServiceFee, '${_order.serviceFee} DH'),
                const Divider(height: AppSpacing.lg),
                _detailRow(context.l10n.clientCommonTotal, '${_order.total} DH', isTotal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomAction() {
    if (_order.status == GasServiceStatus.livre) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppShadows.elevated,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: PrimaryButton(
            label: _review == null ? context.l10n.clientOrdersRateDriver : context.l10n.clientOrderTrackingEditReview,
            icon: Icons.star,
            onPressed: _isSubmittingReview ? null : _showReviewSheet,
            fullWidth: true,
          ),
        ),
      );
    }

    return null;
  }

  Future<void> _refreshOrder() async {
    try {
      final latest = await _repository.getRequestById(_order.id);
      if (!mounted) return;
      setState(() {
        _order = latest;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.clientGasRefreshError),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _loadExistingReview() async {
    if (_order.status != GasServiceStatus.livre) return;
    try {
      final review = await _repository.getRequestReview(_order.id);
      if (!mounted) return;
      setState(() {
        _review = review;
      });
    } catch (_) {}
  }

  Future<void> _showReviewSheet() async {
    var livreurRating = _review?.livreurRating ?? 5;
    final livreurCommentController = TextEditingController(
      text: _review?.livreurComment ?? '',
    );

    final result = await showAppBottomSheet<bool>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            const SizedBox(height: AppSpacing.lg),
            SheetTitle(context.l10n.clientOrdersRateDriver),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed: () {
                    setSheetState(() {
                      livreurRating = star;
                    });
                  },
                  icon: Icon(
                    star <= livreurRating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                  ),
                );
              }),
            ),
            TextField(
              controller: livreurCommentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: context.l10n.clientOrdersDriverCommentHint,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.clientCommonSend),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.clientCommonCancel),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) {
      livreurCommentController.dispose();
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });
    try {
      final review = await _repository.upsertRequestReview(
        requestId: _order.id,
        livreurRating: livreurRating,
        livreurComment: livreurCommentController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _review = review;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.clientOrderTrackingReviewSaved),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.clientCommonErrorWithMessage(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReview = false;
        });
      }
      livreurCommentController.dispose();
    }
  }

  bool _isStatusReached(GasServiceStatus status) {
    final currentIndex = GasServiceStatus.values.indexOf(_order.status);
    final targetIndex = GasServiceStatus.values.indexOf(status);
    return currentIndex >= targetIndex;
  }

  void _handleMenuAction(String action) {
    if (action == 'contact') {
      _callPhone();
    }
  }

  Future<void> _callPhone() async {
    final ok = await launchPhoneCall(_order.livreurPhone);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.clientOrderTrackingDriverPhoneUnavailable),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}



