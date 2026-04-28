import 'package:equatable/equatable.dart';

import '../../domain/models/client_model.dart';

enum ClientsStatus { initial, loading, success, failure }

class ClientsState extends Equatable {
  const ClientsState({
    this.status = ClientsStatus.initial,
    this.items = const [],
    this.filteredStatus,
    this.zoneId,
    this.query = '',
    this.errorMessage,
    this.total = 0,
  });

  final ClientsStatus status;
  final List<ClientModel> items;
  final bool? filteredStatus;
  final String? zoneId;
  final String query;
  final String? errorMessage;
  final int total;

  ClientsState copyWith({
    ClientsStatus? status,
    List<ClientModel>? items,
    bool? filteredStatus,
    String? zoneId,
    bool clearFilter = false,
    bool clearZone = false,
    String? query,
    String? errorMessage,
    int? total,
  }) {
    return ClientsState(
      status: status ?? this.status,
      items: items ?? this.items,
      filteredStatus: clearFilter ? null : filteredStatus ?? this.filteredStatus,
      zoneId: clearZone ? null : zoneId ?? this.zoneId,
      query: query ?? this.query,
      errorMessage: errorMessage,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [status, items, filteredStatus, zoneId, query, errorMessage, total];
}
