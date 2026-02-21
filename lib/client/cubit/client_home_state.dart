import 'package:equatable/equatable.dart';
import 'package:sevenouti/client/models/models.dart';

/// États possibles de la page Home du client
abstract class ClientHomeState extends Equatable {
  const ClientHomeState();

  @override
  List<Object?> get props => [];
}

/// État initial - avant de charger quoi que ce soit
class ClientHomeInitial extends ClientHomeState {
  const ClientHomeInitial();
}

/// État de chargement - récupération de la position et des hanouts
class ClientHomeLoading extends ClientHomeState {
  const ClientHomeLoading();
}

/// État de chargement de la position uniquement
class ClientHomeLoadingLocation extends ClientHomeState {
  const ClientHomeLoadingLocation();
}

/// État de succès - hanouts chargés
class ClientHomeLoaded extends ClientHomeState {
  const ClientHomeLoaded({
    required this.hanouts,
    required this.userLatitude,
    required this.userLongitude,
    this.selectedHanout,
  });

  final List<HanoutWithDistance> hanouts;
  final double userLatitude;
  final double userLongitude;
  final HanoutWithDistance? selectedHanout;

  @override
  List<Object?> get props => [
        hanouts,
        userLatitude,
        userLongitude,
        selectedHanout,
      ];

  /// Copie l'état avec modifications
  ClientHomeLoaded copyWith({
    List<HanoutWithDistance>? hanouts,
    double? userLatitude,
    double? userLongitude,
    HanoutWithDistance? selectedHanout,
  }) {
    return ClientHomeLoaded(
      hanouts: hanouts ?? this.hanouts,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      selectedHanout: selectedHanout ?? this.selectedHanout,
    );
  }
}

/// État vide - pas de hanouts trouvés
class ClientHomeEmpty extends ClientHomeState {
  const ClientHomeEmpty({
    required this.userLatitude,
    required this.userLongitude,
  });

  final double userLatitude;
  final double userLongitude;

  @override
  List<Object?> get props => [userLatitude, userLongitude];
}

/// État d'erreur - problème lors du chargement
class ClientHomeError extends ClientHomeState {
  const ClientHomeError({
    required this.message,
    this.canRetry = true,
  });

  final String message;
  final bool canRetry;

  @override
  List<Object?> get props => [message, canRetry];
}

/// État d'erreur de permission (géolocalisation)
class ClientHomeLocationPermissionDenied extends ClientHomeState {
  const ClientHomeLocationPermissionDenied();
}