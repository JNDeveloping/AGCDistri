import 'package:equatable/equatable.dart';

import '../../domain/models/client_model.dart';

enum ClientsStatus { initial, loading, success, failure }

class ClientsState extends Equatable {
  const ClientsState({
    this.status = ClientsStatus.initial,
    this.items = const [],
    this.filteredStatus,
    this.query = '',
    this.errorMessage,
    this.total = 0,
  });

  final ClientsStatus status;
  final List<ClientModel> items;
  final bool? filteredStatus;
  final String query;
  final String? errorMessage;
  final int total;

  ClientsState copyWith({
    ClientsStatus? status,
    List<ClientModel>? items,
    bool? filteredStatus,
    bool clearFilter = false,
    String? query,
    String? errorMessage,
    int? total,
  }) {
    return ClientsState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredStatus: clearFilter ? null : filteredStatus ?? this.filteredStatus,
      query: query ?? this.query,
      errorMessage: errorMessage,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [status, items, filteredStatus, query, errorMessage, total];
}
