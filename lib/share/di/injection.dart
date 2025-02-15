import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';
import 'package:gestion_propinas/tip/infrastucture/repositories/firebase_tip_adapter.dart';
import 'package:get_it/get_it.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/employee/application/usecases/add_employee_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/delete_employee_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/fetch_employees_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/get_employee_by_pin_use_case.dart';
import 'package:gestion_propinas/employee/application/usecases/update_employee_use_case.dart';
import 'package:gestion_propinas/employee/infrastructure/repositories/firebase_employee_adapter.dart';
import 'package:gestion_propinas/tip/application/services/tip_service.dart';
import 'package:gestion_propinas/tip/application/usecases/add_tip.dart';
import 'package:gestion_propinas/tip/application/usecases/delete_tip.dart';
import 'package:gestion_propinas/tip/application/usecases/fetch_tips.dart';
import 'package:gestion_propinas/tip/application/usecases/update_tip.dart';
import 'package:gestion_propinas/task/application/services/task_service.dart';
import 'package:gestion_propinas/task/application/usecases/add_task_usecase.dart';
import 'package:gestion_propinas/task/application/usecases/get_tasks_created_by_usecase.dart';
import 'package:gestion_propinas/task/application/usecases/get_user_task_usecase.dart';
import 'package:gestion_propinas/task/application/usecases/update_task_usecase.dart';
import 'package:gestion_propinas/task/infrastructure/repositories/firestore_task_repository.dart';

final GetIt getIt = GetIt.instance;

void setupDependencies() {
  // Repositorios
  getIt.registerLazySingleton(() => FirebaseEmployeeAdapter());
  getIt.registerLazySingleton(() => FirebaseTipAdapter()); // Agregado
  getIt.registerLazySingleton(() => FirebaseTaskRepository());

  // Registro explícito del repositorio de tips
  getIt.registerLazySingleton<TipRepository>(() => getIt<FirebaseTipAdapter>());

  // Servicios
  getIt.registerLazySingleton(() => EmployeeService(
        fetchEmployeesUseCase: FetchEmployeesUseCase(getIt<FirebaseEmployeeAdapter>()),
        addEmployeeUseCase: AddEmployeeUseCase(getIt<FirebaseEmployeeAdapter>()),
        getEmployeeByPinUseCase:
            GetEmployeeByPinUseCase(getIt<FirebaseEmployeeAdapter>()),
        updateEmployeeUseCase:
            UpdateEmployeeUseCase(getIt<FirebaseEmployeeAdapter>()),
        deleteEmployeeUseCase:
            DeleteEmployeeUseCase(getIt<FirebaseEmployeeAdapter>()),
      ));

  getIt.registerLazySingleton(() => TipService(
        fetchTipsUseCase: FetchTips(getIt<FirebaseTipAdapter>()),
        addTipUseCase: AddTip(getIt<FirebaseTipAdapter>()),
        updateTipUseCase: UpdateTip(getIt<FirebaseTipAdapter>()),
        deleteTipUseCase: DeleteTip(getIt<FirebaseTipAdapter>()),
      ));

  getIt.registerLazySingleton(() => TaskService(
        getUserTasksUseCase: GetUserTasks(getIt<FirebaseTaskRepository>()),
        updateTaskStatusUseCase:
            UpdateTaskStatus(getIt<FirebaseTaskRepository>()),
        addTaskUseCase: AddTask(getIt<FirebaseTaskRepository>()),
        getTasksCreatedByUseCase:
            GetTasksCreatedBy(getIt<FirebaseTaskRepository>()),
      ));
}
