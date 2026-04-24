import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/clientes/presentation/pages/clientes_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/productos/presentation/pages/productos_page.dart';

class AppRouter {
  AppRouter({required AuthCubit authCubit})
      : router = GoRouter(
          initialLocation: SplashPage.path,
          refreshListenable: GoRouterRefreshStream(authCubit.stream),
          routes: [
            GoRoute(path: SplashPage.path, name: SplashPage.name, builder: (_, __) => const SplashPage()),
            GoRoute(path: LoginPage.path, name: LoginPage.name, builder: (_, __) => const LoginPage()),
            GoRoute(path: DashboardPage.path, name: DashboardPage.name, builder: (_, __) => const DashboardPage()),
            GoRoute(path: ClientesPage.path, name: ClientesPage.name, builder: (_, __) => const ClientesPage()),
            GoRoute(path: ProductosPage.path, name: ProductosPage.name, builder: (_, __) => const ProductosPage()),
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
              final allowed = [DashboardPage.path, ClientesPage.path, ProductosPage.path];
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
