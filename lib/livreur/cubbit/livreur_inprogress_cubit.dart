import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/gas_service_order.dart';
import 'package:sevenouti/client/models/order_model.dart';
import 'package:sevenouti/livreur/cubbit/livreur_inprogress_state.dart';
import 'package:sevenouti/livreur/repository/livreur_repositories.dart';

class LivreurInProgressCubit extends Cubit<LivreurInProgressState> {
  LivreurInProgressCubit({
    required LivreurOrdersRepository repository,
    required GasServiceLivreurRepository gasRepository,
  })  : _repository = repository,
        _gasRepository = gasRepository,
        super(const LivreurInProgressInitial());

  final LivreurOrdersRepository _repository;
  final GasServiceLivreurRepository _gasRepository;

  Future<void> loadOrders() async {
    emit(const LivreurInProgressLoading());
    try {
      final orders = await _repository.getLivreurOrders(limit: 100);
      final active = orders.where((o) {
        return o.status == OrderStatus.ready ||
            o.status == OrderStatus.pickedUp ||
            o.status == OrderStatus.delivering;
      }).toList();
      final gasRequests = await _gasRepository.getLivreurGasRequests();
      final gasActive = gasRequests.where((r) {
        return r.status == GasServiceStatus.enRoute ||
            r.status == GasServiceStatus.arrive ||
            r.status == GasServiceStatus.recupereVide ||
            r.status == GasServiceStatus.vaAuHanout ||
            r.status == GasServiceStatus.retourMaison;
      }).toList();

      if (active.isEmpty && gasActive.isEmpty) {
        emit(const LivreurInProgressEmpty());
      } else {
        emit(LivreurInProgressLoaded(orders: active, gasRequests: gasActive));
      }
    } on ApiException catch (e) {
      emit(LivreurInProgressError(message: e.message));
    } catch (e) {
      emit(LivreurInProgressError(
        message: e.toString(),
      ));
    }
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    try {
      await _repository.updateOrderStatus(orderId, status);
      await loadOrders();
    } on ApiException catch (e) {
      emit(LivreurInProgressError(message: e.message));
    } catch (e) {
      emit(LivreurInProgressError(
        message: e.toString(),
      ));
    }
  }

  Future<void> updateGasStatus(
    String requestId,
    GasServiceStatus status,
  ) async {
    try {
      await _gasRepository.updateGasStatus(requestId, status);
      await loadOrders();
    } on ApiException catch (e) {
      emit(LivreurInProgressError(message: e.message));
    } catch (e) {
      emit(LivreurInProgressError(
        message: e.toString(),
      ));
    }
  }
}

