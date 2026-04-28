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

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        destinations: modules
            .map(
              (module) => NavigationDestination(
                icon: Icon(module.icon, size: 23),
                selectedIcon: Icon(module.icon, size: 24),
                label: module.label,
              ),
            )
            .toList(),
        onDestinationSelected: (index) => context.go(modules[index].route),
      ),
    );
  }
}
