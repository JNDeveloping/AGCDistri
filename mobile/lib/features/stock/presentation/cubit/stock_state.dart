import 'package:equatable/equatable.dart';

import '../../domain/models/stock_models.dart';

enum StockStatus { initial, loading, success, failure }

class StockState extends Equatable {
  const StockState({this.status = StockStatus.initial, this.items = const [], this.query = '', this.filter = 'all', this.error});

  final StockStatus status;
  final List<StockItem> items;
  final String query;
  final String filter;
  final String? error;

  StockState copyWith({StockStatus? status, List<StockItem>? items, String? query, String? filter, String? error}) => StockState(
        status: status ?? this.status,
        items: items ?? this.items,
        query: query ?? this.query,
        filter: filter ?? this.filter,
        error: error,
      );

  @override
  List<Object?> get props => [status, items, query, filter, error];
}
