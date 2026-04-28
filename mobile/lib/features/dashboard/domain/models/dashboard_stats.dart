import 'package:equatable/equatable.dart';

class DashboardZoneMetric extends Equatable {
  const DashboardZoneMetric({
    required this.zoneId,
    required this.zoneName,
    required this.sales,
    required this.orders,
    required this.debt,
    required this.clients,
  });

  final String zoneId;
  final String zoneName;
  final double sales;
  final int orders;
  final double debt;
  final int clients;

  factory DashboardZoneMetric.fromJson(Map<String, dynamic> json) => DashboardZoneMetric(
        zoneId: json['zoneId'] as String? ?? '',
        zoneName: json['zoneName'] as String? ?? 'Sin zona',
        sales: (json['sales'] as num?)?.toDouble() ?? 0,
        orders: (json['orders'] as num?)?.toInt() ?? 0,
        debt: (json['debt'] as num?)?.toDouble() ?? 0,
        clients: (json['clients'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [zoneId, zoneName, sales, orders, debt, clients];
}

class DashboardTopProduct extends Equatable {
  const DashboardTopProduct({
    required this.productId,
    required this.productName,
    required this.units,
  });

  final String productId;
  final String productName;
  final double units;

  factory DashboardTopProduct.fromJson(Map<String, dynamic> json) => DashboardTopProduct(
        productId: json['productId'] as String? ?? '',
        productName: json['productName'] as String? ?? 'Producto',
        units: (json['units'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [productId, productName, units];
}

class DashboardStats extends Equatable {
  const DashboardStats({
    required this.salesToday,
    required this.salesMonth,
    required this.pendingOrders,
    required this.preparedOrders,
    required this.deliveryOrders,
    required this.deliveredToday,
    required this.totalDebt,
    required this.clientsWithDebt,
    required this.paymentsToday,
    required this.collectedToday,
    required this.outOfStockProducts,
    required this.lowStockProducts,
    required this.topProducts,
    required this.profitEstimate,
    required this.zones,
  });

  final double salesToday;
  final double salesMonth;
  final int pendingOrders;
  final int preparedOrders;
  final int deliveryOrders;
  final int deliveredToday;
  final double totalDebt;
  final int clientsWithDebt;
  final int paymentsToday;
  final double collectedToday;
  final int outOfStockProducts;
  final int lowStockProducts;
  final List<DashboardTopProduct> topProducts;
  final double profitEstimate;
  final List<DashboardZoneMetric> zones;

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        salesToday: (json['salesToday'] as num?)?.toDouble() ?? 0,
        salesMonth: (json['salesMonth'] as num?)?.toDouble() ?? 0,
        pendingOrders: (json['pendingOrders'] as num?)?.toInt() ?? 0,
        preparedOrders: (json['preparedOrders'] as num?)?.toInt() ?? 0,
        deliveryOrders: (json['deliveryOrders'] as num?)?.toInt() ?? 0,
        deliveredToday: (json['deliveredToday'] as num?)?.toInt() ?? 0,
        totalDebt: (json['totalDebt'] as num?)?.toDouble() ?? 0,
        clientsWithDebt: (json['clientsWithDebt'] as num?)?.toInt() ?? 0,
        paymentsToday: (json['paymentsToday'] as num?)?.toInt() ?? 0,
        collectedToday: (json['collectedToday'] as num?)?.toDouble() ?? 0,
        outOfStockProducts: (json['outOfStockProducts'] as num?)?.toInt() ?? 0,
        lowStockProducts: (json['lowStockProducts'] as num?)?.toInt() ?? 0,
        topProducts: (json['topProducts'] as List<dynamic>? ?? [])
            .map((e) => DashboardTopProduct.fromJson(e as Map<String, dynamic>))
            .toList(),
        profitEstimate: (json['profitEstimate'] as num?)?.toDouble() ?? 0,
        zones: (json['zones'] as List<dynamic>? ?? [])
            .map((e) => DashboardZoneMetric.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [
        salesToday,
        salesMonth,
        pendingOrders,
        preparedOrders,
        deliveryOrders,
        deliveredToday,
        totalDebt,
        clientsWithDebt,
        paymentsToday,
        collectedToday,
        outOfStockProducts,
        lowStockProducts,
        topProducts,
        profitEstimate,
        zones,
      ];
}
