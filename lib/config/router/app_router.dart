import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/employee/application/usecases/add_employee_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/delete_employee_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/fetch_employees_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/get_employee_by_pin_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/update_employee_use_case.dart';
import 'package:gestion_propinas/employee/infrastructure/repositories/firebase_employee_adapter.dart';
import 'package:gestion_propinas/employee/presentation/screens/employee_screen.dart';
import 'package:gestion_propinas/home/presentation/screens/home_screen.dart';
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
      builder: (context, state) => EmployeeScreen(
        employeeService: employeeService,
      ),
    ),
  ],
);
