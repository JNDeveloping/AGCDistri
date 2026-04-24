import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/order_repository.dart';
import '../../domain/models/order_model.dart';
import 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit({required OrderRepository repository}) : _repository = repository, super(const OrdersState());

  final OrderRepository _repository;
  Timer? _debounce;

  Future<void> load() async {
    emit(state.copyWith(status: OrdersStatus.loading, errorMessage: null));
    try {
      final items = await _repository.list(status: state.statusFilter, query: state.query);
      emit(state.copyWith(status: OrdersStatus.success, items: items));
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
    await load();
    return saved;
  }

  Future<OrderModel> cancel(String id) async {
    final updated = await _repository.cancel(id);
    await load();
    return updated;
  }

  Future<OrderModel> changeStatus(String id, String status) async {
    final updated = await _repository.changeStatus(id, status);
    await load();
    return updated;
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }

  Future<List<OrderClientLookup>> searchClients(String query) => _repository.searchClients(query);
  Future<List<OrderProductLookup>> searchProducts(String query) => _repository.searchProducts(query);

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
