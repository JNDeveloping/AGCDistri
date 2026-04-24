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
    icon: Icons.dashboard_rounded,
    roles: ['admin', 'vendedor', 'repartidor'],
  );

  static const clients = AppModule(
    key: 'clientes',
    label: 'Clientes',
    route: '/clientes',
    icon: Icons.groups_rounded,
    roles: ['admin', 'vendedor', 'repartidor'],
  );

  static const products = AppModule(
    key: 'productos',
    label: 'Productos',
    route: '/productos',
    icon: Icons.inventory_2_rounded,
    roles: ['admin', 'vendedor', 'repartidor'],
  );

  static const companySettings = AppModule(
    key: 'company-settings',
    label: 'Empresa',
    route: '/company-settings',
    icon: Icons.business_rounded,
    roles: ['admin'],
  );

  static const modules = [dashboard, clients, products, companySettings];

  static List<AppModule> modulesForRole(String role) {
    return modules.where((module) => module.roles.contains(role)).toList();
  }
}
