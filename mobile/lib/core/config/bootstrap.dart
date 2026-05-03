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
import '../../features/stock/data/datasources/stock_remote_datasource.dart';
import '../../features/stock/data/repositories/stock_repository.dart';
import '../../features/stock/presentation/cubit/stock_cubit.dart';
import '../../features/accounts/data/datasources/accounts_remote_datasource.dart';
import '../../features/accounts/data/repositories/accounts_repository.dart';
import '../../features/credit_notes/data/datasources/credit_note_remote_datasource.dart';
import '../../features/credit_notes/data/repositories/credit_note_repository.dart';
import '../../features/reports/data/datasources/reports_remote_datasource.dart';
import '../../features/reports/data/repositories/reports_repository.dart';
import '../../features/deliveries/data/datasources/delivery_remote_datasource.dart';
import '../../features/deliveries/data/repositories/delivery_repository.dart';
import '../../features/promotions/data/datasources/promotion_remote_datasource.dart';
import '../../features/promotions/data/repositories/promotion_repository.dart';
import '../../services/api/api_client.dart';
import '../../services/storage/token_storage.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../../features/users/data/datasources/users_remote_datasource.dart';
import '../offline/offline_sync_service.dart';
import '../network/connectivity_cubit.dart';
import '../../features/users/data/repositories/users_repository.dart';

Future<void> bootstrap() async {
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final offlineSyncService = OfflineSyncService(apiClient: apiClient);

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

  final stockRepository = StockRepository(
    remoteDataSource: StockRemoteDataSource(apiClient: apiClient),
  );

  final accountsRepository = AccountsRepository(
    remoteDataSource: AccountsRemoteDataSource(apiClient: apiClient),
  );

  final creditNoteRepository = CreditNoteRepository(
    remoteDataSource: CreditNoteRemoteDataSource(apiClient: apiClient),
  );

  final reportsRepository = ReportsRepository(
    remoteDataSource: ReportsRemoteDataSource(apiClient: apiClient),
  );

  final deliveryRepository = DeliveryRepository(
    remoteDataSource: DeliveryRemoteDataSource(apiClient: apiClient),
  );
  final promotionRepository = PromotionRepository(
    remote: PromotionRemoteDataSource(apiClient: apiClient),
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
      stockRepository: stockRepository,
      accountsRepository: accountsRepository,
      creditNoteRepository: creditNoteRepository,
      reportsRepository: reportsRepository,
      deliveryRepository: deliveryRepository,
      promotionRepository: promotionRepository,
      offlineSyncService: offlineSyncService,
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
    required this.stockRepository,
    required this.accountsRepository,
    required this.creditNoteRepository,
    required this.reportsRepository,
    required this.deliveryRepository,
    required this.promotionRepository,
    required this.offlineSyncService,
    super.key,
  });

  final AuthRepository authRepository;
  final ClientRepository clientRepository;
  final ProductRepository productRepository;
  final DashboardRepository dashboardRepository;
  final OrderRepository orderRepository;
  final CompanySettingsRepository companySettingsRepository;
  final UsersRepository usersRepository;
  final StockRepository stockRepository;
  final AccountsRepository accountsRepository;
  final CreditNoteRepository creditNoteRepository;
  final ReportsRepository reportsRepository;
  final DeliveryRepository deliveryRepository;
  final PromotionRepository promotionRepository;
  final OfflineSyncService offlineSyncService;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: stockRepository),
        RepositoryProvider.value(value: accountsRepository),
        RepositoryProvider.value(value: clientRepository),
        RepositoryProvider.value(value: creditNoteRepository),
        RepositoryProvider.value(value: reportsRepository),
        RepositoryProvider.value(value: deliveryRepository),
        RepositoryProvider.value(value: offlineSyncService),
        RepositoryProvider.value(value: usersRepository),
        RepositoryProvider.value(value: promotionRepository),
      ],
      child: MultiBlocProvider(
        providers: [
        BlocProvider(create: (_) => AuthCubit(authRepository: authRepository)..initialize()),
        BlocProvider(create: (_) => ClientsCubit(clientRepository: clientRepository)),
        BlocProvider(create: (_) => ProductsCubit(repository: productRepository)),
        BlocProvider(create: (_) => DashboardCubit(repository: dashboardRepository)),
        BlocProvider(create: (_) => OrdersCubit(repository: orderRepository)),
        BlocProvider(create: (_) => CompanySettingsCubit(repository: companySettingsRepository)),
        BlocProvider(create: (_) => StockCubit(repository: stockRepository)),
        BlocProvider(create: (_) => ConnectivityCubit()),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter(
            authCubit: context.read<AuthCubit>(),
            usersRepository: usersRepository,
            promotionRepository: promotionRepository,
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
                  builder: (context, child) => Stack(
                    children: [
                      child ?? const SizedBox.shrink(),
                      BlocListener<ConnectivityCubit, ConnectivityBannerState>(
                        listenWhen: (a, b) => a != b && b == ConnectivityBannerState.reconnecting,
                        listener: (_, __) => offlineSyncService.syncPending(),
                        child: BlocBuilder<ConnectivityCubit, ConnectivityBannerState>(
                          builder: (_, state) => state == ConnectivityBannerState.online
                              ? const SizedBox.shrink()
                              : Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Material(
                                  color: state == ConnectivityBannerState.offline ? Colors.red.shade700 : Colors.green.shade700,
                                  child: SafeArea(
                                    bottom: false,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      child: Text(
                                        state == ConnectivityBannerState.offline
                                            ? 'Sin conexión · Trabajando offline'
                                            : 'Conexión recuperada, sincronizando…',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      ),
    );
  }
}
