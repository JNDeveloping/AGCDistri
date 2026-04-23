import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../services/api/api_client.dart';
import '../../services/storage/token_storage.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

Future<void> bootstrap() async {
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final authRepository = AuthRepository(
    remoteDataSource: AuthRemoteDataSource(apiClient: apiClient),
    tokenStorage: tokenStorage,
  );

  runApp(AppRoot(authRepository: authRepository));
}

class AppRoot extends StatelessWidget {
  const AppRoot({required this.authRepository, super.key});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(authRepository: authRepository)..initialize(),
      child: Builder(
        builder: (context) {
          final router = AppRouter(authCubit: context.read<AuthCubit>()).router;

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'AGC Distribuidora',
            theme: AppTheme.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
