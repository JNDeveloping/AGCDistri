import 'package:dio/dio.dart';

import '../../domain/models/credit_note_model.dart';
import '../datasources/credit_note_remote_datasource.dart';

class CreditNoteRepository {
  CreditNoteRepository({required CreditNoteRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  final CreditNoteRemoteDataSource _remoteDataSource;

  Future<List<CreditNoteModel>> listByOrder(String orderId) async {
    try {
      final payload = await _remoteDataSource.listByOrder(orderId);
      final data = payload['data'];
      final list = data is List<dynamic> ? data : <dynamic>[];
      return list.map((e) => CreditNoteModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<CreditNoteModel> getById(String id) async {
    try {
      final payload = await _remoteDataSource.getById(id);
      return CreditNoteModel.fromJson(payload['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<CreditNoteModel> create({
    required String orderId,
    required String reason,
    String? notes,
    required bool affectsStock,
    required bool affectsAccount,
    required List<CreditNoteItemInput> items,
  }) async {
    try {
      final payload = await _remoteDataSource.create({
        'orderId': orderId,
        'reason': reason,
        'notes': notes,
        'affectsStock': affectsStock,
        'affectsAccount': affectsAccount,
        'items': items.map((i) => i.toJson()).toList(),
      });
      return CreditNoteModel.fromJson(payload['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Exception _mapError(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response?.data as Map<String, dynamic>;
      return Exception((data['message'] as String?) ?? 'Error al procesar la nota de crédito.');
    }
    return Exception('No se pudo conectar con notas de crédito.');
  }
}
