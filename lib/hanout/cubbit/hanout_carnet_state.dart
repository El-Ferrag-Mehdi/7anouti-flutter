import 'package:equatable/equatable.dart';
import 'package:sevenouti/hanout/models/hanout_models.dart';

abstract class HanoutCarnetState extends Equatable {
  const HanoutCarnetState();

  @override
  List<Object?> get props => [];
}

class HanoutCarnetInitial extends HanoutCarnetState {
  const HanoutCarnetInitial();
}

class HanoutCarnetLoading extends HanoutCarnetState {
  const HanoutCarnetLoading();
}

class HanoutCarnetLoaded extends HanoutCarnetState {
  const HanoutCarnetLoaded({
    required this.carnets,
    required this.requests,
  });

  final List<HanoutCarnetModel> carnets;
  final List<HanoutCarnetRequestModel> requests;

  @override
  List<Object?> get props => [carnets, requests];
}

class HanoutCarnetEmpty extends HanoutCarnetState {
  const HanoutCarnetEmpty();
}

class HanoutCarnetError extends HanoutCarnetState {
  const HanoutCarnetError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
