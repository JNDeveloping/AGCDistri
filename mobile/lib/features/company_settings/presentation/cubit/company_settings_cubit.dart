import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/company_settings_repository.dart';
import '../../domain/models/company_settings_model.dart';
import 'company_settings_state.dart';

class CompanySettingsCubit extends Cubit<CompanySettingsState> {
  CompanySettingsCubit({required CompanySettingsRepository repository})
      : _repository = repository,
        super(const CompanySettingsState());

  final CompanySettingsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: CompanySettingsStatus.loading, errorMessage: null));
    try {
      final settings = await _repository.getSettings();
      emit(state.copyWith(status: CompanySettingsStatus.success, settings: settings));
    } on CompanySettingsException catch (error) {
      emit(state.copyWith(status: CompanySettingsStatus.failure, errorMessage: error.message));
    }
  }

  Future<void> save(CompanySettingsModel model) async {
    emit(state.copyWith(status: CompanySettingsStatus.saving, errorMessage: null));
    try {
      final saved = await _repository.saveSettings(model);
      emit(state.copyWith(status: CompanySettingsStatus.success, settings: saved));
    } on CompanySettingsException catch (error) {
      emit(state.copyWith(status: CompanySettingsStatus.failure, errorMessage: error.message));
      rethrow;
    }
  }

  Future<void> resetDefaults() async {
    emit(state.copyWith(status: CompanySettingsStatus.saving, errorMessage: null));
    try {
      final defaults = await _repository.resetDefaults();
      emit(state.copyWith(status: CompanySettingsStatus.success, settings: defaults));
    } on CompanySettingsException catch (error) {
      emit(state.copyWith(status: CompanySettingsStatus.failure, errorMessage: error.message));
      rethrow;
    }
  }

  double suggestedWholesalePrice(double cost) {
    final percentage = state.settings.defaultProfitPercentage;
    final raw = cost + (cost * percentage / 100);
    if (!state.settings.priceRoundingEnabled) return raw;
    final m = state.settings.priceRoundingMultiple;
    return (raw / m).ceil() * m.toDouble();
  }
}
