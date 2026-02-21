import 'package:flutter/widgets.dart';
import 'package:sevenouti/client/l10n/client_l10n.dart';
import 'package:sevenouti/client/models/order_model.dart';

extension HanoutL10nX on BuildContext {
  String hanoutOrderStatusLabel(OrderStatus status) => orderStatusLabel(status);

  String hanoutDeliveryTypeLabel(DeliveryType type) => deliveryTypeLabel(type);

  String hanoutPaymentMethodLabel(PaymentMethod method) =>
      paymentMethodLabel(method);
}
