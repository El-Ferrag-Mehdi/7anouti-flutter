import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/carnet_model.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/hanout/models/hanout_models.dart';

class HanoutOrdersRepository {
  HanoutOrdersRepository(this._apiService);

  final ApiService _apiService;

  Future<List<HanoutOrderModel>> getHanoutOrders({
    String? status,
    int limit = 50,
  }) async {
    String endpoint = '/orders/hanout/my-orders?limit=$limit';
    if (status != null) {
      endpoint += '&status=$status';
    }
    final dynamic response = await _apiService.get(endpoint);
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> ordersJson = responseMap['data'] as List<dynamic>;
    return ordersJson.map((dynamic jsonItem) {
      return HanoutOrderModel.fromJson(jsonItem as Map<String, dynamic>);
    }).toList();
  }

  Future<HanoutOrderModel> acceptOrder(
    String orderId, {
    double? totalAmount,
  }) async {
    final Map<String, dynamic> body = {};
    if (totalAmount != null) body['totalAmount'] = totalAmount;
    final dynamic response = await _apiService.put(
      '/orders/$orderId/accept',
      body: body.isEmpty ? null : body,
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return HanoutOrderModel.fromJson(
      responseMap['data'] as Map<String, dynamic>,
    );
  }

  Future<HanoutOrderModel> updateOrderStatus(
    String orderId, {
    OrderStatus? status,
    double? totalAmount,
  }) async {
    final Map<String, dynamic> body = {};
    if (status != null) body['status'] = status.value;
    if (totalAmount != null) body['totalAmount'] = totalAmount;
    final dynamic response = await _apiService.put(
      '/orders/$orderId/status',
      body: body.isEmpty ? null : body,
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return HanoutOrderModel.fromJson(
      responseMap['data'] as Map<String, dynamic>,
    );
  }

  Future<HanoutOrderModel> assignLivreur(
    String orderId,
    String livreurId,
  ) async {
    final dynamic response = await _apiService.put(
      '/orders/$orderId/assign-livreur',
      body: {'livreurId': livreurId},
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return HanoutOrderModel.fromJson(
      responseMap['data'] as Map<String, dynamic>,
    );
  }

  Future<void> requestLivreur(String orderId) async {
    await _apiService.post('/delivery-requests/order/$orderId');
  }

  Future<HanoutOrderModel> getOrderById(String orderId) async {
    final dynamic response = await _apiService.get('/orders/$orderId');
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return HanoutOrderModel.fromJson(
      responseMap['data'] as Map<String, dynamic>,
    );
  }
}

class HanoutCarnetRepository {
  HanoutCarnetRepository(this._apiService);

  final ApiService _apiService;

  Future<List<HanoutCarnetModel>> getHanoutCarnets() async {
    final dynamic response = await _apiService.get('/carnet/hanout/my-carnets');
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> carnetsJson = responseMap['data'] as List<dynamic>;
    return carnetsJson.map((dynamic jsonItem) {
      return HanoutCarnetModel.fromJson(jsonItem as Map<String, dynamic>);
    }).toList();
  }

  Future<List<HanoutCarnetRequestModel>> getHanoutRequests({
    String? status,
  }) async {
    String endpoint = '/carnet/hanout/requests';
    if (status != null) {
      endpoint += '?status=$status';
    }
    final dynamic response = await _apiService.get(endpoint);
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> requestsJson = responseMap['data'] as List<dynamic>;
    return requestsJson.map((dynamic jsonItem) {
      return HanoutCarnetRequestModel.fromJson(
        jsonItem as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<HanoutCarnetModel> updateCreditLimit(
    String carnetId,
    double creditLimit,
  ) async {
    final dynamic response = await _apiService.put(
      '/carnet/$carnetId/limit',
      body: {'creditLimit': creditLimit},
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return HanoutCarnetModel.fromJson(
      responseMap['data'] as Map<String, dynamic>,
    );
  }

  Future<HanoutCarnetModel> approveRequest(String requestId) async {
    final dynamic response =
        await _apiService.post('/carnet/requests/$requestId/approve');
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return HanoutCarnetModel.fromJson(
      responseMap['data'] as Map<String, dynamic>,
    );
  }

  Future<HanoutCarnetRequestModel> rejectRequest(
    String requestId,
    String reason,
  ) async {
    final dynamic response = await _apiService.post(
      '/carnet/requests/$requestId/reject',
      body: {'reason': reason},
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return HanoutCarnetRequestModel.fromJson(
      responseMap['data'] as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> recordPayment({
    required String carnetId,
    required double amount,
    String? description,
  }) async {
    final Map<String, dynamic> body = {'amount': amount};
    if (description != null) body['description'] = description;

    final dynamic response =
        await _apiService.post('/carnet/$carnetId/payment', body: body);
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final Map<String, dynamic> data = responseMap['data'] as Map<String, dynamic>;

    return {
      'carnet': HanoutCarnetModel.fromJson(
        data['carnet'] as Map<String, dynamic>,
      ),
      'transaction': data['transaction'],
    };
  }

  Future<Map<String, dynamic>> addDebt({
    required String carnetId,
    required double amount,
    required String description,
  }) async {
    final Map<String, dynamic> body = {
      'amount': amount,
      'description': description,
    };

    final dynamic response =
        await _apiService.post('/carnet/$carnetId/debt', body: body);
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final Map<String, dynamic> data = responseMap['data'] as Map<String, dynamic>;

    return {
      'carnet': HanoutCarnetModel.fromJson(
        data['carnet'] as Map<String, dynamic>,
      ),
      'transaction': data['transaction'],
    };
  }

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
}
