import 'package:get_it/get_it.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/expenses_repository_impl.dart';
import '../data/repositories/budget_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/expenses_repository.dart';
import '../domain/repositories/budget_repository.dart';
import '../presentation/viewmodels/auth_viewmodel.dart';
import '../presentation/viewmodels/expenses_viewmodel.dart';
import '../presentation/viewmodels/budget_viewmodel.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ViewModels
  sl.registerFactory(
    () => AuthViewModel(authRepository: sl()),
  );
  sl.registerFactory(
    () => ExpensesViewModel(expensesRepository: sl()),
  );
  sl.registerFactory(
    () => BudgetViewModel(budgetRepository: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(),
  );
  sl.registerLazySingleton<ExpensesRepository>(
    () => ExpensesRepositoryImpl(),
  );
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(),
  );

  // Use cases
  // TODO: Add use cases here

  // Data sources
  // TODO: Add data sources here
} 