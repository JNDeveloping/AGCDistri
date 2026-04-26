import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../clientes/data/repositories/client_repository.dart';
import '../../data/repositories/accounts_repository.dart';
import 'accounts_overview_state.dart';

class AccountsOverviewCubit extends Cubit<AccountsOverviewState> {
  AccountsOverviewCubit({
    required AccountsRepository accountsRepository,
    required ClientRepository clientRepository,
  })  : _accountsRepository = accountsRepository,
        _clientRepository = clientRepository,
        super(const AccountsOverviewState());

  final AccountsRepository _accountsRepository;
  final ClientRepository _clientRepository;
  Timer? _debounce;

  Future<void> load() async {
    emit(state.copyWith(status: AccountsOverviewStatus.loading, clearError: true));
    try {
      final response = await _clientRepository.list(
        query: state.query.trim(),
        isActive: true,
      );

      final summaries = await Future.wait(
        response.items.map((client) async {
          DateTime? lastActivity;
          double currentBalance = client.currentBalance;
          try {
            final account = await _accountsRepository.account(client.id);
            currentBalance = account.currentBalance;
            lastActivity = account.lastMovementAt;
          } catch (_) {
            // Se mantiene balance del cliente para no cortar el listado completo.
          }

          return AccountClientSummary(
            client: client,
            currentBalance: currentBalance,
            lastActivity: lastActivity,
          );
        }),
      );

      emit(
        state.copyWith(
          status: AccountsOverviewStatus.success,
          items: _applyFilter(summaries, state.filter),
        ),
      );
    } on ClientException catch (error) {
      emit(
        state.copyWith(
          status: AccountsOverviewStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AccountsOverviewStatus.failure,
          errorMessage: 'No se pudo cargar Cuentas Corrientes.',
        ),
      );
    }
  }

  void onSearchChanged(String value) {
    emit(state.copyWith(query: value));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), load);
  }

  Future<void> setFilter(AccountsOverviewFilter filter) async {
    emit(state.copyWith(filter: filter));
    await load();
  }

  List<AccountClientSummary> _applyFilter(List<AccountClientSummary> items, AccountsOverviewFilter filter) {
    final filtered = switch (filter) {
      AccountsOverviewFilter.all => items,
      AccountsOverviewFilter.withDebt => items.where((item) => item.hasDebt).toList(),
      AccountsOverviewFilter.upToDate => items.where((item) => !item.hasDebt).toList(),
    };

    filtered.sort((a, b) {
      final debtOrder = (b.currentBalance > 0 ? 1 : 0) - (a.currentBalance > 0 ? 1 : 0);
      if (debtOrder != 0) return debtOrder;
      return a.client.businessName.toLowerCase().compareTo(b.client.businessName.toLowerCase());
    });

    return filtered;
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
