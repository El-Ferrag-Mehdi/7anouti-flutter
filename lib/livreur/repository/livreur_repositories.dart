import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/gas_service_order.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/livreur/models/delivery_request_model.dart';
import 'package:sevenouti/livreur/models/livreur_order_model.dart';

class LivreurRequestsRepository {
  LivreurRequestsRepository(this._apiService);

  final ApiService _apiService;

  Future<List<LivreurDeliveryRequestModel>> getAvailableRequests({
    double? latitude,
    double? longitude,
    int radius = 5000,
  }) async {
    var endpoint = '/delivery-requests/livreur/available';
    if (latitude != null && longitude != null) {
      endpoint +=
          '?latitude=$latitude&longitude=$longitude&radius=$radius';
    }
    final dynamic response = await _apiService.get(endpoint);
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> jsonList = responseMap['data'] as List<dynamic>;
    final deliveryRequests = jsonList.map((dynamic jsonItem) {
      return LivreurDeliveryRequestModel.fromJson(
        jsonItem as Map<String, dynamic>,
      );
    }).toList();

    final gasRequests = await _getAvailableGasRequests(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );

    final merged = [...deliveryRequests, ...gasRequests];
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  Future<void> acceptRequest(String requestId) async {
    await _apiService.post('/delivery-requests/$requestId/accept');
  }

  Future<void> rejectRequest(String requestId) async {
    await _apiService.post('/delivery-requests/$requestId/reject');
  }

  Future<void> acceptGasRequest(String requestId) async {
    await _apiService.post('/gas-service/requests/$requestId/accept');
  }

  Future<void> rejectGasRequest(String requestId) async {
    await _apiService.post('/gas-service/requests/$requestId/reject');
  }

  Future<List<LivreurDeliveryRequestModel>> _getAvailableGasRequests({
    double? latitude,
    double? longitude,
    int radius = 5000,
  }) async {
    try {
      var endpoint = '/gas-service/requests/livreur/available';
      if (latitude != null && longitude != null) {
        endpoint +=
            '?latitude=$latitude&longitude=$longitude&radius=$radius';
      }

      final dynamic response = await _apiService.get(endpoint);
      final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
      final List<dynamic> jsonList = responseMap['data'] as List<dynamic>;

      return jsonList.map((dynamic jsonItem) {
        final Map<String, dynamic> json = jsonItem as Map<String, dynamic>;
        final status = json['status'] as String? ?? 'PENDING';
        return LivreurDeliveryRequestModel(
          id: json['id'] as String,
          status: status,
          orderId: json['id'] as String,
          hanoutId: '',
          createdAt: DateTime.parse(json['createdAt'] as String),
          order: LivreurDeliveryOrderInfo(
            id: json['id'] as String,
            freeTextOrder: 'Service bouteille à gaz',
            status: _mapGasToOrderStatus(status),
            deliveryType: DeliveryType.delivery,
            clientAddress: json['clientAddress'] as String?,
            clientLatitude: json['clientLatitude'] != null
                ? (json['clientLatitude'] as num).toDouble()
                : null,
            clientLongitude: json['clientLongitude'] != null
                ? (json['clientLongitude'] as num).toDouble()
                : null,
            notes: json['notes'] as String?,
          ),
          hanout: null,
          distance: json['distance'] != null
              ? (json['distance'] as num).toDouble()
              : null,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  OrderStatus _mapGasToOrderStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'EN_ROUTE':
      case 'ARRIVE':
      case 'RECUPERE_VIDE':
      case 'VA_AU_HANOUT':
      case 'RETOUR_MAISON':
        return OrderStatus.delivering;
      case 'LIVRE':
        return OrderStatus.delivered;
      case 'CANCELLED':
      case 'REJECTED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

class LivreurOrdersRepository {
  LivreurOrdersRepository(this._apiService);

  final ApiService _apiService;

  Future<List<LivreurOrderModel>> getLivreurOrders({
    String? status,
    int limit = 50,
  }) async {
    String endpoint = '/orders/livreur/my-orders?limit=$limit';
    if (status != null) {
      endpoint += '&status=$status';
    }
    final dynamic response = await _apiService.get(endpoint);
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> ordersJson = responseMap['data'] as List<dynamic>;
    return ordersJson.map((dynamic jsonItem) {
      return LivreurOrderModel.fromJson(jsonItem as Map<String, dynamic>);
    }).toList();
  }

  Future<LivreurOrderModel> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    final dynamic response = await _apiService.put(
      '/orders/$orderId/status',
      body: {'status': status.value},
    );
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return LivreurOrderModel.fromJson(
      responseMap['data'] as Map<String, dynamic>,
    );
  }
}

class GasServiceLivreurRepository {
  GasServiceLivreurRepository(this._apiService);

  final ApiService _apiService;

  Future<List<GasServiceOrder>> getLivreurGasRequests({String? status}) async {
    var endpoint = '/gas-service/requests/livreur/my';
    if (status != null) {
      endpoint += '?status=$status';
    }
    final dynamic response = await _apiService.get(endpoint);
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    final List<dynamic> list = responseMap['data'] as List<dynamic>;
    return list.map((dynamic item) {
      return GasServiceOrder.fromJson(item as Map<String, dynamic>);
    }).toList();
  }

  Future<GasServiceOrder> updateGasStatus(
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
}

class LivreurEarningsRepository {
  LivreurEarningsRepository(this._apiService);

  final ApiService _apiService;

  Future<Map<String, dynamic>> getEarnings({int limit = 100}) async {
    final dynamic response =
        await _apiService.get('/livreur/earnings?limit=$limit');
    final Map<String, dynamic> responseMap = response as Map<String, dynamic>;
    return responseMap['data'] as Map<String, dynamic>;
  }
}
