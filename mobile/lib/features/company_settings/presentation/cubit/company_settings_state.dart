import 'package:equatable/equatable.dart';

import '../../domain/models/company_settings_model.dart';

enum CompanySettingsStatus { initial, loading, success, saving, failure }

class CompanySettingsState extends Equatable {
  const CompanySettingsState({
    this.status = CompanySettingsStatus.initial,
    this.settings = CompanySettingsModel.defaults,
    this.errorMessage,
  });

  final CompanySettingsStatus status;
  final CompanySettingsModel settings;
  final String? errorMessage;

  CompanySettingsState copyWith({
    CompanySettingsStatus? status,
    CompanySettingsModel? settings,
    String? errorMessage,
  }) {
    return CompanySettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, settings, errorMessage];
}
