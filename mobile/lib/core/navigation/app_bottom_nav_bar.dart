import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'module_registry.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.currentRoute,
    required this.role,
    super.key,
  });

  final String currentRoute;
  final String role;

  @override
  Widget build(BuildContext context) {
    final modules = ModuleRegistry.modulesForRole(role);
    final currentIndex = modules.indexWhere((module) => module.route == currentRoute);

    return NavigationBar(
      selectedIndex: currentIndex < 0 ? 0 : currentIndex,
      destinations: modules
          .map(
            (module) => NavigationDestination(
              icon: Icon(module.icon),
              label: module.label,
            ),
          )
          .toList(),
      onDestinationSelected: (index) {
        context.go(modules[index].route);
      },
    );
  }
}
