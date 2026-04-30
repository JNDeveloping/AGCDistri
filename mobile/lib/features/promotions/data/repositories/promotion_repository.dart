import 'package:dio/dio.dart';
import '../../domain/models/promotion_model.dart';
import '../datasources/promotion_remote_datasource.dart';

class PromotionRepository {
  PromotionRepository({required PromotionRemoteDataSource remote}) : _remote = remote;
  final PromotionRemoteDataSource _remote;

  Future<List<PromotionModel>> list({String? q, bool? isActive, String? type}) async {
    try {
      final p = await _remote.list(q: q, isActive: isActive, type: type);
      final data = p['data'];
      final items = data is List ? data : (data is Map<String, dynamic> ? data['items'] as List<dynamic>? ?? [] : []);
      return items.map((e) => PromotionModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) { throw Exception((e.response?.data as Map<String,dynamic>?)?['message'] ?? 'Error al listar promociones'); }
  }
  Future<PromotionModel> getById(String id) async {
    final p = await _remote.getById(id);
    return PromotionModel.fromJson(p['data'] as Map<String, dynamic>);
  }
  Future<void> save(Map<String,dynamic> data, {String? id}) async => id == null ? _remote.create(data) : _remote.update(id, data);
  Future<void> archive(String id) => _remote.archive(id);
  Future<void> toggle(String id) => _remote.toggle(id);
}
