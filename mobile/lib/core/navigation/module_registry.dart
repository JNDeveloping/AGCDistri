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


  static const orders = AppModule(
    key: 'pedidos',
    label: 'Pedidos',
    route: '/pedidos',
    icon: Icons.shopping_cart_checkout_rounded,
    roles: ['admin', 'vendedor', 'repartidor'],
  );

  static const stock = AppModule(
    key: 'stock',
    label: 'Stock',
    route: '/stock',
    icon: Icons.inventory_rounded,
    roles: ['admin', 'vendedor', 'repartidor'],
  );

  static const profile = AppModule(
    key: 'profile',
    label: 'Perfil',
    route: '/profile',
    icon: Icons.person_rounded,
    roles: ['admin', 'vendedor', 'repartidor'],
  );

  static const modules = [dashboard, clients, products, orders, stock, profile];

  static List<AppModule> modulesForRole(String role) {
    return modules.where((module) => module.roles.contains(role)).toList();
  }
}
