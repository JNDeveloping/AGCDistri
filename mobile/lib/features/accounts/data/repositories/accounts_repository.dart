import 'package:dio/dio.dart';

import '../../domain/models/account_models.dart';
import '../datasources/accounts_remote_datasource.dart';

class AccountsRepository {
  AccountsRepository({required AccountsRemoteDataSource remoteDataSource}) : _remote = remoteDataSource;
  final AccountsRemoteDataSource _remote;

  Future<ClientAccount> account(String clientId) async {
    try {
      final payload = await _remote.account(clientId);
      return ClientAccount.fromJson(payload['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AccountsException(_msg(e));
    }
  }

  Future<List<AccountMovement>> movements(String clientId, {String? type, String? dateFrom, String? dateTo}) async {
    try {
      final payload = await _remote.movements(clientId, type: type, dateFrom: dateFrom, dateTo: dateTo);
      return (payload['data'] as List<dynamic>? ?? []).map((e) => AccountMovement.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AccountsException(_msg(e));
    }
  }

  Future<void> registerPayment({required String clientId, required double amount, required String paymentMethod, String? notes}) async {
    try {
      await _remote.createPayment({'clientId': clientId, 'amount': amount, 'paymentMethod': paymentMethod, 'notes': notes});
    } on DioException catch (e) {
      throw AccountsException(_msg(e));
    }
  }

  Future<void> adjustBalance({required String clientId, required double amount, required String description, String? notes}) async {
    try {
      await _remote.adjust(clientId, {'amount': amount, 'description': description, 'notes': notes});
    } on DioException catch (e) {
      throw AccountsException(_msg(e));
    }
  }

  Future<ClientPayment> getPaymentById(String paymentId) async {
    try {
      final payload = await _remote.paymentById(paymentId);
      return ClientPayment.fromJson(payload['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw AccountsException(_msg(e));
    }
  }

  String _msg(DioException e) {
    if (e.response?.data is Map<String, dynamic>) return (e.response?.data['message'] as String?) ?? 'Error cuenta corriente.';
    return 'No se pudo conectar con cuenta corriente.';
  }
}

class AccountsException implements Exception {
  AccountsException(this.message);
  final String message;

  @override
  String toString() => message;
}
