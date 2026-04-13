import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sevenouti/admin/data/admin_repository.dart';
import 'package:sevenouti/admin/models/admin_hanout_model.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/user_model.dart';
import 'package:sevenouti/core/constants/app_constrants.dart';
import 'package:sevenouti/core/widgets/app_widgets.dart';
import 'package:sevenouti/core/widgets/free_delivery_promo_badge.dart';
import 'package:sevenouti/utils/localized_formatters.dart';
import 'package:sevenouti/utils/phone_launcher.dart';

Future<void> showAdminHanoutInsightsDialog({
  required BuildContext context,
  required AdminHanoutModel hanout,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _AdminInsightsDialog(
      title: hanout.name,
      subtitle: hanout.address,
      phone: hanout.phone,
      icon: Icons.storefront,
      future: AdminRepository(ApiService()).getHanoutInsights(hanout.id),
      builder: (context, data) => _HanoutInsightsBody(data: data),
    ),
  );
}

Future<void> showAdminLivreurInsightsDialog({
  required BuildContext context,
  required UserModel livreur,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _AdminInsightsDialog(
      title: livreur.name,
      subtitle: livreur.phone,
      phone: livreur.phone,
      icon: Icons.delivery_dining,
      future: AdminRepository(ApiService()).getLivreurInsights(livreur.id),
      builder: (context, data) => _LivreurInsightsBody(data: data),
    ),
  );
}

class _AdminInsightsDialog extends StatelessWidget {
  const _AdminInsightsDialog({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.future,
    required this.builder,
    this.phone,
  });

  final String title;
  final String subtitle;
  final String? phone;
  final IconData icon;
  final Future<Map<String, dynamic>> future;
  final Widget Function(BuildContext context, Map<String, dynamic> data)
  builder;

  @override
  Widget build(BuildContext context) {
    final headerPhone = phone?.trim();
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1100,
          maxHeight: 780,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (headerPhone != null && headerPhone.isNotEmpty)
                    IconButton(
                      onPressed: () => launchPhoneCall(headerPhone),
                      icon: const Icon(Icons.phone),
                      tooltip: 'Appeler',
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LoadingView(
                      message: 'Chargement des détails...',
                    );
                  }

                  if (snapshot.hasError) {
                    return ErrorView(message: snapshot.error.toString());
                  }

                  final data = snapshot.data;
                  if (data == null) {
                    return const EmptyView(
                      message: 'Aucune donnée disponible',
                      icon: Icons.inbox_outlined,
                    );
                  }

                  return builder(context, data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HanoutInsightsBody extends StatelessWidget {
  const _HanoutInsightsBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final summary = _asMap(data['summary']);
    final orders = _asList(data['orders']);
    final ordersByStatus = _asMap(summary['ordersByStatus']);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _SummaryGrid(
          cards: [
            _MetricData(
              'Commandes',
              '${_int(summary['ordersTotal'])}',
              Icons.receipt_long,
            ),
            _MetricData(
              'Actives',
              '${_int(summary['activeOrders'])}',
              Icons.hourglass_top,
            ),
            _MetricData(
              'Livrées',
              '${_int(summary['deliveredOrders'])}',
              Icons.check_circle,
            ),
            _MetricData(
              'Annulées',
              '${_int(summary['cancelledOrders'])}',
              Icons.cancel,
            ),
            _MetricData(
              'Gains',
              _formatDh(summary['revenueDelivered']),
              Icons.payments,
            ),
            _MetricData(
              'Panier moyen',
              _formatDh(summary['averageOrderValue']),
              Icons.bar_chart,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _StatusSection(title: 'Statuts commandes', data: ordersByStatus),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: 'Historique commandes',
          child: orders.isEmpty
              ? const Text('Aucune commande')
              : Column(
                  children: orders
                      .map((item) => _OrderExpansionTile(order: _asMap(item)))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _LivreurInsightsBody extends StatelessWidget {
  const _LivreurInsightsBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final summary = _asMap(data['summary']);
    final orders = _asList(data['orders']);
    final gasRequests = _asList(data['gasRequests']);
    final ordersByStatus = _asMap(summary['ordersByStatus']);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _SummaryGrid(
          cards: [
            _MetricData(
              'Commandes',
              '${_int(summary['ordersTotal'])}',
              Icons.receipt_long,
            ),
            _MetricData(
              'Actives',
              '${_int(summary['activeOrders'])}',
              Icons.hourglass_top,
            ),
            _MetricData(
              'Livrées',
              '${_int(summary['deliveredOrders'])}',
              Icons.check_circle,
            ),
            _MetricData(
              'Historique gaz',
              '${_int(summary['gasRequestsTotal'])}',
              Icons.local_fire_department,
            ),
            _MetricData(
              'Total collecté',
              _formatDh(summary['totalCollected']),
              Icons.payments,
            ),
            _MetricData(
              'À reverser',
              _formatDh(summary['amountToTransfer']),
              Icons.account_balance_wallet,
            ),
            _MetricData(
              'Livr. gratuites',
              '${_int(summary['freeDeliveryPromoCompletedCount'])}',
              Icons.card_giftcard,
            ),
            _MetricData(
              'Remboursement',
              _formatDh(
                summary['freeDeliveryPromoPotentialReimbursementTotal'],
              ),
              Icons.savings,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _StatusSection(title: 'Statuts commandes', data: ordersByStatus),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: 'Historique livreur',
          child: orders.isEmpty
              ? const Text('Aucune commande')
              : Column(
                  children: orders
                      .map(
                        (item) => _OrderExpansionTile(
                          order: _asMap(item),
                          showHanout: true,
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: 'Historique gaz',
          child: gasRequests.isEmpty
              ? const Text('Aucune course gaz')
              : Column(
                  children: gasRequests
                      .map((item) => _GasExpansionTile(request: _asMap(item)))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.cards});

  final List<_MetricData> cards;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: cards
          .map(
            (card) => Container(
              width: 220,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.medium,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(card.icon, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.label,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.value,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.title,
    required this.data,
  });

  final String title;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: data.entries
            .map(
              (entry) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.round,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${_orderStatusLabel(entry.key)}: ${_int(entry.value)}',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _OrderExpansionTile extends StatelessWidget {
  const _OrderExpansionTile({
    required this.order,
    this.showHanout = false,
  });

  final Map<String, dynamic> order;
  final bool showHanout;

  @override
  Widget build(BuildContext context) {
    final client = _asMap(order['client']);
    final livreur = _asMap(order['livreur']);
    final hanout = _asMap(order['hanout']);
    final totalAmount = _double(order['totalAmount']);
    final createdAt = _date(order['createdAt']);
    final processingMode = '${order['processingMode'] ?? 'HANOUT'}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        title: Text(
          '#${_shortId(order['id'])} - ${_orderStatusLabel(order['status'])}',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${client['nameFr'] ?? client['name'] ?? '-'} • ${_formatDate(createdAt)}',
          style: AppTextStyles.caption,
        ),
        trailing: totalAmount != null
            ? Text(
                formatDh(context, totalAmount),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
        children: [
          if (_bool(order['freeDeliveryPromoApplied']))
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: FreeDeliveryPromoBadge(compact: true),
            ),
          if (_bool(order['freeDeliveryPromoApplied']))
            const SizedBox(height: AppSpacing.sm),
          _detailRow('Contenu', '${order['freeTextOrder'] ?? '-'}'),
          if (showHanout) _detailRow('Hanout', '${hanout['name'] ?? '-'}'),
          _detailRow('Client', '${client['nameFr'] ?? client['name'] ?? '-'}'),
          _phoneDetailRow('Téléphone client', client['phone']?.toString()),
          if (livreur.isNotEmpty)
            _detailRow(
              'Livreur',
              '${livreur['nameFr'] ?? livreur['name'] ?? '-'}',
            ),
          if (livreur.isNotEmpty)
            _phoneDetailRow(
              'Téléphone livreur',
              livreur['phone']?.toString(),
            ),
          if (showHanout)
            _phoneDetailRow(
              'Téléphone hanout',
              hanout['phone']?.toString(),
            ),
          _detailRow('Type', _deliveryTypeLabel(order['deliveryType'])),
          _detailRow('Paiement', _paymentMethodLabel(order['paymentMethod'])),
          _detailRow('Flux', _processingModeLabel(processingMode)),
          if (order['clientAddressFr'] != null ||
              order['clientAddressAr'] != null ||
              order['clientAddress'] != null)
            _detailRow(
              'Adresse',
              '${order['clientAddressFr'] ?? order['clientAddressAr'] ?? order['clientAddress'] ?? '-'}',
            ),
          if (order['notes'] != null && '${order['notes']}'.trim().isNotEmpty)
            _detailRow('Notes', '${order['notes']}'),
          if (order['latestDeliveryRequestStatus'] != null)
            _detailRow(
              'Demande livreur',
              '${order['latestDeliveryRequestStatus']}',
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Historique statut',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _timelineRow('Créée', _date(order['createdAt'])),
          _timelineRow('Acceptée', _date(order['acceptedAt'])),
          _timelineRow('Prête', _date(order['readyAt'])),
          _timelineRow('Récupérée', _date(order['pickedUpAt'])),
          _timelineRow('Livrée', _date(order['deliveredAt'])),
          _timelineRow('Annulée', _date(order['cancelledAt'])),
          if (order['cancellationReason'] != null &&
              '${order['cancellationReason']}'.trim().isNotEmpty)
            _detailRow('Motif annulation', '${order['cancellationReason']}'),
        ],
      ),
    );
  }
}

class _GasExpansionTile extends StatelessWidget {
  const _GasExpansionTile({required this.request});

  final Map<String, dynamic> request;

  @override
  Widget build(BuildContext context) {
    final client = _asMap(request['client']);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        title: Text(
          'Gaz - ${_gasStatusLabel(request['status'])}',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${client['nameFr'] ?? client['name'] ?? '-'} • ${_formatDate(_date(request['createdAt']))}',
          style: AppTextStyles.caption,
        ),
        trailing: Text(
          formatDh(context, _double(request['price']) ?? 0),
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        children: [
          _detailRow('Client', '${client['nameFr'] ?? client['name'] ?? '-'}'),
          _phoneDetailRow('Téléphone client', client['phone']?.toString()),
          _detailRow('Adresse', '${request['clientAddress'] ?? '-'}'),
          if (request['notes'] != null &&
              '${request['notes']}'.trim().isNotEmpty)
            _detailRow('Notes', '${request['notes']}'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Historique statut',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _timelineRow('Créée', _date(request['createdAt'])),
          _timelineRow('Acceptée', _date(request['acceptedAt'])),
          _timelineRow('Arrivée', _date(request['arrivedAt'])),
          _timelineRow('Récupérée', _date(request['pickedUpAt'])),
          _timelineRow('Au hanout', _date(request['atHanoutAt'])),
          _timelineRow('Retour', _date(request['returnHomeAt'])),
          _timelineRow('Livrée', _date(request['deliveredAt'])),
          _timelineRow('Annulée', _date(request['cancelledAt'])),
        ],
      ),
    );
  }
}

Widget _detailRow(String label, String value, {Widget? trailing}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.bodySmall),
        ),
        if (trailing != null) trailing,
      ],
    ),
  );
}

Widget _phoneDetailRow(String label, String? phone) {
  final value = phone?.trim();
  return _detailRow(
    label,
    value == null || value.isEmpty ? '-' : value,
    trailing: _hasPhone(value)
        ? IconButton(
            onPressed: () => launchPhoneCall(value),
            icon: const Icon(Icons.phone, size: 18),
            tooltip: 'Appeler',
          )
        : null,
  );
}

Widget _timelineRow(String label, DateTime? value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          _formatDate(value),
          style: AppTextStyles.caption,
        ),
      ],
    ),
  );
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  return {};
}

List<dynamic> _asList(dynamic value) {
  if (value is List<dynamic>) return value;
  return const [];
}

int _int(dynamic value) => (value as num?)?.toInt() ?? 0;

double? _double(dynamic value) => (value as num?)?.toDouble();

bool _bool(dynamic value) => value as bool? ?? false;

DateTime? _date(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String _shortId(dynamic id) {
  final value = '$id';
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}

String _formatDh(dynamic value) {
  final number = (value as num?)?.toDouble() ?? 0;
  return '${number.toStringAsFixed(2)} DH';
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
}

bool _hasPhone(String? value) => value != null && value.trim().isNotEmpty;

String _orderStatusLabel(dynamic status) {
  switch ('$status'.toUpperCase()) {
    case 'PENDING':
      return 'En attente';
    case 'ACCEPTED':
      return 'Acceptée';
    case 'READY':
      return 'Prête';
    case 'PICKED_UP':
      return 'Récupérée';
    case 'DELIVERING':
      return 'En livraison';
    case 'DELIVERED':
      return 'Livrée';
    case 'CANCELLED':
      return 'Annulée';
    default:
      return '$status';
  }
}

String _gasStatusLabel(dynamic status) {
  switch ('$status'.toUpperCase()) {
    case 'PENDING':
      return 'En attente';
    case 'ACCEPTED':
      return 'Acceptée';
    case 'ARRIVE':
      return 'Arrivé';
    case 'RECUPERE_VIDE':
      return 'Vide récupérée';
    case 'VA_AU_HANOUT':
      return 'Vers hanout';
    case 'RETOUR_MAISON':
      return 'Retour maison';
    case 'LIVRE':
      return 'Livrée';
    case 'CANCELLED':
      return 'Annulée';
    default:
      return '$status';
  }
}

String _deliveryTypeLabel(dynamic value) {
  return '$value'.toUpperCase() == 'PICKUP' ? 'Collecte' : 'Livraison';
}

String _paymentMethodLabel(dynamic value) {
  return '$value'.toUpperCase() == 'CARNET' ? 'Carnet' : 'Cash';
}

String _processingModeLabel(String value) {
  return value.toUpperCase() == 'DIRECT_LIVREUR' ? 'Direct livreur' : 'Hanout';
}
