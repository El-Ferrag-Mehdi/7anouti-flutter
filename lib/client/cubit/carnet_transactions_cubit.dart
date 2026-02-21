import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sevenouti/client/cubit/carnet_transactions_state.dart';
import 'package:sevenouti/client/data/api_service.dart';
import 'package:sevenouti/client/models/carnet_model.dart';
import 'package:sevenouti/client/repository/repositories.dart';

/// Cubit pour gérer les transactions d'un carnet
class CarnetTransactionsCubit extends Cubit<CarnetTransactionsState> {
  CarnetTransactionsCubit({
    required CarnetRepository carnetRepository,
  })  : _carnetRepository = carnetRepository,
        super(const CarnetTransactionsInitial());

  final CarnetRepository _carnetRepository;

  /// Charge les transactions d'un carnet
  Future<void> loadTransactions(CarnetModel carnet) async {
    emit(const CarnetTransactionsLoading());

    try {
      final transactions = await _carnetRepository.getCarnetTransactions(
        carnet.id,
      );

      if (transactions.isEmpty) {
        emit(const CarnetTransactionsEmpty());
      } else {
        emit(CarnetTransactionsLoaded(
          transactions: transactions,
          carnet: carnet,
        ));
      }
    } on ApiException catch (e) {
      emit(CarnetTransactionsError(message: e.message));
    } catch (e) {
      emit(CarnetTransactionsError(
        message: e.toString(),
      ));
    }
  }

  /// VERSION MOCK pour tester sans API
  Future<void> loadTransactionsMock(CarnetModel carnet) async {
    emit(const CarnetTransactionsLoading());

    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Transactions fictives
    final mockTransactions = [
      CarnetTransactionModel(
        id: 'tx1',
        carnetId: carnet.id,
        clientId: 'client1',
        hanoutId: carnet.hanoutId,
        type: TransactionType.credit,
        amount: 35.00,
        balanceBefore: 85.50,
        balanceAfter: 120.50,
        orderId: 'order123',
        description: 'Commande #order123',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      CarnetTransactionModel(
        id: 'tx2',
        carnetId: carnet.id,
        clientId: 'client1',
        hanoutId: carnet.hanoutId,
        type: TransactionType.payment,
        amount: 50.00,
        balanceBefore: 135.50,
        balanceAfter: 85.50,
        description: 'Paiement en espèces',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      CarnetTransactionModel(
        id: 'tx3',
        carnetId: carnet.id,
        clientId: 'client1',
        hanoutId: carnet.hanoutId,
        type: TransactionType.credit,
        amount: 22.50,
        balanceBefore: 113.00,
        balanceAfter: 135.50,
        orderId: 'order122',
        description: 'Commande #order122',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      CarnetTransactionModel(
        id: 'tx4',
        carnetId: carnet.id,
        clientId: 'client1',
        hanoutId: carnet.hanoutId,
        type: TransactionType.credit,
        amount: 28.00,
        balanceBefore: 85.00,
        balanceAfter: 113.00,
        orderId: 'order121',
        description: 'Commande #order121',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      CarnetTransactionModel(
        id: 'tx5',
        carnetId: carnet.id,
        clientId: 'client1',
        hanoutId: carnet.hanoutId,
        type: TransactionType.payment,
        amount: 100.00,
        balanceBefore: 185.00,
        balanceAfter: 85.00,
        description: 'Paiement en espèces',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];

    emit(CarnetTransactionsLoaded(
      transactions: mockTransactions,
      carnet: carnet,
    ));
  }
}

