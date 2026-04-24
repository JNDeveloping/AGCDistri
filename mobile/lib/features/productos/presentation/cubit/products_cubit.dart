import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/product_repository.dart';
import '../../domain/models/product_model.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit({required ProductRepository repository})
      : _repository = repository,
        super(const ProductsState());

  final ProductRepository _repository;
  Timer? _debounce;

  Future<void> load() async {
    emit(state.copyWith(status: ProductsStatus.loading, errorMessage: null));
    try {
      final items = await _repository.list(
        query: state.query,
        isActive: state.filterActive,
        lowStock: state.filterLowStock,
      );
      emit(state.copyWith(status: ProductsStatus.success, items: items));
    } on ProductException catch (error) {
      emit(state.copyWith(status: ProductsStatus.failure, errorMessage: error.message));
    }
  }

  void onSearch(String value) {
    emit(state.copyWith(query: value));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), load);
  }

  Future<void> setActiveFilter(bool? value) async {
    emit(state.copyWith(filterActive: value, clearActive: value == null));
    await load();
  }

  Future<void> setLowStockFilter(bool value) async {
    emit(state.copyWith(filterLowStock: value));
    await load();
  }

  Future<ProductModel> getById(String id) => _repository.getById(id);

  Future<void> save(ProductModel model, {String? id}) async {
    await _repository.save(model, id: id);
    await load();
  }

  Future<void> deactivate(String id) async {
    await _repository.deactivate(id);
    await load();
  }

  Future<List<ProductCategory>> listCategories({bool includeInactive = false}) {
    return _repository.listCategories(includeInactive: includeInactive);
  }

  Future<void> saveCategory({String? id, required String name, String? description}) {
    return _repository.saveCategory(id: id, name: name, description: description);
  }

  Future<void> deactivateCategory(String id) {
    return _repository.deactivateCategory(id);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
