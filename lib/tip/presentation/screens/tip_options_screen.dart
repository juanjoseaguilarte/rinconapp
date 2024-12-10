import 'package:flutter/material.dart';
import 'package:gestion_propinas/employee/application/services/employee_service.dart';
import 'package:gestion_propinas/tip/domain/entities/tip.dart';
import 'package:gestion_propinas/tip/domain/repositories/tip_repository.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_admin_screen.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_create_screen.dart';
import 'package:gestion_propinas/tip/presentation/screens/tip_pay_screen.dart';

class TipOptionsScreen extends StatelessWidget {
  final EmployeeService employeeService;
  final TipRepository tipRepository;
  final Map<String, dynamic> loggedUser;

  const TipOptionsScreen({
    Key? key,
    required this.employeeService,
    required this.tipRepository,
    required this.loggedUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Estilo de botón cuadrado
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(100, 100), // cuadrado de 100x100
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // sin esquinas redondeadas
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opciones de Propinas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 20, // espacio horizontal entre botones
          runSpacing: 20, // espacio vertical entre filas
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TipCreateScreen(
                      employeeService: employeeService,
                      tipRepository: tipRepository,
                    ),
                  ),
                );
              },
              style: buttonStyle,
              child: const Text('Añadir Propina', textAlign: TextAlign.center),
            ),
            ElevatedButton(
              onPressed: () {
                // Mostrar aviso antes de navegar
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Atención'),
                      content: const Text(
                          'Una vez dentro del pago de propinas, deberás pagar todas y no hay vuelta atrás. ¿Deseas continuar?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(
                              context), // cierra el diálogo sin hacer nada
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // cierra el diálogo
                            // Ahora sí navegamos a TipPayScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TipPayScreen(
                                  tipRepository: tipRepository,
                                  employeeService: employeeService,
                                ),
                              ),
                            );
                          },
                          child: const Text('Aceptar'),
                        ),
                      ],
                    );
                  },
                );
              },
              style: buttonStyle,
              child: const Text(
                'Pagar Todas Las Propinas',
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Cargar empleados para seleccionar
                final employees = await employeeService.getAllEmployees();
                if (employees.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No hay empleados disponibles')),
                  );
                  return;
                }

                // Mostrar modal para seleccionar un camarero
                showDialog(
                  context: context,
                  builder: (context) {
                    String? selectedEmployeeId;

                    return AlertDialog(
                      title: const Text('Seleccionar Camarero'),
                      content: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Selecciona un camarero'),
                        value: selectedEmployeeId,
                        onChanged: (value) {
                          selectedEmployeeId = value;
                          Navigator.pop(context);
                          if (selectedEmployeeId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IndividualTipPayScreen(
                                  employeeId: selectedEmployeeId!,
                                  employeeService: employeeService,
                                  tipRepository: tipRepository,
                                ),
                              ),
                            );
                          }
                        },
                        items: employees.map((employee) {
                          return DropdownMenuItem(
                            value: employee.id,
                            child: Text(employee.name),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
              style: buttonStyle,
              child: const Text('Pagar Propina Individual',
                  textAlign: TextAlign.center),
            ),
            if (loggedUser['role'] == 'Admin')
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TipAdminScreen(
                        tipRepository: tipRepository,
                        employeeService: employeeService,
                      ),
                    ),
                  );
                },
                style: buttonStyle,
                child: const Text('Admin', textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}

class IndividualTipPayScreen extends StatelessWidget {
  final String employeeId;
  final EmployeeService employeeService;
  final TipRepository tipRepository;

  const IndividualTipPayScreen({
    Key? key,
    required this.employeeId,
    required this.employeeService,
    required this.tipRepository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: tipRepository.fetchTips(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final tips = snapshot.data as List<Tip>;
        final employeeTips = tips
            .where((tip) =>
                tip.employeePayments[employeeId]?['isDeleted'] == false)
            .map((tip) => tip.employeePayments[employeeId]!['amount'] as double)
            .fold(0.0, (prev, amount) => prev + amount);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pagar Propina Individual'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Propina Total: €${employeeTips.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Una vez confirmes, no habrá vuelta atrás. ¿Deseas continuar?',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    // Lógica para pagar la propina individual
                    final updatedTips = tips.map((tip) {
                      if (tip.employeePayments.containsKey(employeeId)) {
                        final updatedPayments = Map.of(tip.employeePayments);
                        updatedPayments[employeeId]?['isDeleted'] = true;
                        return tip.copyWith(employeePayments: updatedPayments);
                      }
                      return tip;
                    }).toList();

                    for (var tip in updatedTips) {
                      await tipRepository.updateTip(tip);
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Propina pagada exitosamente')),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Confirmar Pago'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
