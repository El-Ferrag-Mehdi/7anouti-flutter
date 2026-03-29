import 'package:flutter/widgets.dart';
import 'package:sevenouti/client/l10n/client_l10n.dart';
import 'package:sevenouti/client/models/order_model.dart';

extension HanoutL10nX on BuildContext {
  String hanoutOrderStatusLabel(
    OrderStatus status, {
    OrderProcessingMode processingMode = OrderProcessingMode.hanout,
  }) => orderStatusLabel(status, processingMode: processingMode);

  String hanoutDeliveryTypeLabel(DeliveryType type) => deliveryTypeLabel(type);

  String hanoutPaymentMethodLabel(PaymentMethod method) =>
      paymentMethodLabel(method);
}
