import 'package:equatable/equatable.dart';

import '../../domain/models/product_model.dart';

enum ProductsStatus { initial, loading, success, failure }

class ProductsState extends Equatable {
  const ProductsState({
    this.status = ProductsStatus.initial,
    this.items = const [],
    this.query = '',
    this.filterActive,
    this.filterLowStock = false,
    this.errorMessage,
  });

  final ProductsStatus status;
  final List<ProductModel> items;
  final String query;
  final bool? filterActive;
  final bool filterLowStock;
  final String? errorMessage;

  ProductsState copyWith({
    ProductsStatus? status,
    List<ProductModel>? items,
    String? query,
    bool? filterActive,
    bool clearActive = false,
    bool? filterLowStock,
    String? errorMessage,
  }) {
    return ProductsState(
      status: status ?? this.status,
      items: items ?? this.items,
      query: query ?? this.query,
      filterActive: clearActive ? null : filterActive ?? this.filterActive,
      filterLowStock: filterLowStock ?? this.filterLowStock,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, query, filterActive, filterLowStock, errorMessage];
}
