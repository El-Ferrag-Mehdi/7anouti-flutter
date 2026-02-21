import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/cubit/hanout_details_state.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/models.dart';
import 'package:sevenouti/client/repository/repositories.dart';

/// Cubit pour gérer la page de détails du hanout
class HanoutDetailsCubit extends Cubit<HanoutDetailsState> {
  HanoutDetailsCubit({
    required HanoutWithDistance hanout,
    required HanoutRepository hanoutRepository,
    required OrderRepository orderRepository,
    required CarnetRepository carnetRepository,
  }) : _hanout = hanout,
       _hanoutRepository = hanoutRepository,
       _orderRepository = orderRepository,
       _carnetRepository = carnetRepository,
       super(const HanoutDetailsInitial());

  final HanoutWithDistance _hanout;
  final HanoutRepository _hanoutRepository;
  final OrderRepository _orderRepository;
  final CarnetRepository _carnetRepository;

  /// Initialise la page
  Future<void> initialize() async {
    emit(const HanoutDetailsLoading());

    try {
      // Récupère les produits et catégories
      final products = await _hanoutRepository.getHanoutProducts(_hanout.id);
      final categories = await _hanoutRepository.getHanoutCategories(
        _hanout.id,
      );

      // Vérifie si le client a un carnet avec ce hanout
      CarnetModel? carnet;
      var canUseCarnet = false;

      if (_hanout.hasCarnet) {
        try {
          carnet = await _carnetRepository.getCarnet(_hanout.id);
          canUseCarnet = carnet?.isActive ?? false;
        } catch (e) {
          // Pas de carnet existant, c'est normal
          canUseCarnet = false;
        }
      }

      emit(
        HanoutDetailsLoaded(
          hanout: _hanout,
          freeTextOrder: '',
          deliveryType: DeliveryType.delivery, // Par défaut: livraison
          paymentMethod: PaymentMethod.cash, // Par défaut: espèces
          products: products,
          categories: categories,
          carnet: carnet,
          canUseCarnet: canUseCarnet,
        ),
      );
    } on ApiException catch (e) {
      emit(HanoutDetailsError(message: e.message));
    } catch (e) {
      emit(
        HanoutDetailsError(
          message: e.toString(),
        ),
      );
    }
  }

  /// Met à jour le texte de la commande
  void updateOrderText(String text) {
    final currentState = state;
    if (currentState is HanoutDetailsLoaded) {
      emit(currentState.copyWith(freeTextOrder: text));
    }
  }

  /// Change le type de livraison
  void changeDeliveryType(DeliveryType type) {
    final currentState = state;
    if (currentState is HanoutDetailsLoaded) {
      emit(currentState.copyWith(deliveryType: type));
    }
  }

  /// Change le mode de paiement
  void changePaymentMethod(PaymentMethod method) {
    final currentState = state;
    if (currentState is HanoutDetailsLoaded) {
      // Si le client choisit carnet mais n'a pas de carnet actif
      if (method == PaymentMethod.carnet && !currentState.canUseCarnet) {
        emit(
          HanoutDetailsError(
            message: 'Vous devez d\'abord activer le carnet avec ce hanout',
            previousState: currentState,
          ),
        );
        return;
      }

      emit(currentState.copyWith(paymentMethod: method));
    }
  }

  /// Ajoute un produit au texte de commande
  void addProductToOrder(ProductModel product) {
    final currentState = state;
    if (currentState is HanoutDetailsLoaded) {
      final currentText = currentState.freeTextOrder;
      final newText = currentText.isEmpty
          ? product.name
          : '$currentText\n${product.name}';

      emit(currentState.copyWith(freeTextOrder: newText));
    }
  }

  /// Soumet la commande
  Future<void> submitOrder({
    String? clientAddress,
    String? clientAddressFr,
    String? clientAddressAr,
    double? clientLatitude,
    double? clientLongitude,
    String? notes,
  }) async {
    final currentState = state;
    if (currentState is! HanoutDetailsLoaded) return;

    if (!currentState.canSubmitOrder) {
      emit(
        HanoutDetailsError(
          message: 'Veuillez saisir votre commande',
          previousState: currentState,
        ),
      );
      return;
    }

    emit(const HanoutDetailsSubmitting());

    try {
      final order = await _orderRepository.createOrder(
        hanoutId: _hanout.id,
        freeTextOrder: currentState.freeTextOrder,
        deliveryType: currentState.deliveryType,
        paymentMethod: currentState.paymentMethod,
        clientAddress: clientAddress,
        clientAddressFr: clientAddressFr,
        clientAddressAr: clientAddressAr,
        clientLatitude: clientLatitude,
        clientLongitude: clientLongitude,
        notes: notes,
      );

      emit(
        HanoutDetailsOrderSuccess(
          order: order,
          hanoutPhone: _hanout.phone,
        ),
      );
    } on ApiException catch (e) {
      emit(
        HanoutDetailsError(
          message: e.message,
          previousState: currentState,
        ),
      );
    } catch (e) {
      emit(
        HanoutDetailsError(
          message: e.toString(),
          previousState: currentState,
        ),
      );
    }
  }

  /// Demande l'activation du carnet
  Future<void> requestCarnetActivation() async {
    final currentState = state;
    if (currentState is! HanoutDetailsLoaded) return;

    try {
      await _carnetRepository.requestCarnetActivation(_hanout.id);

      emit(
        HanoutDetailsError(
          message: 'Demande envoyée! Le hanout va examiner votre demande.',
          previousState: currentState,
        ),
      );
    } on ApiException catch (e) {
      emit(
        HanoutDetailsError(
          message: e.message,
          previousState: currentState,
        ),
      );
    } catch (e) {
      emit(
        HanoutDetailsError(
          message: e.toString(),
          previousState: currentState,
        ),
      );
    }
  }

  /// Efface l'erreur et retourne à l'état précédent
  void clearError() {
    final currentState = state;
    if (currentState is HanoutDetailsError &&
        currentState.previousState != null) {
      emit(currentState.previousState!);
    }
  }

  /// VERSION MOCK pour tester sans API
  Future<void> initializeMock() async {
    emit(const HanoutDetailsLoading());

    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Produits mock
    final mockProducts = [
      ProductModel(
        id: '1',
        name: 'Pain',
        description: 'Pain frais du jour',
        price: 3.0,
        image: null,
        categoryId: '1',
        hanoutId: _hanout.id,
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: '2',
        name: 'Lait',
        description: 'Lait frais 1L',
        price: 8.0,
        image: null,
        categoryId: '2',
        hanoutId: _hanout.id,
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: '3',
        name: 'Œufs',
        description: 'Boîte de 6',
        price: 15.0,
        image: null,
        categoryId: '2',
        hanoutId: _hanout.id,
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: '4',
        name: 'Eau minérale',
        description: 'Pack de 6x1.5L',
        price: 25.0,
        image: null,
        categoryId: '3',
        hanoutId: _hanout.id,
        isAvailable: true,
        createdAt: DateTime.now(),
      ),
    ];

    // Catégories mock
    final mockCategories = [
      const CategoryModel(id: '1', name: 'Boulangerie', icon: '🥖'),
      const CategoryModel(id: '2', name: 'Produits laitiers', icon: '🥛'),
      const CategoryModel(id: '3', name: 'Boissons', icon: '💧'),
      const CategoryModel(id: '4', name: 'Épicerie', icon: '🛒'),
    ];

    // Carnet mock (si le hanout l'accepte)
    CarnetModel? mockCarnet;
    var canUseCarnet = false;

    if (_hanout.hasCarnet) {
      mockCarnet = CarnetModel(
        id: 'carnet1',
        clientId: 'client1',
        hanoutId: _hanout.id,
        balance: 50.0, // Dette de 50 DH
        isActive: true,
        activatedAt: DateTime.now().subtract(const Duration(days: 30)),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );
      canUseCarnet = true;
    }

    emit(
      HanoutDetailsLoaded(
        hanout: _hanout,
        freeTextOrder: '',
        deliveryType: DeliveryType.delivery,
        paymentMethod: PaymentMethod.cash,
        products: mockProducts,
        categories: mockCategories,
        carnet: mockCarnet,
        canUseCarnet: canUseCarnet,
      ),
    );
  }

  /// VERSION MOCK pour soumettre une commande
  Future<void> submitOrderMock({
    String? clientAddress,
    double? clientLatitude,
    double? clientLongitude,
  }) async {
    final currentState = state;
    if (currentState is! HanoutDetailsLoaded) return;

    if (!currentState.canSubmitOrder) {
      emit(
        HanoutDetailsError(
          message: 'Veuillez saisir votre commande',
          previousState: currentState,
        ),
      );
      return;
    }

    emit(const HanoutDetailsSubmitting());

    // Simule un délai réseau
    await Future<void>.delayed(const Duration(seconds: 1));

    // Crée une commande fictive
    final mockOrder = OrderModel(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}',
      clientId: 'client1',
      hanoutId: _hanout.id,
      freeTextOrder: currentState.freeTextOrder,
      status: OrderStatus.pending,
      deliveryType: currentState.deliveryType,
      paymentMethod: currentState.paymentMethod,
      deliveryFee: currentState.deliveryType == DeliveryType.delivery ? 7.0 : 0,
      clientAddress: clientAddress ?? 'Adresse du client',
      clientLatitude: clientLatitude ?? 33.5731,
      clientLongitude: clientLongitude ?? -7.5898,
      createdAt: DateTime.now(),
    );

    emit(
      HanoutDetailsOrderSuccess(
        order: mockOrder,
        hanoutPhone: _hanout.phone,
      ),
    );
  }
}
