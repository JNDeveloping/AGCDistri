import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({required DashboardRepository repository})
      : _repository = repository,
        super(const DashboardState());

  final DashboardRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: DashboardStatus.loading, errorMessage: null));
    try {
      final stats = await _repository.fetchStats();
      emit(state.copyWith(status: DashboardStatus.success, stats: stats));
    } on DashboardException catch (error) {
      emit(state.copyWith(status: DashboardStatus.failure, errorMessage: error.message));
    }
  }
}
