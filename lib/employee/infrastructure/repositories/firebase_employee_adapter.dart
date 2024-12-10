// employee/infrastructure/adapters/firebase_employee_adapter.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestion_propinas/employee/domain/entities/employee.dart';
import 'package:gestion_propinas/employee/domain/repositories/employee_repository.dart';

class FirebaseEmployeeAdapter implements EmployeeRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<void> insertEmployee(Employee employee) async {
    try {
      await _db.collection('employees').doc(employee.id).set(employee.toMap());
    } catch (e) {
      print("Error inserting employee: $e");
    }
  }

  @override
  Future<List<Employee>> fetchEmployees() async {
    try {
      final snapshot = await _db.collection('employees').get();
      return snapshot.docs.map((doc) => Employee.fromMap(doc.data())).toList();
    } catch (e) {
      print("Error fetching employees: $e");
      return [];
    }
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    final docRef = _db.collection('employees').doc(employee.id);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      try {
        await docRef.update(employee.toMap());
      } catch (e) {
        print("Error updating employee: $e");
      }
    } else {
      print("Employee with id ${employee.id} does not exist.");
    }
  }

  @override
  Future<void> deleteEmployee(String id) async {
    try {
      final docRef = _db.collection('employees').doc(id);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        print("Employee with id $id does not exist.");
        return;
      }

      final employeeData = docSnapshot.data();
      if (employeeData != null && employeeData['role'] == 'Admin') {
        print("Cannot delete an Admin employee.");
        return;
      }

      await docRef.delete();
      print("Employee with id $id has been deleted.");
    } catch (e) {
      print("Error deleting employee: $e");
    }
  }

  @override
  Future<String?> getEmployeeIdByName(String name) async {
    try {
      final snapshot = await _db
          .collection('employees')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty ? snapshot.docs.first.id : null;
    } catch (e) {
      print("Error fetching employee ID by name: $e");
      return null;
    }
  }

  @override
  Future<String?> getAdminId() async {
    return await getEmployeeIdByName('Admin');
  }

  @override
  Future<Employee?> getEmployeeByPin(int pin) async {
    try {
      final snapshot = await _db
          .collection('employees')
          .where('pin', isEqualTo: pin)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Employee.fromMap(snapshot.docs.first.data());
      }
    } catch (e) {
      print("Error fetching employee by PIN: $e");
    }
    return null;
  }
}
