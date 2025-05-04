import 'package:flutter/material.dart';
import 'package:gestion_propinas/cash/domain/repositories/arqueo_repository.dart';
import 'package:gestion_propinas/cash/domain/repositories/cash_transation_repository.dart';
import 'package:gestion_propinas/cash/presentation/screens/cash_menu_screen.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/employee/application/usecases/add_employee_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/delete_employee_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/fetch_employees_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/get_employee_by_pin_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/update_employee_use_case.dart';
import 'package:gestion_propinas/employee/infrastructure/repositories/firebase_employee_adapter.dart';
import 'package:gestion_propinas/employee/presentation/screens/employee_screen.dart';
import 'package:gestion_propinas/home/presentation/screens/home_screen.dart';
import 'package:gestion_propinas/shift/presentation/screens/shift_screen.dart';
// import 'package:gestion_propinas/survey/presentation/screens/survey_list_screen.dart';
// import 'package:gestion_propinas/survey/application/services/survey_service.dart';
// import 'package:gestion_propinas/tip/presentation/screens/tip_screen.dart';
import 'package:gestion_propinas/task/presentation/screens/task_screen.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

final employeeRepository = FirebaseEmployeeAdapter();

final employeeService = EmployeeService(
  fetchEmployeesUseCase: FetchEmployeesUseCase(employeeRepository),
  addEmployeeUseCase: AddEmployeeUseCase(employeeRepository),
  getEmployeeByPinUseCase: GetEmployeeByPinUseCase(employeeRepository),
  updateEmployeeUseCase: UpdateEmployeeUseCase(employeeRepository),
  deleteEmployeeUseCase: DeleteEmployeeUseCase(employeeRepository),
);

// GoRouter configuration
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/employees',
      builder: (context, state) {
        final employeeService = GetIt.instance<EmployeeService>();
        return EmployeeScreen(
          employeeService: employeeService,
        );
      },
    ),
    GoRoute(
      path: '/cash',
      builder: (context, state) {
        final loggedUser = state.extra as Map<String, dynamic>? ?? {};
        final arqueoRepository = GetIt.instance<ArqueoRepository>();
        final transactionRepository =
            GetIt.instance<CashTransactionRepository>();

        return FutureBuilder<double>(
          future: () async {
            double initialAmount = await arqueoRepository.getInitialAmount();
            DateTime? lastArqueoDate =
                await arqueoRepository.getLastArqueoDate() ?? DateTime(2000);
            final transactions = await transactionRepository
                .fetchTransactionsSince(lastArqueoDate);
            double entradas = 0.0;
            double salidas = 0.0;
            for (var t in transactions) {
              if (t.type == 'entrada') {
                entradas += t.amount;
              } else if (t.type == 'salida') {
                salidas += t.amount;
              }
            }
            return initialAmount + entradas - salidas;
          }(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Scaffold(
                  body: Center(
                      child: Text('Error calculando caja: ${snapshot.error}')));
            }
            final expectedAmount = snapshot.data ?? 0.0;
            return CashMenuScreen(
                loggedUser: loggedUser, expectedAmount: expectedAmount);
          },
        );
      },
    ),
    GoRoute(
      path: '/surveys',
      builder: (context, state) {
        return const Scaffold(
            body: Center(child: Text('Pantalla de Encuestas (Pendiente)')));
      },
    ),
    GoRoute(
      path: '/tips',
      builder: (context, state) {
        return const Scaffold(
            body: Center(child: Text('Pantalla de Propinas (Pendiente)')));
      },
    ),
    GoRoute(
      path: '/shifts',
      builder: (context, state) {
        final loggedUser = state.extra as Map<String, dynamic>? ?? {};
        return ShiftScreen(loggedUser: loggedUser);
      },
    ),
    GoRoute(
      path: '/tasks',
      builder: (context, state) {
        return const Scaffold(
            body: Center(child: Text('Pantalla de Tareas (Pendiente)')));
      },
    ),
  ],
);
