import 'package:equatable/equatable.dart';

import '../../domain/models/order_model.dart';

enum OrdersStatus { initial, loading, success, failure }

class OrdersState extends Equatable {
  const OrdersState({
    this.status = OrdersStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.query = '',
    this.statusFilter,
  });

  final OrdersStatus status;
  final List<OrderModel> items;
  final String? errorMessage;
  final String query;
  final String? statusFilter;

  OrdersState copyWith({OrdersStatus? status, List<OrderModel>? items, String? errorMessage, String? query, String? statusFilter}) {
    return OrdersState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      query: query ?? this.query,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage, query, statusFilter];
}
