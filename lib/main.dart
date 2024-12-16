import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/employee/application/usecases/add_employee.dart';
import 'package:gestion_propinas/employee/application/usecases/delete_employee.dart';
import 'package:gestion_propinas/employee/application/usecases/fetch_employees.dart';
import 'package:gestion_propinas/employee/application/usecases/get_employee_by_pin.dart';
import 'package:gestion_propinas/employee/application/usecases/update_employee.dart';
import 'package:gestion_propinas/employee/infrastructure/repositories/firebase_employee_adapter.dart';
import 'package:gestion_propinas/firebase_options.dart';
import 'package:gestion_propinas/share/services/print_service.dart';
import 'package:gestion_propinas/task/application/services/task_service.dart';
import 'package:gestion_propinas/task/application/usecases/add_task_usecase.dart';
import 'package:gestion_propinas/task/application/usecases/get_user_task_usecase.dart';
import 'package:gestion_propinas/task/application/usecases/update_task_usecase.dart';
import 'package:gestion_propinas/task/infrastructure/repositories/firestore_task_repository.dart';
import 'package:gestion_propinas/tip/application/services/tip_service.dart';
import 'package:gestion_propinas/tip/application/usecases/add_tip.dart';
import 'package:gestion_propinas/tip/application/usecases/delete_tip.dart';
import 'package:gestion_propinas/tip/application/usecases/fetch_tips.dart';
import 'package:gestion_propinas/tip/application/usecases/update_tip.dart';
import 'package:gestion_propinas/tip/infrastucture/repositories/firebase_tip_adapter.dart';
import 'package:gestion_propinas/home/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final printerService = PrinterService(printerIp: '192.168.1.100');

  // Inicialización de repositorios
  final employeeRepository = FirebaseEmployeeAdapter();
  final tipRepository = FirebaseTipAdapter(); // Aquí se inicializa
  final taskRepository = FirebaseTaskRepository();


  // Inicialización de casos de uso para Empleados
  final employeeService = EmployeeService(
    fetchEmployeesUseCase: FetchEmployees(employeeRepository),
    addEmployeeUseCase: AddEmployee(employeeRepository),
    getEmployeeByPinUseCase: GetEmployeeByPin(employeeRepository),
    updateEmployeeUseCase: UpdateEmployee(employeeRepository),
    deleteEmployeeUseCase: DeleteEmployee(employeeRepository),
  );

  // Inicialización de casos de uso para Propinas
  final tipService = TipService(
    fetchTipsUseCase: FetchTips(tipRepository),
    addTipUseCase: AddTip(tipRepository),
    updateTipUseCase: UpdateTip(tipRepository),
    deleteTipUseCase: DeleteTip(tipRepository),
  );

  // Casos de uso para tareas
  final taskService = TaskService(
    getUserTasksUseCase: GetUserTasks(taskRepository),
    updateTaskStatusUseCase: UpdateTaskStatus(taskRepository),
    addTaskUseCase: AddTask(taskRepository),
  );

  runApp(MyApp(
    employeeService: employeeService,
    tipService: tipService,
    tipRepository: tipRepository, // Pasa el repositorio aquí
    prinService: printerService,
    taskService: taskService,
  ));
}

class MyApp extends StatelessWidget {
  final EmployeeService employeeService;
  final TipService tipService;
  final FirebaseTipAdapter tipRepository;
  final TaskService taskService;

  const MyApp({
    Key? key,
    required this.employeeService,
    required this.tipService,
    required this.tipRepository,
    required PrinterService prinService,
    required this.taskService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Propinas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(
        employeeService: employeeService,
        tipRepository: tipRepository,
        taskService: taskService,
      ),
    );
  }
}
