import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/stock_repository.dart';
import 'stock_state.dart';

class StockCubit extends Cubit<StockState> {
  StockCubit({required StockRepository repository}) : _repository = repository, super(const StockState());

  final StockRepository _repository;
  Timer? _debounce;

  Future<void> load() async {
    emit(state.copyWith(status: StockStatus.loading, error: null));
    try {
      final items = await _repository.list(
        q: state.query,
        lowStock: state.filter == 'low',
        outOfStock: state.filter == 'out',
      );
      emit(state.copyWith(status: StockStatus.success, items: items));
    } on StockException catch (e) {
      emit(state.copyWith(status: StockStatus.failure, error: e.message));
    }
  }

  void onSearch(String value) {
    emit(state.copyWith(query: value));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), load);
  }

  Future<void> setFilter(String filter) async {
    emit(state.copyWith(filter: filter));
    await load();
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
