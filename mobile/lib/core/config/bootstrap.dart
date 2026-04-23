import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/clientes/data/datasources/client_remote_datasource.dart';
import '../../features/clientes/data/repositories/client_repository.dart';
import '../../features/clientes/presentation/cubit/clients_cubit.dart';
import '../../features/productos/data/datasources/product_remote_datasource.dart';
import '../../features/productos/data/repositories/product_repository.dart';
import '../../features/productos/presentation/cubit/products_cubit.dart';
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

  final clientRepository = ClientRepository(
    remoteDataSource: ClientRemoteDataSource(apiClient: apiClient),
  );

  final productRepository = ProductRepository(
    remoteDataSource: ProductRemoteDataSource(apiClient: apiClient),
  );

  runApp(
    AppRoot(
      authRepository: authRepository,
      clientRepository: clientRepository,
      productRepository: productRepository,
    ),
  );
}

class AppRoot extends StatelessWidget {
  const AppRoot({
    required this.authRepository,
    required this.clientRepository,
    required this.productRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final ClientRepository clientRepository;
  final ProductRepository productRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(authRepository: authRepository)..initialize()),
        BlocProvider(create: (_) => ClientsCubit(clientRepository: clientRepository)),
        BlocProvider(create: (_) => ProductsCubit(repository: productRepository)),
      ],
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
