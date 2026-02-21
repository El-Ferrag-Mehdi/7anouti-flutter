// ============================================
// REPOSITORIES COMPLETS - API RÉELLES (CORRIGÉ)
// Remplace le fichier lib/core/services/repositories.dart par celui-ci
// ============================================

import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/models.dart';

// ============================================
// HANOUT REPOSITORY
// ============================================

class HanoutRepository {
  HanoutRepository(this._apiService);

  final ApiService _apiService;

  /// Récupère les hanouts proches d'une position
  Future<List<HanoutWithDistance>> getNearbyHanouts({
    required double latitude,
    required double longitude,
    double radius = 500,
  }) async {
    final dynamic response = await _apiService.get(
      '/hanouts/nearby?latitude=$latitude&longitude=$longitude&radius=$radius',
    );

    // Cast explicite en Map
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> hanoutsJson = responseMap['data'] as List<dynamic>;

    return hanoutsJson.map((dynamic jsonItem) {
      final Map<String, dynamic> json = jsonItem as Map<String, dynamic>;

      return HanoutWithDistance(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        address: json['address'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        phone: json['phone'] as String,
        image: json['image'] as String?,
        isOpen: json['isOpen'] as bool,
        showRating: json['showRating'] as bool? ?? true,
        hasCarnet: json['hasCarnet'] as bool,
        deliveryFee: json['deliveryFee'] != null
            ? (json['deliveryFee'] as num).toDouble()
            : null,
        estimatedDeliveryTime: json['estimatedDeliveryTime'] as int?,
        rating: json['rating'] != null
            ? (json['rating'] as num).toDouble()
            : null,
        totalOrders: json['totalOrders'] as int?,
        ownerId: json['ownerId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        // updatedAt: DateTime.parse(json['updatedAt'] as String),
        // CORRECTION: distanceInMeters au lieu de distance
        distanceInMeters: json['distance'] != null
            ? (json['distance'] as num).toDouble()
            : 0,
      );
    }).toList();
  }

  /// Récupère un hanout par ID
  Future<HanoutModel> getHanoutById(String hanoutId) async {
    final dynamic response = await _apiService.get('/hanouts/$hanoutId');
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final Map<String, dynamic> json =
        responseMap['data'] as Map<String, dynamic>;

    return HanoutModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String,
      image: json['image'] as String?,
      isOpen: json['isOpen'] as bool,
      showRating: json['showRating'] as bool? ?? true,
      hasCarnet: json['hasCarnet'] as bool,
      deliveryFee: json['deliveryFee'] != null
          ? (json['deliveryFee'] as num).toDouble()
          : null,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] as int?,
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      totalOrders: json['totalOrders'] as int?,
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      // updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Récupère les produits d'un hanout
  Future<List<ProductModel>> getHanoutProducts(String hanoutId) async {
    final dynamic response = await _apiService.get(
      '/hanouts/$hanoutId/products',
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> productsJson = responseMap['data'] as List<dynamic>;

    return productsJson.map((dynamic jsonItem) {
      final Map<String, dynamic> json = jsonItem as Map<String, dynamic>;

      return ProductModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: json['price'] != null ? (json['price'] as num).toDouble() : null,
        image: json['image'] as String?,
        categoryId: json['categoryId'] as String?,
        hanoutId: json['hanoutId'] as String,
        isAvailable: json['isAvailable'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
    }).toList();
  }

  /// Récupère les catégories d'un hanout
  Future<List<CategoryModel>> getHanoutCategories(String hanoutId) async {
    final dynamic response = await _apiService.get(
      '/hanouts/$hanoutId/categories',
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> categoriesJson = responseMap['data'] as List<dynamic>;

    return categoriesJson.map((dynamic jsonItem) {
      final Map<String, dynamic> json = jsonItem as Map<String, dynamic>;

      return CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String?,
      );
    }).toList();
  }
}

// ============================================
// ORDER REPOSITORY
// ============================================

class OrderRepository {
  OrderRepository(this._apiService);

  final ApiService _apiService;

  /// Crée une nouvelle commande
  Future<OrderModel> createOrder({
    required String hanoutId,
    required String freeTextOrder,
    required DeliveryType deliveryType,
    required PaymentMethod paymentMethod,
    String? clientAddress,
    String? clientAddressFr,
    String? clientAddressAr,
    double? clientLatitude,
    double? clientLongitude,
    List<Map<String, dynamic>>? items, // CORRECTION: Type explicite
    String? notes,
  }) async {
    final Map<String, dynamic> body = {
      'hanoutId': hanoutId,
      'freeTextOrder': freeTextOrder,
      'deliveryType': deliveryType.value,
      'paymentMethod': paymentMethod.value,
    };

    if (clientAddress != null) body['clientAddress'] = clientAddress;
    if (clientAddressFr != null) body['clientAddressFr'] = clientAddressFr;
    if (clientAddressAr != null) body['clientAddressAr'] = clientAddressAr;
    if (clientLatitude != null) body['clientLatitude'] = clientLatitude;
    if (clientLongitude != null) body['clientLongitude'] = clientLongitude;
    if (notes != null) body['notes'] = notes;
    if (items != null) body['items'] = items;

    final dynamic response = await _apiService.post('/orders', body: body);
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;

    return _parseOrder(responseMap['data'] as Map<String, dynamic>);
  }

  /// Récupère une commande par ID
  Future<OrderModel> getOrderById(String orderId) async {
    final dynamic response = await _apiService.get('/orders/$orderId');
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;

    return _parseOrder(responseMap['data'] as Map<String, dynamic>);
  }

  /// Récupère les commandes du client
  Future<List<OrderModel>> getClientOrders({
    String? status,
    int limit = 50,
  }) async {
    String endpoint = '/orders/my-orders?limit=$limit';
    if (status != null) {
      endpoint += '&status=$status';
    }

    final dynamic response = await _apiService.get(endpoint);
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> ordersJson = responseMap['data'] as List<dynamic>;

    return ordersJson.map((dynamic jsonItem) {
      return _parseOrder(jsonItem as Map<String, dynamic>);
    }).toList();
  }

  /// Annule une commande
  Future<OrderModel> cancelOrder(String orderId, {String? reason}) async {
    final Map<String, dynamic>? body = reason != null
        ? {'reason': reason}
        : null;

    final dynamic response = await _apiService.put(
      '/orders/$orderId/cancel',
      body: body,
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;

    return _parseOrder(responseMap['data'] as Map<String, dynamic>);
  }

  /// Met à jour le statut d'une commande
  Future<OrderModel> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    final dynamic response = await _apiService.put(
      '/orders/$orderId/status',
      body: {'status': status.value},
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;

    return _parseOrder(responseMap['data'] as Map<String, dynamic>);
  }

  Future<ReviewModel?> getOrderReview(String orderId) async {
    final dynamic response = await _apiService.get('/orders/$orderId/review');
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final dynamic data = responseMap['data'];
    if (data == null) return null;
    return ReviewModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ReviewModel> upsertOrderReview({
    required String orderId,
    required int hanoutRating,
    String? hanoutComment,
    int? livreurRating,
    String? livreurComment,
  }) async {
    final Map<String, dynamic> body = {
      'hanoutRating': hanoutRating,
      if (hanoutComment != null && hanoutComment.trim().isNotEmpty)
        'hanoutComment': hanoutComment.trim(),
      if (livreurRating != null) 'livreurRating': livreurRating,
      if (livreurComment != null && livreurComment.trim().isNotEmpty)
        'livreurComment': livreurComment.trim(),
    };
    final dynamic response = await _apiService.post(
      '/orders/$orderId/review',
      body: body,
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return ReviewModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }

  /// Parse JSON vers OrderModel
  OrderModel _parseOrder(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      hanoutId: json['hanoutId'] as String,
      livreurId: json['livreurId'] as String?,
      freeTextOrder: json['freeTextOrder'] as String,
      status: OrderStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      deliveryType: DeliveryType.values.firstWhere(
        (e) => e.value == json['deliveryType'],
        orElse: () => DeliveryType.delivery,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.value == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      deliveryFee: json['deliveryFee'] != null
          ? (json['deliveryFee'] as num).toDouble()
          : null,
      totalAmount: json['totalAmount'] != null
          ? (json['totalAmount'] as num).toDouble()
          : null,
      clientAddress: json['clientAddress'] as String?,
      clientAddressFr: json['clientAddressFr'] as String?,
      clientAddressAr: json['clientAddressAr'] as String?,
      clientLatitude: json['clientLatitude'] != null
          ? (json['clientLatitude'] as num).toDouble()
          : null,
      clientLongitude: json['clientLongitude'] != null
          ? (json['clientLongitude'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      readyAt: json['readyAt'] != null
          ? DateTime.parse(json['readyAt'] as String)
          : null,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.parse(json['pickedUpAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      // Items are optional
      items: json['items'] != null
          ? (json['items'] as List<dynamic>).map((dynamic itemJson) {
              final Map<String, dynamic> item =
                  itemJson as Map<String, dynamic>;
              return OrderItem(
                productId: item['productId'] as String,
                productName: item['productName'] as String,
                quantity: item['quantity'] as int,
                unitPrice: item['unitPrice'] != null
                    ? (item['unitPrice'] as num).toDouble()
                    : null,
                totalPrice: item['totalPrice'] != null
                    ? (item['totalPrice'] as num).toDouble()
                    : null,
              );
            }).toList()
          : null,
    );
  }
}

// ============================================
// CARNET REPOSITORY
// ============================================

class CarnetRepository {
  CarnetRepository(this._apiService);

  final ApiService _apiService;

  /// Récupère le carnet avec un hanout spécifique
  Future<CarnetModel> getCarnet(String hanoutId) async {
    final dynamic response = await _apiService.get('/carnet/hanout/$hanoutId');
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;

    return _parseCarnet(responseMap['data'] as Map<String, dynamic>);
  }

  /// Récupère tous les carnets du client
  Future<List<CarnetModel>> getAllCarnets() async {
    final dynamic response = await _apiService.get('/carnet/my-carnets');
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> carnetsJson = responseMap['data'] as List<dynamic>;

    return carnetsJson.map((dynamic jsonItem) {
      return _parseCarnet(jsonItem as Map<String, dynamic>);
    }).toList();
  }

  /// Récupère les transactions d'un carnet
  Future<List<CarnetTransactionModel>> getCarnetTransactions(
    String carnetId,
  ) async {
    final dynamic response = await _apiService.get(
      '/carnet/$carnetId/transactions',
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> transactionsJson = responseMap['data'] as List<dynamic>;

    return transactionsJson.map((dynamic jsonItem) {
      final Map<String, dynamic> json = jsonItem as Map<String, dynamic>;

      return CarnetTransactionModel(
        id: json['id'] as String,
        carnetId: json['carnetId'] as String,
        clientId: json['clientId'] as String,
        hanoutId: json['hanoutId'] as String,
        type: TransactionType.values.firstWhere(
          (e) => e.value == json['type'],
          orElse: () => TransactionType.credit,
        ),
        amount: (json['amount'] as num).toDouble(),
        balanceBefore: (json['balanceBefore'] as num).toDouble(),
        balanceAfter: (json['balanceAfter'] as num).toDouble(),
        orderId: json['orderId'] as String?,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
    }).toList();
  }

  /// Demande l'activation du carnet
  Future<CarnetRequestModel> requestCarnetActivation(String hanoutId) async {
    final dynamic response = await _apiService.post(
      '/carnet/request',
      body: {'hanoutId': hanoutId},
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;

    return _parseCarnetRequest(responseMap['data'] as Map<String, dynamic>);
  }

  /// Récupère les demandes de carnet du client
  Future<List<CarnetRequestModel>> getCarnetRequests() async {
    final dynamic response = await _apiService.get('/carnet/my-requests');
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> requestsJson = responseMap['data'] as List<dynamic>;

    return requestsJson.map((dynamic jsonItem) {
      return _parseCarnetRequest(jsonItem as Map<String, dynamic>);
    }).toList();
  }

  /// Enregistre un paiement
  Future<Map<String, dynamic>> recordPayment({
    required String carnetId,
    required double amount,
    String? description,
  }) async {
    final Map<String, dynamic> body = {
      'amount': amount,
    };
    if (description != null) body['description'] = description;

    final dynamic response = await _apiService.post(
      '/carnet/$carnetId/payment',
      body: body,
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final Map<String, dynamic> data =
        responseMap['data'] as Map<String, dynamic>;

    return {
      'carnet': _parseCarnet(data['carnet'] as Map<String, dynamic>),
      'transaction': _parseTransaction(
        data['transaction'] as Map<String, dynamic>,
      ),
    };
  }

  /// Parse JSON vers CarnetModel
  CarnetModel _parseCarnet(Map<String, dynamic> json) {
    return CarnetModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      hanoutId: json['hanoutId'] as String,
      balance: (json['balance'] as num).toDouble(),
      isActive: json['isActive'] as bool,
      activatedAt: json['activatedAt'] != null
          ? DateTime.parse(json['activatedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Parse JSON vers CarnetRequestModel
  CarnetRequestModel _parseCarnetRequest(Map<String, dynamic> json) {
    return CarnetRequestModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      hanoutId: json['hanoutId'] as String,
      status: RequestStatus.fromString(json['status'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
    );
  }

  /// Parse JSON vers CarnetTransactionModel
  CarnetTransactionModel _parseTransaction(Map<String, dynamic> json) {
    return CarnetTransactionModel(
      id: json['id'] as String,
      carnetId: json['carnetId'] as String,
      clientId: json['clientId'] as String,
      hanoutId: json['hanoutId'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => TransactionType.credit,
      ),
      amount: (json['amount'] as num).toDouble(),
      balanceBefore: (json['balanceBefore'] as num).toDouble(),
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      orderId: json['orderId'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // /// Helper pour parser le statut de CarnetRequest
  // CarnetRequestStatus _parseCarnetRequestStatus(String status) {
  //   switch (status.toUpperCase()) {
  //     case 'PENDING':
  //       return CarnetRequestStatus.pending;
  //     case 'APPROVED':
  //       return CarnetRequestStatus.approved;
  //     case 'REJECTED':
  //       return CarnetRequestStatus.rejected;
  //     default:
  //       return CarnetRequestStatus.pending;
  //   }
  // }
}

// ============================================
// GAS SERVICE REPOSITORY
// ============================================

class GasServiceRepository {
  GasServiceRepository(this._apiService);

  final ApiService _apiService;

  Future<GasServiceOrder> createRequest({
    String? clientAddress,
    double? clientLatitude,
    double? clientLongitude,
    String? notes,
    double? price,
    double? serviceFee,
  }) async {
    final Map<String, dynamic> body = {};
    if (clientAddress != null) body['clientAddress'] = clientAddress;
    if (clientLatitude != null) body['clientLatitude'] = clientLatitude;
    if (clientLongitude != null) body['clientLongitude'] = clientLongitude;
    if (notes != null) body['notes'] = notes;
    if (price != null) body['price'] = price;
    if (serviceFee != null) body['serviceFee'] = serviceFee;

    final dynamic response = await _apiService.post(
      '/gas-service/requests',
      body: body.isEmpty ? null : body,
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return GasServiceOrder.fromJson(
      responseMap['data'] as Map<String, dynamic>,
    );
  }

  Future<GasServiceOrder> getRequestById(String requestId) async {
    final dynamic response = await _apiService.get(
      '/gas-service/requests/$requestId',
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return GasServiceOrder.fromJson(
      responseMap['data'] as Map<String, dynamic>,
    );
  }

  Future<List<GasServiceOrder>> getMyRequests() async {
    final dynamic response = await _apiService.get('/gas-service/requests/my');
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> list = responseMap['data'] as List<dynamic>;
    return list.map((dynamic item) {
      return GasServiceOrder.fromJson(item as Map<String, dynamic>);
    }).toList();
  }

  Future<GasServiceOrder> updateStatus(
    String requestId,
    GasServiceStatus status,
  ) async {
    final dynamic response = await _apiService.put(
      '/gas-service/requests/$requestId/status',
      body: {'status': status.value},
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return GasServiceOrder.fromJson(
      responseMap['data'] as Map<String, dynamic>,
    );
  }

  Future<GasServiceOrder> cancelRequest(
    String requestId, {
    String? reason,
  }) async {
    final Map<String, dynamic>? body = reason != null
        ? {'reason': reason}
        : null;
    final dynamic response = await _apiService.post(
      '/gas-service/requests/$requestId/cancel',
      body: body,
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return GasServiceOrder.fromJson(
      responseMap['data'] as Map<String, dynamic>,
    );
  }

  Future<ReviewModel?> getRequestReview(String requestId) async {
    final dynamic response = await _apiService.get(
      '/gas-service/requests/$requestId/review',
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final dynamic data = responseMap['data'];
    if (data == null) return null;
    return ReviewModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ReviewModel> upsertRequestReview({
    required String requestId,
    required int livreurRating,
    String? livreurComment,
  }) async {
    final Map<String, dynamic> body = {
      'livreurRating': livreurRating,
      if (livreurComment != null && livreurComment.trim().isNotEmpty)
        'livreurComment': livreurComment.trim(),
    };

    final dynamic response = await _apiService.post(
      '/gas-service/requests/$requestId/review',
      body: body,
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return ReviewModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }
}
