import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/expenses_repository_impl.dart';
import '../data/repositories/budget_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/expenses_repository.dart';
import '../domain/repositories/budget_repository.dart';
import '../presentation/viewmodels/auth_viewmodel.dart';
import '../presentation/viewmodels/expenses_viewmodel.dart';
import '../presentation/viewmodels/budget_viewmodel.dart';
import '../data/local/database/app_database.dart';
import '../data/datasources/local_data_source.dart';
import '../data/datasources/local_data_source_impl.dart';
import '../core/network/connectivity_service.dart';
import '../core/services/sync_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // 注册Firebase服务，确保全局单一实例
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => GoogleSignIn());

  // 本地数据库
  sl.registerLazySingleton(() => AppDatabase());

  // 数据源
  sl.registerLazySingleton<LocalDataSource>(
    () => LocalDataSourceImpl(
      sl(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  // 网络连接服务
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(),
  );

  // 同步服务
  sl.registerLazySingleton(
    () => SyncService(
      localDataSource: sl(),
      expensesRepository: sl(),
      budgetRepository: sl(),
      connectivityService: sl(),
      auth: sl(),
    ),
  );

  // ViewModels
  sl.registerFactory(
    () => AuthViewModel(
      authRepository: sl(),
      syncService: sl(),
    ),
  );
  sl.registerFactory(
    () => ExpensesViewModel(
      expensesRepository: sl(),
      budgetRepository: sl(),
      connectivityService: sl(),
    ),
  );
  sl.registerFactory(
    () => BudgetViewModel(budgetRepository: sl()),
  );

  // Repositories - 使用注入的服务
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      auth: sl<FirebaseAuth>(),
      googleSignIn: sl<GoogleSignIn>(),
    ),
  );
  sl.registerLazySingleton<ExpensesRepository>(
    () => ExpensesRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
      localDataSource: sl(),
      connectivityService: sl(),
    ),
  );
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
      localDataSource: sl(),
      connectivityService: sl(),
    ),
  );

  // Use cases
  // TODO: Add use cases here

  // Data sources
  // TODO: Add data sources here
}
