import 'package:flutter/widgets.dart';
import 'package:sevenouti/client/models/gas_service_order.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/l10n/l10n.dart';

extension ClientL10nX on BuildContext {
  String orderStatusLabel(OrderStatus status) {
    final l10n = this.l10n;
    switch (status) {
      case OrderStatus.pending:
        return l10n.clientOrderStatusPending;
      case OrderStatus.accepted:
        return l10n.clientOrderStatusAccepted;
      case OrderStatus.preparing:
        return l10n.clientOrderStatusPreparing;
      case OrderStatus.ready:
        return l10n.clientOrderStatusReady;
      case OrderStatus.pickedUp:
        return l10n.clientOrderStatusPickedUp;
      case OrderStatus.delivering:
        return l10n.clientOrderStatusDelivering;
      case OrderStatus.delivered:
        return l10n.clientOrderStatusDelivered;
      case OrderStatus.cancelled:
        return l10n.clientOrderStatusCancelled;
    }
  }

  String deliveryTypeLabel(DeliveryType type) {
    switch (type) {
      case DeliveryType.pickup:
        return l10n.clientDeliveryPickup;
      case DeliveryType.delivery:
        return l10n.clientDeliveryDelivery;
    }
  }

  String paymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return l10n.clientPaymentCash;
      case PaymentMethod.carnet:
        return l10n.clientPaymentCarnet;
    }
  }

  String gasStatusLabel(GasServiceStatus status) {
    final l10n = this.l10n;
    switch (status) {
      case GasServiceStatus.pending:
        return l10n.clientGasStatusPending;
      case GasServiceStatus.enRoute:
        return l10n.clientGasStatusEnRoute;
      case GasServiceStatus.arrive:
        return l10n.clientGasStatusArrive;
      case GasServiceStatus.recupereVide:
        return l10n.clientGasStatusPickedEmpty;
      case GasServiceStatus.vaAuHanout:
        return l10n.clientGasStatusToHanout;
      case GasServiceStatus.retourMaison:
        return l10n.clientGasStatusReturnHome;
      case GasServiceStatus.livre:
        return l10n.clientGasStatusDelivered;
      case GasServiceStatus.cancelled:
        return l10n.clientGasStatusCancelled;
      case GasServiceStatus.rejected:
        return l10n.clientGasStatusRejected;
    }
  }

  String gasStatusMessage(GasServiceStatus status) {
    final l10n = this.l10n;
    switch (status) {
      case GasServiceStatus.pending:
        return l10n.clientGasMessagePending;
      case GasServiceStatus.enRoute:
        return l10n.clientGasMessageEnRoute;
      case GasServiceStatus.arrive:
        return l10n.clientGasMessageArrive;
      case GasServiceStatus.recupereVide:
        return l10n.clientGasMessagePickedEmpty;
      case GasServiceStatus.vaAuHanout:
        return l10n.clientGasMessageToHanout;
      case GasServiceStatus.retourMaison:
        return l10n.clientGasMessageReturnHome;
      case GasServiceStatus.livre:
        return l10n.clientGasMessageDelivered;
      case GasServiceStatus.cancelled:
        return l10n.clientGasMessageCancelled;
      case GasServiceStatus.rejected:
        return l10n.clientGasMessageRejected;
    }
  }
}
