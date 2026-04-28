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
  final Map<String, List<ProductModel>> _cache = {};

  Future<void> load({bool forceRefresh = false}) async {
    final cacheKey = '${state.query.trim()}|${state.filterActive?.toString() ?? 'all'}|${state.filterLowStock}';
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      emit(state.copyWith(status: ProductsStatus.success, items: _cache[cacheKey], errorMessage: null));
      return;
    }

    emit(state.copyWith(status: ProductsStatus.loading, errorMessage: null));
    try {
      final items = await _repository.list(
        query: state.query,
        isActive: state.filterActive,
        lowStock: state.filterLowStock,
      );
      _cache[cacheKey] = items;
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
    _cache.clear();
    await load(forceRefresh: true);
  }

  Future<void> deactivate(String id) async {
    await _repository.deactivate(id);
    _cache.clear();
    await load(forceRefresh: true);
  }

  Future<List<ProductCategory>> listCategories({bool includeInactive = false}) {
    return _repository.listCategories(includeInactive: includeInactive);
  }

  Future<void> saveCategory({String? id, required String name, String? description}) async {
    await _repository.saveCategory(id: id, name: name, description: description);
    _cache.clear();
    await load(forceRefresh: true);
  }

  Future<void> deactivateCategory(String id) async {
    await _repository.deactivateCategory(id);
    _cache.clear();
    await load(forceRefresh: true);
  }

  Future<void> activateCategory(String id) async {
    await _repository.activateCategory(id);
    _cache.clear();
    await load(forceRefresh: true);
  }

  Future<int> moveCategoryProducts({required String id, required String categoryId}) {
    return _repository.moveCategoryProducts(id: id, categoryId: categoryId);
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    _cache.clear();
    await load(forceRefresh: true);
  }

  Future<List<ProductVariantModel>> listVariants(String productId) => _repository.listVariants(productId);
  Future<void> saveVariant(String productId, ProductVariantModel variant, {String? variantId}) => _repository.saveVariant(productId, variant, variantId: variantId);
  Future<void> setVariantActive(String variantId, bool active) => _repository.setVariantActive(variantId, active);
  Future<void> deleteVariant(String variantId) => _repository.deleteVariant(variantId);

  Future<void> refreshAfterVariantMutation() async {
    _cache.clear();
    if (state.status == ProductsStatus.success || state.status == ProductsStatus.failure) {
      await load(forceRefresh: true);
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
