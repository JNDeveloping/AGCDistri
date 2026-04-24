import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  const DashboardStats({
    required this.totalClients,
    required this.activeClients,
    required this.totalProducts,
    required this.activeProducts,
    required this.lowStockProducts,
    required this.recentClients,
    required this.recentProducts,
  });

  final int totalClients;
  final int activeClients;
  final int totalProducts;
  final int activeProducts;
  final int lowStockProducts;
  final List<Map<String, dynamic>> recentClients;
  final List<Map<String, dynamic>> recentProducts;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final clients = json['clients'] as Map<String, dynamic>? ?? {};
    final products = json['products'] as Map<String, dynamic>? ?? {};

    return DashboardStats(
      totalClients: clients['total'] as int? ?? 0,
      activeClients: clients['active'] as int? ?? 0,
      totalProducts: products['total'] as int? ?? 0,
      activeProducts: products['active'] as int? ?? 0,
      lowStockProducts: json['lowStockProducts'] as int? ?? 0,
      recentClients: (json['recentClients'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      recentProducts: (json['recentProducts'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
    );
  }

  @override
  List<Object?> get props => [
        totalClients,
        activeClients,
        totalProducts,
        activeProducts,
        lowStockProducts,
        recentClients,
        recentProducts,
      ];
}
