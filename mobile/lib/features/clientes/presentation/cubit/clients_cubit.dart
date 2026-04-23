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

  Future<void> load() async {
    emit(state.copyWith(status: ClientsStatus.loading, errorMessage: null));
    try {
      final result = await _clientRepository.list(
        query: state.query,
        isActive: state.filteredStatus,
      );

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

  Future<void> deactivate(String id) async {
    await _clientRepository.deactivate(id);
    await load();
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

    await load();
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
