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
    this.dateFrom,
    this.dateTo,
    this.paymentCondition,
    this.zoneId,
    this.sortBy = 'orderDate',
    this.sortDirection = 'desc',
    this.groupBy = 'none',
    this.countsByStatus = const {},
  });

  final OrdersStatus status;
  final List<OrderModel> items;
  final String? errorMessage;
  final String query;
  final String? statusFilter;
  final String? dateFrom;
  final String? dateTo;
  final String? paymentCondition;
  final String? zoneId;
  final String sortBy;
  final String sortDirection;
  final String groupBy;
  final Map<String, int> countsByStatus;

  OrdersState copyWith({
    OrdersStatus? status,
    List<OrderModel>? items,
    String? errorMessage,
    String? query,
    String? statusFilter,
    String? dateFrom,
    String? dateTo,
    String? paymentCondition,
    String? zoneId,
    String? sortBy,
    String? sortDirection,
    String? groupBy,
    Map<String, int>? countsByStatus,
    bool clearDateRange = false,
    bool clearPaymentCondition = false,
    bool clearStatusFilter = false,
  }) {
    return OrdersState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      query: query ?? this.query,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      dateFrom: clearDateRange ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateRange ? null : (dateTo ?? this.dateTo),
      paymentCondition: clearPaymentCondition ? null : (paymentCondition ?? this.paymentCondition),
      zoneId: zoneId ?? this.zoneId,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      groupBy: groupBy ?? this.groupBy,
      countsByStatus: countsByStatus ?? this.countsByStatus,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage, query, statusFilter, dateFrom, dateTo, paymentCondition, zoneId, sortBy, sortDirection, groupBy, countsByStatus];
}
