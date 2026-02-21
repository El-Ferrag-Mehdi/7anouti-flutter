import 'package:equatable/equatable.dart';
import 'package:sevenouti/client/models/models.dart';

/// États de la page de détails du hanout
abstract class HanoutDetailsState extends Equatable {
  const HanoutDetailsState();

  @override
  List<Object?> get props => [];
}

/// État initial
class HanoutDetailsInitial extends HanoutDetailsState {
  const HanoutDetailsInitial();
}

/// État de chargement des produits/catégories
class HanoutDetailsLoading extends HanoutDetailsState {
  const HanoutDetailsLoading();
}

/// État chargé avec données
class HanoutDetailsLoaded extends HanoutDetailsState {
  const HanoutDetailsLoaded({
    required this.hanout,
    required this.freeTextOrder,
    required this.deliveryType,
    required this.paymentMethod,
    this.products = const [],
    this.categories = const [],
    this.carnet,
    this.canUseCarnet = false,
  });

  final HanoutWithDistance hanout;
  final String freeTextOrder; // Texte de la commande
  final DeliveryType deliveryType;
  final PaymentMethod paymentMethod;
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final CarnetModel? carnet;
  final bool canUseCarnet;

  @override
  List<Object?> get props => [
        hanout,
        freeTextOrder,
        deliveryType,
        paymentMethod,
        products,
        categories,
        carnet,
        canUseCarnet,
      ];

  /// Copie avec modifications
  HanoutDetailsLoaded copyWith({
    HanoutWithDistance? hanout,
    String? freeTextOrder,
    DeliveryType? deliveryType,
    PaymentMethod? paymentMethod,
    List<ProductModel>? products,
    List<CategoryModel>? categories,
    CarnetModel? carnet,
    bool? canUseCarnet,
  }) {
    return HanoutDetailsLoaded(
      hanout: hanout ?? this.hanout,
      freeTextOrder: freeTextOrder ?? this.freeTextOrder,
      deliveryType: deliveryType ?? this.deliveryType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      carnet: carnet ?? this.carnet,
      canUseCarnet: canUseCarnet ?? this.canUseCarnet,
    );
  }

  /// Vérifie si la commande peut être validée
  bool get canSubmitOrder {
    return freeTextOrder.trim().isNotEmpty;
  }

  /// Vérifie si le carnet peut être utilisé
  bool get isCarnetPaymentAllowed {
    return canUseCarnet && 
           paymentMethod == PaymentMethod.carnet &&
           hanout.hasCarnet;
  }
}

/// État de soumission de commande en cours
class HanoutDetailsSubmitting extends HanoutDetailsState {
  const HanoutDetailsSubmitting();
}

/// État de succès après soumission
class HanoutDetailsOrderSuccess extends HanoutDetailsState {
  const HanoutDetailsOrderSuccess({
    required this.order,
    required this.hanoutPhone,
  });

  final OrderModel order;
  final String hanoutPhone;

  @override
  List<Object?> get props => [order, hanoutPhone];
}

/// État d'erreur
class HanoutDetailsError extends HanoutDetailsState {
  const HanoutDetailsError({
    required this.message,
    this.previousState,
  });

  final String message;
  final HanoutDetailsState? previousState;

  @override
  List<Object?> get props => [message, previousState];
}
