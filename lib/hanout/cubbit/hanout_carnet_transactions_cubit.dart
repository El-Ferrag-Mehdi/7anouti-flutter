import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/hanout/cubbit/hanout_carnet_transactions_state.dart';
import 'package:sevenouti/hanout/models/hanout_models.dart';
import 'package:sevenouti/hanout/repository/hanout_repositories.dart';

class HanoutCarnetTransactionsCubit
    extends Cubit<HanoutCarnetTransactionsState> {
  HanoutCarnetTransactionsCubit({
    required HanoutCarnetRepository carnetRepository,
  })  : _carnetRepository = carnetRepository,
        super(const HanoutCarnetTransactionsInitial());

  final HanoutCarnetRepository _carnetRepository;

  Future<void> loadTransactions(HanoutCarnetModel carnet) async {
    emit(const HanoutCarnetTransactionsLoading());
    try {
      final transactions =
          await _carnetRepository.getCarnetTransactions(carnet.id);
      if (transactions.isEmpty) {
        emit(const HanoutCarnetTransactionsEmpty());
      } else {
        emit(HanoutCarnetTransactionsLoaded(
          carnet: carnet,
          transactions: transactions,
        ));
      }
    } on ApiException catch (e) {
      emit(HanoutCarnetTransactionsError(message: e.message));
    } catch (e) {
      emit(HanoutCarnetTransactionsError(
        message: e.toString(),
      ));
    }
  }
}

