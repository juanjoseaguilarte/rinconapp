import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú Principal'),
        backgroundColor:
            const Color.fromARGB(255, 31, 98, 154), // Color del AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botón para "Usuarios Online"
            ElevatedButton(
              onPressed: () {
                // Navega a la pantalla de Usuarios Online
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UsuariosOnlineScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 31, 98, 154),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Usuarios Online',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16), // Espacio entre los botones

            // Botón para "Estadísticas Propinas"
          //   ElevatedButton(
          //     onPressed: () {
          //       // Navega a la pantalla de Estadísticas Propinas
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => EstadisticasPropinasScreen(),
          //         ),
          //       );
          //     },
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: const Color.fromARGB(255, 31, 98, 154),
          //       padding: const EdgeInsets.symmetric(vertical: 20),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //     ),
          //     child: const Text(
          //       'Estadísticas Propinas',
          //       style: TextStyle(
          //         color: Colors.white,
          //         fontSize: 18,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //   ),
           ],
        ),
      ),
    );
  }
}

// Pantalla de ejemplo para Usuarios Online
class UsuariosOnlineScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios Online'),
        backgroundColor: const Color.fromARGB(255, 31, 98, 154),
      ),
      body: const Center(
        child: Text('Lista de usuarios online aquí'),
      ),
    );
  }
}
