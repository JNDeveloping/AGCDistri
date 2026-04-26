import '../../../clientes/domain/models/client_model.dart';

enum AccountsOverviewStatus { initial, loading, success, failure }
enum AccountsOverviewFilter { all, withDebt, upToDate }

class AccountClientSummary {
  const AccountClientSummary({
    required this.client,
    required this.currentBalance,
    required this.lastActivity,
  });

  final ClientModel client;
  final double currentBalance;
  final DateTime? lastActivity;

  bool get hasDebt => currentBalance > 0;
}

class AccountsOverviewState {
  const AccountsOverviewState({
    this.status = AccountsOverviewStatus.initial,
    this.items = const [],
    this.query = '',
    this.filter = AccountsOverviewFilter.all,
    this.errorMessage,
  });

  final AccountsOverviewStatus status;
  final List<AccountClientSummary> items;
  final String query;
  final AccountsOverviewFilter filter;
  final String? errorMessage;

  AccountsOverviewState copyWith({
    AccountsOverviewStatus? status,
    List<AccountClientSummary>? items,
    String? query,
    AccountsOverviewFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AccountsOverviewState(
      status: status ?? this.status,
      items: items ?? this.items,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

