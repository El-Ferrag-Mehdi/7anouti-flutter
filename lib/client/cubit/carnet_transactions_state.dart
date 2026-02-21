import 'package:equatable/equatable.dart';
import 'package:sevenouti/client/models/carnet_model.dart';

/// États de l'historique des transactions d'un carnet
abstract class CarnetTransactionsState extends Equatable {
  const CarnetTransactionsState();

  @override
  List<Object?> get props => [];
}

/// État initial
class CarnetTransactionsInitial extends CarnetTransactionsState {
  const CarnetTransactionsInitial();
}

/// État de chargement
class CarnetTransactionsLoading extends CarnetTransactionsState {
  const CarnetTransactionsLoading();
}

/// État chargé
class CarnetTransactionsLoaded extends CarnetTransactionsState {
  const CarnetTransactionsLoaded({
    required this.transactions,
    required this.carnet,
  });

  final List<CarnetTransactionModel> transactions;
  final CarnetModel carnet;

  @override
  List<Object?> get props => [transactions, carnet];

  /// Calcule le total des achats à crédit
  double get totalCredit {
    return transactions
        .where((t) => t.type == TransactionType.credit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Calcule le total des paiements
  double get totalPayments {
    return transactions
        .where((t) => t.type == TransactionType.payment)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}

/// État vide
class CarnetTransactionsEmpty extends CarnetTransactionsState {
  const CarnetTransactionsEmpty();
}

/// État d'erreur
class CarnetTransactionsError extends CarnetTransactionsState {
  const CarnetTransactionsError({
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [message];
}