import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';

class AppRouter {
  AppRouter({required AuthCubit authCubit})
      : router = GoRouter(
          initialLocation: DashboardPage.path,
          refreshListenable: GoRouterRefreshStream(authCubit.stream),
          routes: [
            GoRoute(
              path: DashboardPage.path,
              name: DashboardPage.name,
              builder: (_, __) => const DashboardPage(),
            ),
            GoRoute(
              path: LoginPage.path,
              name: LoginPage.name,
              builder: (_, __) => const LoginPage(),
            ),
          ],
          redirect: (_, state) {
            final isLoggedIn = authCubit.state.isAuthenticated;
            final goingToLogin = state.matchedLocation == LoginPage.path;

            if (!isLoggedIn && !goingToLogin) {
              return LoginPage.path;
            }

            if (isLoggedIn && goingToLogin) {
              return DashboardPage.path;
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
