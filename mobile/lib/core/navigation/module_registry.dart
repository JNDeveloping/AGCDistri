import 'package:flutter/material.dart';

class AppModule {
  const AppModule({
    required this.key,
    required this.label,
    required this.route,
    required this.icon,
    required this.roles,
  });

  final String key;
  final String label;
  final String route;
  final IconData icon;
  final List<String> roles;
}

class ModuleRegistry {
  static const dashboard = AppModule(
    key: 'dashboard',
    label: 'Inicio',
    route: '/dashboard',
    icon: Icons.home_rounded,
    roles: ['admin', 'vendedor', 'repartidor'],
  );

  static const orders = AppModule(
    key: 'pedidos',
    label: 'Pedidos',
    route: '/pedidos',
    icon: Icons.shopping_cart_checkout_rounded,
    roles: ['admin', 'vendedor', 'repartidor'],
  );

  static const clients = AppModule(
    key: 'clientes',
    label: 'Clientes',
    route: '/clientes',
    icon: Icons.groups_rounded,
    roles: ['admin', 'vendedor', 'repartidor'],
  );

  static const stock = AppModule(
    key: 'stock',
    label: 'Stock',
    route: '/stock',
    icon: Icons.inventory_rounded,
    roles: ['admin', 'vendedor', 'repartidor'],
  );

  static const accounts = AppModule(
    key: 'cuentas_corrientes',
    label: 'Cuentas corrientes',
    route: '/cuentas-corrientes',
    icon: Icons.account_balance_wallet_rounded,
    roles: ['admin', 'vendedor', 'repartidor'],
  );

  static const reports = AppModule(
    key: 'reportes',
    label: 'Reportes',
    route: '/reportes',
    icon: Icons.bar_chart_rounded,
    roles: ['admin', 'vendedor'],
  );

  static const products = AppModule(
    key: 'productos',
    label: 'Productos',
    route: '/productos',
    icon: Icons.inventory_2_rounded,
    roles: ['admin', 'vendedor', 'repartidor'],
  );

  static const users = AppModule(
    key: 'usuarios',
    label: 'Usuarios',
    route: '/profile/users',
    icon: Icons.admin_panel_settings_outlined,
    roles: ['admin'],
  );

  static const zones = AppModule(
    key: 'zonas',
    label: 'Zonas',
    route: '/profile/zones',
    icon: Icons.route_rounded,
    roles: ['admin'],
  );

  static const categories = AppModule(
    key: 'categorias',
    label: 'Categorías',
    route: '/profile/categories',
    icon: Icons.category_rounded,
    roles: ['admin'],
  );

  static const company = AppModule(
    key: 'empresa',
    label: 'Empresa',
    route: '/company-settings',
    icon: Icons.business_rounded,
    roles: ['admin'],
  );

  static const profile = AppModule(
    key: 'profile',
    label: 'Perfil',
    route: '/profile',
    icon: Icons.person_rounded,
    roles: ['admin', 'vendedor', 'repartidor'],
  );

  static const bottomModules = [dashboard, orders, clients, stock];
  static const managementModules = [accounts, reports, products, users, zones, categories, company];

  static List<AppModule> modulesForRole(String role) {
    return bottomModules.where((module) => module.roles.contains(role)).toList();
  }

  static List<AppModule> managementForRole(String role) {
    return managementModules.where((module) => module.roles.contains(role)).toList();
  }
}
