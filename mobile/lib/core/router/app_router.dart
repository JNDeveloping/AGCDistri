import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/accounts/presentation/pages/accounts_overview_page.dart';
import '../../features/clientes/presentation/pages/clientes_page.dart';
import '../../features/company_settings/presentation/pages/company_settings_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/pedidos/presentation/pages/pedidos_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/productos/presentation/pages/productos_page.dart';
import '../../features/stock/presentation/pages/stock_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/users/data/repositories/users_repository.dart';
import '../navigation/module_registry.dart';

class AppRouter {
  AppRouter({required AuthCubit authCubit, required UsersRepository usersRepository})
      : router = GoRouter(
          initialLocation: SplashPage.path,
          refreshListenable: GoRouterRefreshStream(authCubit.stream),
          routes: [
            GoRoute(path: SplashPage.path, name: SplashPage.name, builder: (_, __) => const SplashPage()),
            GoRoute(path: LoginPage.path, name: LoginPage.name, builder: (_, __) => const LoginPage()),
            GoRoute(path: DashboardPage.path, name: DashboardPage.name, builder: (_, __) => const DashboardPage()),
            GoRoute(path: AccountsOverviewPage.path, name: AccountsOverviewPage.name, builder: (_, __) => const AccountsOverviewPage()),
            GoRoute(path: ClientesPage.path, name: ClientesPage.name, builder: (_, __) => const ClientesPage()),
            GoRoute(path: ProductosPage.path, name: ProductosPage.name, builder: (_, __) => const ProductosPage()),
            GoRoute(path: PedidosPage.path, name: PedidosPage.name, builder: (_, __) => const PedidosPage()),
            GoRoute(path: StockPage.path, name: StockPage.name, builder: (_, __) => const StockPage()),
            GoRoute(path: ReportsPage.path, name: ReportsPage.name, builder: (_, __) => const ReportsPage()),
            GoRoute(path: ProfilePage.path, name: ProfilePage.name, builder: (_, __) => ProfilePage(usersRepository: usersRepository)),
            GoRoute(path: CompanySettingsPage.path, name: CompanySettingsPage.name, builder: (_, __) => const CompanySettingsPage()),
          ],
          redirect: (_, state) {
            final status = authCubit.state.status;
            final location = state.matchedLocation;

            if (status == AuthStatus.checking) {
              return location == SplashPage.path ? null : SplashPage.path;
            }

            if (status == AuthStatus.unauthenticated) {
              return location == LoginPage.path ? null : LoginPage.path;
            }

            if (status == AuthStatus.authenticated) {
              final role = authCubit.state.session?.user.role ?? 'vendedor';
              final roleModules = [
                ...ModuleRegistry.bottomModules,
                ...ModuleRegistry.managementForRole(role),
                ModuleRegistry.profile,
              ];
              final allowed = {
                ...roleModules.map((module) => module.route),
                '/profile/users',
                '/profile/zones',
                '/profile/categories',
              };

              if (!allowed.contains(location)) {
                return DashboardPage.path;
              }
            }

            return null;
          },
        );

  final GoRouter router;
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
