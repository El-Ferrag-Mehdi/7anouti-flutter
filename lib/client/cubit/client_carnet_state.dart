import 'package:equatable/equatable.dart';
import 'package:sevenouti/client/models/carnet_model.dart';

/// États de la page Carnet du client
abstract class ClientCarnetState extends Equatable {
  const ClientCarnetState();

  @override
  List<Object?> get props => [];
}

/// État initial
class ClientCarnetInitial extends ClientCarnetState {
  const ClientCarnetInitial();
}

/// État de chargement
class ClientCarnetLoading extends ClientCarnetState {
  const ClientCarnetLoading();
}

/// État chargé avec les carnets
class ClientCarnetLoaded extends ClientCarnetState {
  const ClientCarnetLoaded({
    required this.carnets,
    this.selectedCarnet,
  });

  final List<CarnetModel> carnets;
  final CarnetModel? selectedCarnet;

  @override
  List<Object?> get props => [carnets, selectedCarnet];

  /// Solde total (toutes les dettes)
  double get totalBalance {
    return carnets.fold(0.0, (sum, carnet) => sum + carnet.balance);
  }

  /// Nombre de carnets actifs
  int get activeCarnetCount {
    return carnets.where((c) => c.isActive).length;
  }

  /// Copie avec modifications
  ClientCarnetLoaded copyWith({
    List<CarnetModel>? carnets,
    CarnetModel? selectedCarnet,
  }) {
    return ClientCarnetLoaded(
      carnets: carnets ?? this.carnets,
      selectedCarnet: selectedCarnet ?? this.selectedCarnet,
    );
  }
}

/// État vide - pas de carnets
class ClientCarnetEmpty extends ClientCarnetState {
  const ClientCarnetEmpty();
}

/// État d'erreur
class ClientCarnetError extends ClientCarnetState {
  const ClientCarnetError({
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [message];
}