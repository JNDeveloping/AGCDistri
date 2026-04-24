import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/clientes/data/datasources/client_remote_datasource.dart';
import '../../features/clientes/data/repositories/client_repository.dart';
import '../../features/clientes/presentation/cubit/clients_cubit.dart';
import '../../features/company_settings/data/datasources/company_settings_remote_datasource.dart';
import '../../features/company_settings/data/repositories/company_settings_repository.dart';
import '../../features/company_settings/presentation/cubit/company_settings_cubit.dart';
import '../../features/company_settings/presentation/cubit/company_settings_state.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/productos/data/datasources/product_remote_datasource.dart';
import '../../features/productos/data/repositories/product_repository.dart';
import '../../features/productos/presentation/cubit/products_cubit.dart';
import '../../features/pedidos/data/datasources/order_remote_datasource.dart';
import '../../features/pedidos/data/repositories/order_repository.dart';
import '../../features/pedidos/presentation/cubit/orders_cubit.dart';
import '../../services/api/api_client.dart';
import '../../services/storage/token_storage.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../../features/users/data/datasources/users_remote_datasource.dart';
import '../../features/users/data/repositories/users_repository.dart';

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

  final dashboardRepository = DashboardRepository(
    remoteDataSource: DashboardRemoteDataSource(apiClient: apiClient),
  );

  final orderRepository = OrderRepository(
    remoteDataSource: OrderRemoteDataSource(apiClient: apiClient),
  );

  final companySettingsRepository = CompanySettingsRepository(
    remoteDataSource: CompanySettingsRemoteDataSource(apiClient: apiClient),
  );

  final usersRepository = UsersRepository(
    remoteDataSource: UsersRemoteDataSource(apiClient: apiClient),
  );

  runApp(
    AppRoot(
      authRepository: authRepository,
      clientRepository: clientRepository,
      productRepository: productRepository,
      dashboardRepository: dashboardRepository,
      orderRepository: orderRepository,
      companySettingsRepository: companySettingsRepository,
      usersRepository: usersRepository,
    ),
  );
}

class AppRoot extends StatelessWidget {
  const AppRoot({
    required this.authRepository,
    required this.clientRepository,
    required this.productRepository,
    required this.dashboardRepository,
    required this.orderRepository,
    required this.companySettingsRepository,
    required this.usersRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final ClientRepository clientRepository;
  final ProductRepository productRepository;
  final DashboardRepository dashboardRepository;
  final OrderRepository orderRepository;
  final CompanySettingsRepository companySettingsRepository;
  final UsersRepository usersRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(authRepository: authRepository)..initialize()),
        BlocProvider(create: (_) => ClientsCubit(clientRepository: clientRepository)),
        BlocProvider(create: (_) => ProductsCubit(repository: productRepository)),
        BlocProvider(create: (_) => DashboardCubit(repository: dashboardRepository)),
        BlocProvider(create: (_) => OrdersCubit(repository: orderRepository)),
        BlocProvider(create: (_) => CompanySettingsCubit(repository: companySettingsRepository)),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter(
            authCubit: context.read<AuthCubit>(),
            usersRepository: usersRepository,
          ).router;

          return BlocListener<AuthCubit, AuthState>(
            listenWhen: (previous, current) => previous.status != current.status || previous.session != current.session,
            listener: (context, state) {
              if (state.status == AuthStatus.authenticated) {
                context.read<CompanySettingsCubit>().load();
              }
            },
            child: BlocBuilder<CompanySettingsCubit, CompanySettingsState>(
              builder: (context, settingsState) {
                return MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  title: 'AGC Distribuidora',
                  theme: AppTheme.light(settingsState.settings),
                  routerConfig: router,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
