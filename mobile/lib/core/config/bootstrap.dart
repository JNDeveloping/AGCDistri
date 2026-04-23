import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../services/api/api_client.dart';
import '../../services/storage/token_storage.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

Future<void> bootstrap() async {
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getTemporaryDirectory(),
  );

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);

  runApp(
    AppRoot(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    ),
  );
}

class AppRoot extends StatelessWidget {
  const AppRoot({
    required this.apiClient,
    required this.tokenStorage,
    super.key,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthCubit(
            apiClient: apiClient,
            tokenStorage: tokenStorage,
          )..restoreSession(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter(authCubit: context.read<AuthCubit>()).router;

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'AGC Distribuidora',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
