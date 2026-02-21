import 'package:equatable/equatable.dart';
import 'package:sevenouti/client/models/gas_service_order.dart';
import 'package:sevenouti/livreur/models/livreur_order_model.dart';

abstract class LivreurInProgressState extends Equatable {
  const LivreurInProgressState();

  @override
  List<Object?> get props => [];
}

class LivreurInProgressInitial extends LivreurInProgressState {
  const LivreurInProgressInitial();
}

class LivreurInProgressLoading extends LivreurInProgressState {
  const LivreurInProgressLoading();
}

class LivreurInProgressLoaded extends LivreurInProgressState {
  const LivreurInProgressLoaded({
    required this.orders,
    required this.gasRequests,
  });

  final List<LivreurOrderModel> orders;
  final List<GasServiceOrder> gasRequests;

  @override
  List<Object?> get props => [orders, gasRequests];
}

class LivreurInProgressEmpty extends LivreurInProgressState {
  const LivreurInProgressEmpty();
}

class LivreurInProgressError extends LivreurInProgressState {
  const LivreurInProgressError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
