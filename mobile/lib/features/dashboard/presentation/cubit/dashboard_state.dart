import 'package:equatable/equatable.dart';

import '../../domain/models/dashboard_stats.dart';

enum DashboardStatus { initial, loading, success, failure }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.stats,
    this.errorMessage,
  });

  final DashboardStatus status;
  final DashboardStats? stats;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardStats? stats,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, stats, errorMessage];
}
