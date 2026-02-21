import 'package:flutter/material.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/l10n/client_l10n.dart';
import 'package:sevenouti/client/models/models.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/client/repository/repositories.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_background.dart';
import 'package:sevenouti/core/widgets/buttons.dart'
    hide IconButton, TextButton;
import 'package:sevenouti/core/widgets/modern_sheet.dart';
import 'package:sevenouti/l10n/l10n.dart';
import 'package:sevenouti/utils/date_utils.dart' as app_date;
import 'package:sevenouti/utils/phone_launcher.dart';

/// Page de suivi de commande en temps rÃƒÆ’Ã‚Â©el
class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({
    required this.order,
    this.hanoutPhone,
    this.livreurPhone,
    super.key,
  });

  final OrderModel order;
  final String? hanoutPhone;
  final String? livreurPhone;

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  late OrderModel _order;
  late OrderRepository _orderRepository;
  ReviewModel? _review;
  bool _isSubmittingReview = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _orderRepository = OrderRepository(ApiService());
    _loadExistingReview();

    // TODO: En production, tu utiliseras WebSocket ou polling pour les mises ÃƒÆ’Ã‚Â  jour
    // _startListeningToOrderUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.clientOrderTrackingTitle),
        actions: [
          // Menu avec options
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              if (_canCancelOrder())
                PopupMenuItem(
                  enabled: !_isCancelling,
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: AppColors.error),
                      SizedBox(width: 8),
                      Text(context.l10n.clientOrderTrackingCancelOrder),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'contact',
                child: Row(
                  children: [
                    Icon(Icons.phone),
                    SizedBox(width: 8),
                    Text(context.l10n.clientCommonContactHanout),
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
              // Header avec statut principal
              _buildStatusHeader(),

              // Timeline des ÃƒÆ’Ã‚Â©tapes
              _buildTimeline(),

              // DÃƒÆ’Ã‚Â©tails de la commande
              _buildOrderDetails(),

              // Infos hanout
              _buildHanoutInfo(),

              // Infos livreur (si assignÃƒÆ’Ã‚Â©)
              if (_order.livreurId != null) _buildLivreurInfo(),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),

      // Bouton d'action en bas
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  /// Header avec le statut actuel
  Widget _buildStatusHeader() {
    final status = _order.status;
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.95),
            color,
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
            // IcÃƒÆ’Ã‚Â´ne animÃƒÆ’Ã‚Â©e
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Statut
            Text(
              context.orderStatusLabel(status),
              style: AppTextStyles.h2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Message selon le statut
            Text(
              _getStatusMessage(status),
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),

            // Temps estimÃƒÆ’Ã‚Â© (si en cours)
            if (_order.status == OrderStatus.accepted ||
                _order.status == OrderStatus.preparing) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: AppRadius.round,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.clientOrderTrackingEta,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Timeline des ÃƒÆ’Ã‚Â©tapes de la commande
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

            // Liste des ÃƒÆ’Ã‚Â©tapes
            _buildTimelineStep(
              title: context.l10n.clientOrderTrackingStepPlaced,
              time: _order.createdAt,
              isCompleted: true,
              isActive: _order.status == OrderStatus.pending,
            ),

            _buildTimelineStep(
              title: context.l10n.clientOrderTrackingStepAccepted,
              time: _order.acceptedAt,
              isCompleted: _isStatusReached(OrderStatus.accepted),
              isActive: _order.status == OrderStatus.accepted,
            ),

            _buildTimelineStep(
              title: context.l10n.clientOrderTrackingStepPreparing,
              time: _order.readyAt != null ? _order.readyAt : null,
              isCompleted: _isStatusReached(OrderStatus.preparing),
              isActive: _order.status == OrderStatus.preparing,
            ),

            _buildTimelineStep(
              title: context.l10n.clientOrderTrackingStepReady,
              time: _order.readyAt,
              isCompleted: _isStatusReached(OrderStatus.ready),
              isActive: _order.status == OrderStatus.ready,
            ),

            if (_order.deliveryType == DeliveryType.delivery) ...[
              _buildTimelineStep(
                title: context.l10n.clientOrderTrackingStepPickedUp,
                time: _order.pickedUpAt,
                isCompleted: _isStatusReached(OrderStatus.pickedUp),
                isActive: _order.status == OrderStatus.pickedUp,
              ),

              _buildTimelineStep(
                title: context.l10n.clientOrderTrackingStepDelivering,
                time: null,
                isCompleted: _isStatusReached(OrderStatus.delivering),
                isActive: _order.status == OrderStatus.delivering,
              ),
            ],

            _buildTimelineStep(
              title: _order.deliveryType == DeliveryType.delivery
                  ? context.l10n.clientOrderTrackingStepDelivered
                  : context.l10n.clientOrderTrackingStepCollected,
              time: _order.deliveredAt,
              isCompleted: _isStatusReached(OrderStatus.delivered),
              isActive: _order.status == OrderStatus.delivered,
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
        // Indicateur visuel
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
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
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

        // Texte
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

  /// DÃƒÆ’Ã‚Â©tails de la commande
  Widget _buildOrderDetails() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.clientOrderTrackingOrderDetails, style: AppTextStyles.h3),
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
                // NumÃƒÆ’Ã‚Â©ro de commande
                _detailRow(context.l10n.clientOrderTrackingNumber, '#${_order.id.substring(0, 8)}'),
                const Divider(height: AppSpacing.lg),

                // Contenu de la commande
                Text(
                  context.l10n.clientOrderTrackingContent,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _order.freeTextOrder,
                  style: AppTextStyles.bodyMedium,
                ),
                const Divider(height: AppSpacing.lg),

                // Type de livraison
                _detailRow(context.l10n.clientOrderTrackingType, context.deliveryTypeLabel(_order.deliveryType)),
                const Divider(height: AppSpacing.lg),

                // Paiement
                _detailRow(context.l10n.clientConfirmPaymentLabel, context.paymentMethodLabel(_order.paymentMethod)),

                // Adresse (si livraison)
                if (_order.deliveryType == DeliveryType.delivery &&
                    _order.clientAddress != null) ...[
                  const Divider(height: AppSpacing.lg),
                  _detailRow(context.l10n.clientOrderTrackingAddress, _order.clientAddress!),
                ],

                // Frais
                if (_order.deliveryFee != null) ...[
                  const Divider(height: AppSpacing.lg),
                  _detailRow(
                    context.l10n.clientConfirmDeliveryFee,
                    '${_order.deliveryFee!.toStringAsFixed(2)} DH',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  /// Infos du hanout
  Widget _buildHanoutInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.clientOrderTrackingHanout, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.md),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.large,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                // IcÃƒÆ’Ã‚Â´ne
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: AppRadius.medium,
                  ),
                  child: const Icon(
                    Icons.store,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.clientOrderTrackingHanoutNameFallback, // TODO: RÃƒÆ’Ã‚Â©cupÃƒÆ’Ã‚Â©rer depuis hanout
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.clientOrderTrackingHanoutAddressFallback,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),

                // Bouton appel
                IconButton(
                  onPressed: () => _callHanout(),
                  icon: const Icon(Icons.phone),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Infos du livreur
  Widget _buildLivreurInfo() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.clientOrderTrackingDriver, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.md),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.large,
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.3),
              ),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.secondary,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.clientOrderTrackingDriverNameFallback, // TODO: RÃƒÆ’Ã‚Â©cupÃƒÆ’Ã‚Â©rer depuis livreur
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.clientOrderTrackingDriverStats,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bouton appel
                IconButton(
                  onPressed: () => _callLivreur(),
                  icon: const Icon(Icons.phone),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton d'action en bas selon le statut
  Widget? _buildBottomAction() {
    // Si annulÃƒÆ’Ã‚Â©e, pas de bouton
    if (_order.status == OrderStatus.cancelled) {
      return null;
    }

    // Si livrÃƒÆ’Ã‚Â©e, bouton pour ÃƒÆ’Ã‚Â©valuer
    if (_order.status == OrderStatus.delivered) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppShadows.elevated,
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: SafeArea(
          child: PrimaryButton(
            label: _review == null
                ? context.l10n.clientOrderTrackingRateOrder
                : context.l10n.clientOrderTrackingEditReview,
            icon: Icons.star,
            onPressed: _isSubmittingReview ? null : _showReviewSheet,
            fullWidth: true,
          ),
        ),
      );
    }

    // Si en cours, bouton pour annuler (si possible)
    if (_canCancelOrder()) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppShadows.elevated,
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: SafeArea(
          child: SecondaryButton(
            label: context.l10n.clientOrderTrackingCancelOrder,
            icon: Icons.cancel,
            onPressed: _isCancelling ? null : () => _showCancelDialog(),
            fullWidth: true,
          ),
        ),
      );
    }

    return null;
  }

  // === MÃƒÆ’Ã‚Â©thodes Helper ===

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.accepted:
        return AppColors.info;
      case OrderStatus.preparing:
      case OrderStatus.ready:
      case OrderStatus.pickedUp:
      case OrderStatus.delivering:
        return AppColors.warning;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.accepted:
        return Icons.check_circle;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.done_all;
      case OrderStatus.pickedUp:
        return Icons.shopping_bag;
      case OrderStatus.delivering:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return context.l10n.clientOrderTrackingMessagePending;
      case OrderStatus.accepted:
        return context.l10n.clientOrderTrackingMessageAccepted;
      case OrderStatus.preparing:
        return context.l10n.clientOrderTrackingMessagePreparing;
      case OrderStatus.ready:
        return _order.deliveryType == DeliveryType.delivery
            ? context.l10n.clientOrderTrackingMessageReadyDelivery
            : context.l10n.clientOrderTrackingMessageReadyPickup;
      case OrderStatus.pickedUp:
        return context.l10n.clientOrderTrackingMessagePickedUp;
      case OrderStatus.delivering:
        return context.l10n.clientOrderTrackingMessageDelivering;
      case OrderStatus.delivered:
        return context.l10n.clientOrderTrackingMessageDelivered;
      case OrderStatus.cancelled:
        return context.l10n.clientOrderTrackingMessageCancelled;
    }
  }

  bool _isStatusReached(OrderStatus status) {
    final currentIndex = OrderStatus.values.indexOf(_order.status);
    final targetIndex = OrderStatus.values.indexOf(status);
    return currentIndex >= targetIndex;
  }

  bool _canCancelOrder() {
    // Peut annuler si: pending ou accepted (pas encore en prÃƒÆ’Ã‚Â©paration)
    return _order.status == OrderStatus.pending ||
        _order.status == OrderStatus.accepted;
  }

  Future<void> _loadExistingReview() async {
    if (_order.status != OrderStatus.delivered) return;
    try {
      final review = await _orderRepository.getOrderReview(_order.id);
      if (!mounted) return;
      setState(() {
        _review = review;
      });
    } catch (_) {
      // Silence: absence d'avis ou endpoint indisponible
    }
  }

  Future<void> _showReviewSheet() async {
    var hanoutRating = _review?.hanoutRating ?? 5;
    var livreurRating = _review?.livreurRating ?? 5;
    final hanoutCommentController = TextEditingController(
      text: _review?.hanoutComment ?? '',
    );
    final livreurCommentController = TextEditingController(
      text: _review?.livreurComment ?? '',
    );
    final hasLivreur = _order.livreurId != null;

    final result = await showAppBottomSheet<bool>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              const SizedBox(height: AppSpacing.lg),
              SheetTitle(context.l10n.clientOrderTrackingRateOrder),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.clientOrdersHanoutRating,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    onPressed: () {
                      setSheetState(() {
                        hanoutRating = star;
                      });
                    },
                    icon: Icon(
                      star <= hanoutRating ? Icons.star : Icons.star_border,
                      color: AppColors.warning,
                    ),
                  );
                }),
              ),
              TextField(
                controller: hanoutCommentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: context.l10n.clientOrdersHanoutCommentHint,
                ),
              ),
              if (hasLivreur) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.clientOrdersDriverRating,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
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
              ],
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
          );
        },
      ),
    );

    if (result != true || !mounted) {
      hanoutCommentController.dispose();
      livreurCommentController.dispose();
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      final review = await _orderRepository.upsertOrderReview(
        orderId: _order.id,
        hanoutRating: hanoutRating,
        hanoutComment: hanoutCommentController.text.trim(),
        livreurRating: hasLivreur ? livreurRating : null,
        livreurComment: hasLivreur
            ? livreurCommentController.text.trim()
            : null,
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
      hanoutCommentController.dispose();
      livreurCommentController.dispose();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'cancel':
        _showCancelDialog();
        break;
      case 'contact':
        _callHanout();
        break;
    }
  }

  void _showCancelDialog() {
    showAppBottomSheet<void>(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpacing.lg),
          SheetTitle(context.l10n.clientOrderTrackingCancelOrder),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.clientOrderTrackingCancelConfirm,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.clientCommonNo),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isCancelling
                      ? null
                      : () async {
                    Navigator.of(context).pop();
                    await _cancelOrder();
                  },
                  child: Text(context.l10n.clientOrderTrackingCancelYes),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    if (_isCancelling) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      final cancelledOrder = await _orderRepository.cancelOrder(_order.id);
      if (!mounted) return;

      setState(() {
        _order = cancelledOrder;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.clientOrderTrackingCancelled),
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
          _isCancelling = false;
        });
      }
    }
  }

  void _callHanout() {
    _callPhone(
      phone: widget.hanoutPhone,
      fallbackMessage: context.l10n.clientOrderTrackingHanoutPhoneUnavailable,
    );
  }

  void _callLivreur() {
    _callPhone(
      phone: widget.livreurPhone,
      fallbackMessage: context.l10n.clientOrderTrackingDriverPhoneUnavailable,
    );
  }

  Future<void> _callPhone({
    required String? phone,
    required String fallbackMessage,
  }) async {
    final ok = await launchPhoneCall(phone);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fallbackMessage),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// Extension pour copyWith sur OrderModel (ÃƒÆ’Ã‚Â  ajouter dans order_model.dart)
extension OrderModelExtension on OrderModel {
  OrderModel copyWith({
    OrderStatus? status,
    DateTime? cancelledAt,
  }) {
    return OrderModel(
      id: id,
      clientId: clientId,
      hanoutId: hanoutId,
      livreurId: livreurId,
      freeTextOrder: freeTextOrder,
      items: items,
      status: status ?? this.status,
      deliveryType: deliveryType,
      paymentMethod: paymentMethod,
      deliveryFee: deliveryFee,
      totalAmount: totalAmount,
      clientAddress: clientAddress,
      clientLatitude: clientLatitude,
      clientLongitude: clientLongitude,
      notes: notes,
      createdAt: createdAt,
      acceptedAt: acceptedAt,
      readyAt: readyAt,
      pickedUpAt: pickedUpAt,
      deliveredAt: deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason,
    );
  }
}




