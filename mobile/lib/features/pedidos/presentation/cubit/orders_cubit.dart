import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/order_repository.dart';
import '../../domain/models/order_model.dart';
import 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit({required OrderRepository repository}) : _repository = repository, super(const OrdersState());

  final OrderRepository _repository;
  Timer? _debounce;
  final Map<String, List<OrderModel>> _cache = {};

  Future<void> load({bool forceRefresh = false}) async {
    final cacheKey = [
      state.statusFilter ?? 'all',
      state.query.trim(),
      state.dateFrom ?? '-',
      state.dateTo ?? '-',
      state.paymentCondition ?? '-',
      state.zoneId ?? '-',
      state.sortBy,
      state.sortDirection,
    ].join('|');
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      emit(state.copyWith(status: OrdersStatus.success, items: _cache[cacheKey], errorMessage: null));
      return;
    }

    emit(state.copyWith(status: OrdersStatus.loading, errorMessage: null));
    try {
      final result = await _repository.list(
        status: state.statusFilter,
        search: state.query.trim().isEmpty ? null : state.query.trim(),
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        paymentCondition: state.paymentCondition,
        zoneId: state.zoneId,
        sortBy: state.sortBy,
        sortDirection: state.sortDirection,
      );
      _cache[cacheKey] = result.items;
      emit(state.copyWith(status: OrdersStatus.success, items: result.items, countsByStatus: result.countsByStatus));
    } on OrderException catch (e) {
      emit(state.copyWith(status: OrdersStatus.failure, errorMessage: e.message));
    }
  }

  void onSearch(String value) {
    emit(state.copyWith(query: value));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), load);
  }

  Future<void> setStatusFilter(String? status) async {
    emit(state.copyWith(statusFilter: status, clearStatusFilter: status == null));
    await load();
  }

  Future<void> setPaymentCondition(String? value) async {
    emit(state.copyWith(paymentCondition: value, clearPaymentCondition: value == null));
    await load();
  }

  Future<void> setDateRange({String? from, String? to}) async {
    emit(state.copyWith(dateFrom: from, dateTo: to, clearDateRange: from == null && to == null));
    await load();
  }

  Future<void> setSorting({required String sortBy, required String sortDirection}) async {
    emit(state.copyWith(sortBy: sortBy, sortDirection: sortDirection));
    await load();
  }

  void setGroupBy(String groupBy) {
    emit(state.copyWith(groupBy: groupBy));
  }

  Future<void> setZoneFilter(String? zoneId) async {
    emit(state.copyWith(zoneId: zoneId));
    await load();
  }

  Future<OrderModel> getById(String id) => _repository.getById(id);

  Future<OrderModel> save({
    String? id,
    required String clientId,
    required List<OrderItemInput> items,
    double discountTotal = 0,
    String? paymentTerms,
    String? notes,
  }) async {
    final saved = await _repository.save(
      id: id,
      clientId: clientId,
      items: items,
      discountTotal: discountTotal,
      paymentTerms: paymentTerms,
      notes: notes,
    );
    _cache.clear();
    await load(forceRefresh: true);
    return saved;
  }

  Future<OrderModel> cancel(String id) async {
    final updated = await _repository.cancel(id);
    _cache.clear();
    await load(forceRefresh: true);
    return updated;
  }

  Future<OrderModel> changeStatus(String id, String status) async {
    final updated = await _repository.changeStatus(id, status);
    _cache.clear();
    await load(forceRefresh: true);
    return updated;
  }

  Future<OrderStockValidation> validateStock(String id) => _repository.validateStock(id);

  Future<void> delete(String id) async {
    await _repository.delete(id);
    _cache.clear();
    await load(forceRefresh: true);
  }

  Future<List<OrderClientLookup>> searchClients(String query) => _repository.searchClients(query);
  Future<List<OrderProductLookup>> searchProducts(String query) => _repository.searchProducts(query);
  Future<List<OrderProductVariantLookup>> searchProductVariants(String productId) => _repository.searchProductVariants(productId);
  Future<List<ClientPurchaseHistoryItem>> getPurchaseHistory(String clientId) => _repository.getPurchaseHistory(clientId);
  Future<List<SuggestedProductItem>> getSuggestedProducts(String clientId) => _repository.getSuggestedProducts(clientId);
  Future<ClientLastOrderSuggestion> getLastOrder(String clientId) => _repository.getLastOrder(clientId);

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
