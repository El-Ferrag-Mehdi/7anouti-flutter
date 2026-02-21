import 'package:flutter/widgets.dart';
import 'package:sevenouti/client/l10n/client_l10n.dart';
import 'package:sevenouti/client/models/gas_service_order.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/l10n/l10n.dart';

extension LivreurL10nX on BuildContext {
  String livreurOrderStatusLabel(OrderStatus status) => orderStatusLabel(status);

  String livreurDeliveryTypeLabel(DeliveryType type) => deliveryTypeLabel(type);
  String livreurGasStatusLabel(GasServiceStatus status) => gasStatusLabel(status);

  String livreurRequestStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return l10n.livreurRequestStatusAccepted;
      case 'REJECTED':
        return l10n.livreurRequestStatusRejected;
      case 'PENDING':
      default:
        return l10n.livreurRequestStatusPending;
    }
  }

  String livreurGasActionLabel(GasServiceStatus status) {
    switch (status) {
      case GasServiceStatus.arrive:
        return l10n.livreurGasActionArrived;
      case GasServiceStatus.recupereVide:
        return l10n.livreurGasActionPickedBottle;
      case GasServiceStatus.vaAuHanout:
        return l10n.livreurGasActionToHanout;
      case GasServiceStatus.retourMaison:
        return l10n.livreurGasActionReturnHome;
      case GasServiceStatus.livre:
        return l10n.livreurGasActionDelivered;
      case GasServiceStatus.pending:
      case GasServiceStatus.enRoute:
      case GasServiceStatus.cancelled:
      case GasServiceStatus.rejected:
        return l10n.livreurGasActionUpdate;
    }
  }
}
