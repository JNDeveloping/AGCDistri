import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/client_repository.dart';
import '../../domain/models/client_model.dart';
import 'clients_state.dart';

class ClientsCubit extends Cubit<ClientsState> {
  ClientsCubit({required ClientRepository clientRepository})
      : _clientRepository = clientRepository,
        super(const ClientsState());

  final ClientRepository _clientRepository;
  Timer? _debounce;
  final Map<String, ClientListResponse> _cache = {};

  Future<void> load({bool forceRefresh = false}) async {
    final cacheKey = '${state.query.trim()}|${state.filteredStatus ?? 'all'}|${state.zoneId ?? 'all'}';
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      emit(
        state.copyWith(
          status: ClientsStatus.success,
          items: cached.items,
          total: cached.total,
          errorMessage: null,
        ),
      );
      return;
    }

    emit(state.copyWith(status: ClientsStatus.loading, errorMessage: null));
    try {
      final result = await _clientRepository.list(
        query: state.query,
        isActive: state.filteredStatus,
        zoneId: state.zoneId,
      );
      _cache[cacheKey] = result;

      emit(
        state.copyWith(
          status: ClientsStatus.success,
          items: result.items,
          total: result.total,
          errorMessage: null,
        ),
      );
    } on ClientException catch (error) {
      emit(state.copyWith(status: ClientsStatus.failure, errorMessage: error.message));
    }
  }

  void onSearchChanged(String value) {
    emit(state.copyWith(query: value));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 380), load);
  }

  Future<void> applyFilter(bool? isActive) async {
    emit(state.copyWith(filteredStatus: isActive, clearFilter: isActive == null));
    await load();
  }

  Future<void> setZoneFilter(String? zoneId) async {
    emit(state.copyWith(zoneId: zoneId, clearZone: zoneId == null));
    await load();
  }

  Future<void> deactivate(String id) async {
    await _clientRepository.deactivate(id);
    _cache.clear();
    await load(forceRefresh: true);
  }

  Future<void> activate(String id) async {
    await _clientRepository.activate(id);
    _cache.clear();
    await load(forceRefresh: true);
  }

  Future<void> delete(String id) async {
    await _clientRepository.delete(id);
    _cache.clear();
    await load(forceRefresh: true);
  }

  Future<ClientModel> getById(String id) {
    return _clientRepository.getById(id);
  }

  Future<void> saveClient({required ClientModel payload, String? id}) async {
    if (id == null) {
      await _clientRepository.create(payload);
    } else {
      await _clientRepository.update(id, payload);
    }

    _cache.clear();
    await load(forceRefresh: true);
  }

  Future<List<ClientZone>> listZones({bool includeInactive = false}) {
    return _clientRepository.listZones(includeInactive: includeInactive);
  }

  Future<ClientZone> createZone({required String name, String? description}) {
    return _clientRepository.createZone(name: name, description: description);
  }

  Future<ClientZone> updateZone({required String id, required String name, String? description}) {
    return _clientRepository.updateZone(id: id, name: name, description: description);
  }

  Future<ClientZone> deactivateZone(String id) {
    return _clientRepository.deactivateZone(id);
  }

  Future<ClientZone> activateZone(String id) {
    return _clientRepository.activateZone(id);
  }

  Future<int> moveZoneClients({required String id, required String zoneId}) {
    return _clientRepository.moveZoneClients(id: id, zoneId: zoneId);
  }

  Future<void> deleteZone(String id) {
    return _clientRepository.deleteZone(id);
  }

  Future<void> refreshAfterZoneMutation() async {
    _cache.clear();
    await load(forceRefresh: true);
  }

  Future<ZoneSummary> getZoneSummary(String id) => _clientRepository.getZoneSummary(id);

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
