import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Importar modelos y providers necesarios más adelante
// import '../../../data/models/user_model.dart';
// import '../../providers/user_management_provider.dart'; // Podríamos crear este provider
import 'create_user_screen.dart'; // Pantalla para crear usuario

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // TODO: Obtener la lista de usuarios desde un provider

    // Simulación de lista de usuarios (reemplazar con datos reales)
    final List<Map<String, String>> users = [
      {'name': 'Admin Principal', 'email': 'admin@example.com', 'role': 'superAdmin'},
      {'name': 'Gerente Sede Centro', 'email': 'gerente.centro@example.com', 'role': 'sedeAdmin'},
      {'name': 'Empleado Cocina', 'email': 'cocina1@example.com', 'role': 'staff'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Usuarios'),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          // TODO: Usar un UserListTile personalizado
          return ListTile(
            leading: CircleAvatar( // Icono o iniciales
              // Mostrar inicial del rol o un icono genérico
              child: Text(user['role']?[0].toUpperCase() ?? '?'),
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            ),
            title: Text(user['name'] ?? 'Sin Nombre'),
            subtitle: Text("${user['email']} (${user['role']})"), // Mostrar email y rol
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar Usuario',
              onPressed: () {
                // TODO: Navegar a pantalla de edición de usuario pasando el ID/datos
                print('Editar usuario: ${user['email']}');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidad Editar Usuario (Próximamente)'))
                );
              },
            ),
            // Podrías añadir opción de eliminar con confirmación aquí
            // onTap: () { /* Ver detalles? */ },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Añadir Usuario'),
        onPressed: () {
          // Navegar a la pantalla de creación de usuario
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateUserScreen()), // Asegúrate que CreateUserScreen exista
          );
        },
      ),
    );
  }
}
