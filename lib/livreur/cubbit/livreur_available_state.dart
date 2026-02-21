import 'package:equatable/equatable.dart';
import 'package:sevenouti/livreur/models/delivery_request_model.dart';

abstract class LivreurAvailableState extends Equatable {
  const LivreurAvailableState();

  @override
  List<Object?> get props => [];
}

class LivreurAvailableInitial extends LivreurAvailableState {
  const LivreurAvailableInitial();
}

class LivreurAvailableLoading extends LivreurAvailableState {
  const LivreurAvailableLoading();
}

class LivreurAvailableLoaded extends LivreurAvailableState {
  const LivreurAvailableLoaded({required this.requests});

  final List<LivreurDeliveryRequestModel> requests;

  @override
  List<Object?> get props => [requests];
}

class LivreurAvailableEmpty extends LivreurAvailableState {
  const LivreurAvailableEmpty();
}

class LivreurAvailableError extends LivreurAvailableState {
  const LivreurAvailableError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
