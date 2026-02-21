import 'package:equatable/equatable.dart';
import 'package:sevenouti/client/models/carnet_model.dart';
import 'package:sevenouti/hanout/models/hanout_models.dart';

abstract class HanoutCarnetTransactionsState extends Equatable {
  const HanoutCarnetTransactionsState();

  @override
  List<Object?> get props => [];
}

class HanoutCarnetTransactionsInitial extends HanoutCarnetTransactionsState {
  const HanoutCarnetTransactionsInitial();
}

class HanoutCarnetTransactionsLoading extends HanoutCarnetTransactionsState {
  const HanoutCarnetTransactionsLoading();
}

class HanoutCarnetTransactionsLoaded extends HanoutCarnetTransactionsState {
  const HanoutCarnetTransactionsLoaded({
    required this.carnet,
    required this.transactions,
  });

  final HanoutCarnetModel carnet;
  final List<CarnetTransactionModel> transactions;

  @override
  List<Object?> get props => [carnet, transactions];

  double get totalCredit {
    return transactions
        .where((t) => t.type == TransactionType.credit)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get totalPayments {
    return transactions
        .where((t) => t.type == TransactionType.payment)
        .fold(0, (sum, t) => sum + t.amount);
  }
}

class HanoutCarnetTransactionsEmpty extends HanoutCarnetTransactionsState {
  const HanoutCarnetTransactionsEmpty();
}

class HanoutCarnetTransactionsError extends HanoutCarnetTransactionsState {
  const HanoutCarnetTransactionsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
