import 'package:dio/dio.dart';

import '../../domain/models/client_model.dart';
import '../datasources/client_remote_datasource.dart';

class ClientRepository {
  ClientRepository({required ClientRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  final ClientRemoteDataSource _remoteDataSource;

  Future<ClientListResponse> list({required String query, bool? isActive, int page = 1}) async {
    try {
      final payload = await _remoteDataSource.fetchClients(query: query, isActive: isActive, page: page);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      final items = (data['items'] as List<dynamic>? ?? [])
          .map((raw) => ClientModel.fromJson(raw as Map<String, dynamic>))
          .toList();

      return ClientListResponse(
        items: items,
        total: data['total'] as int? ?? items.length,
        page: data['page'] as int? ?? page,
        limit: data['limit'] as int? ?? 20,
      );
    } on DioException catch (error) {
      throw ClientException(_extractMessage(error));
    }
  }

  Future<ClientModel> getById(String id) async {
    try {
      final payload = await _remoteDataSource.getClient(id);
      final data = payload['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw ClientException('Cliente no encontrado.');
      }
      return ClientModel.fromJson(data);
    } on DioException catch (error) {
      throw ClientException(_extractMessage(error));
    }
  }

  Future<ClientModel> create(ClientModel client) async {
    try {
      final payload = await _remoteDataSource.createClient(client.toJson());
      final data = payload['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw ClientException('No se pudo crear el cliente.');
      }
      return ClientModel.fromJson(data);
    } on DioException catch (error) {
      throw ClientException(_extractMessage(error));
    }
  }

  Future<ClientModel> update(String id, ClientModel client) async {
    try {
      final payload = await _remoteDataSource.updateClient(id, client.toJson());
      final data = payload['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw ClientException('No se pudo actualizar el cliente.');
      }
      return ClientModel.fromJson(data);
    } on DioException catch (error) {
      throw ClientException(_extractMessage(error));
    }
  }

  Future<ClientModel> deactivate(String id) async {
    try {
      final payload = await _remoteDataSource.deactivateClient(id);
      final data = payload['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw ClientException('No se pudo desactivar el cliente.');
      }
      return ClientModel.fromJson(data);
    } on DioException catch (error) {
      throw ClientException(_extractMessage(error));
    }
  }

  Future<ClientModel> activate(String id) async {
    try {
      final payload = await _remoteDataSource.activateClient(id);
      final data = payload['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw ClientException('No se pudo activar el cliente.');
      }
      return ClientModel.fromJson(data);
    } on DioException catch (error) {
      throw ClientException(_extractMessage(error));
    }
  }

  Future<void> delete(String id) async {
    try {
      await _remoteDataSource.deleteClient(id);
    } on DioException catch (error) {
      throw ClientException(_extractMessage(error));
    }
  }

  Future<List<ClientZone>> listZones({bool includeInactive = false}) async {
    try {
      final payload = await _remoteDataSource.listZones(includeInactive: includeInactive);
      return (payload['data'] as List<dynamic>? ?? [])
          .map((raw) => ClientZone.fromJson(raw as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ClientException(_extractMessage(error));
    }
  }

  Future<ClientZone> createZone({required String name, String? description}) async {
    try {
      final payload = await _remoteDataSource.createZone(name: name, description: description);
      final data = payload['data'] as Map<String, dynamic>?;
      if (data == null) throw ClientException('No se pudo crear la zona.');
      return ClientZone.fromJson(data);
    } on DioException catch (error) {
      throw ClientException(_extractMessage(error));
    }
  }

  Future<ClientZone> updateZone({required String id, required String name, String? description}) async {
    try {
      final payload = await _remoteDataSource.updateZone(id, name: name, description: description);
      final data = payload['data'] as Map<String, dynamic>?;
      if (data == null) throw ClientException('No se pudo actualizar la zona.');
      return ClientZone.fromJson(data);
    } on DioException catch (error) {
      throw ClientException(_extractMessage(error));
    }
  }

  Future<ClientZone> deactivateZone(String id) async {
    try {
      final payload = await _remoteDataSource.deactivateZone(id);
      final data = payload['data'] as Map<String, dynamic>?;
      if (data == null) throw ClientException('No se pudo desactivar la zona.');
      return ClientZone.fromJson(data);
    } on DioException catch (error) {
      throw ClientException(_extractMessage(error));
    }
  }

  Future<int> moveZoneClients({required String id, required String zoneId}) async {
    try {
      final payload = await _remoteDataSource.moveZoneClients(id, zoneId: zoneId);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      return data['moved'] as int? ?? 0;
    } on DioException catch (error) {
      throw ClientException(_extractMessage(error));
    }
  }

  Future<void> deleteZone(String id) async {
    try {
      await _remoteDataSource.deleteZone(id);
    } on DioException catch (error) {
      throw ClientException(_extractMessage(error));
    }
  }

  String _extractMessage(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      return (error.response?.data['message'] as String?) ?? 'Error en módulo clientes.';
    }
    return 'No se pudo conectar con el módulo clientes.';
  }
}

class ClientListResponse {
  const ClientListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<ClientModel> items;
  final int total;
  final int page;
  final int limit;
}

class ClientException implements Exception {
  ClientException(this.message);
  final String message;
}

class ClientZone {
  const ClientZone({
    required this.id,
    required this.name,
    required this.isActive,
    this.description,
  });

  final String id;
  final String name;
  final bool isActive;
  final String? description;

  factory ClientZone.fromJson(Map<String, dynamic> json) => ClientZone(
        id: json['id'] as String,
        name: json['name'] as String,
        isActive: json['isActive'] as bool? ?? true,
        description: json['description'] as String?,
      );
}
