import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; // Para el botón de cerrar sesión
// --- IMPORTAR LA PANTALLA DE AÑADIR/EDITAR SEDE ---
import 'add_edit_location_screen.dart';
// -------------------------------------------------

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // --- Placeholders para las pantallas de gestión ---
  // Puedes crear estos archivos si quieres navegar a pantallas vacías por ahora
  // import 'manage_users_screen.dart';
  // -------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context); // Obtener el tema

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      // Usar un ListView para poder añadir más opciones fácilmente
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        children: [
          // --- Opción para Gestionar Usuarios ---
          // TODO: Mostrar este ListTile solo si el usuario es superAdmin
          ListTile(
            leading: Icon(Icons.manage_accounts_outlined, color: theme.colorScheme.primary),
            title: Text('Gestionar Usuarios', style: theme.textTheme.titleMedium),
            subtitle: Text('Añadir o editar usuarios y roles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navegar a la pantalla real de gestión de usuarios
              print('Navegar a Gestionar Usuarios');
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Pantalla "Gestionar Usuarios" (Próximamente)'), duration: Duration(seconds: 2))
               );
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          // ------------------------------------

          const SizedBox(height: 8), // Espacio entre opciones

          // --- Opción para Gestionar Sedes ---
          // TODO: Mostrar este ListTile solo si el usuario es superAdmin o admin de sede?
          ListTile(
            leading: Icon(Icons.store_outlined, color: theme.colorScheme.primary), // Icono de tienda/sede
            title: Text('Gestionar Sedes', style: theme.textTheme.titleMedium),
            subtitle: Text('Añadir o editar sedes/bodegas'),
            trailing: const Icon(Icons.chevron_right),
            // --- ACTUALIZAR onTap ---
            onTap: () {
              // Navegar a la pantalla para añadir/editar sede
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditLocationScreen()), // Navega a la pantalla
              );
            },
            // ------------------------
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          // ---------------------------------------

          // Puedes añadir más opciones de configuración aquí
          // ...

          const Divider(height: 32, thickness: 0.5), // Separador

          // --- Botón Cerrar Sesión ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Cerrar Sesión'),
              onPressed: () async {
                   await authProvider.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
                elevation: 1,
              ),
            ),
          ),
          // ---------------------------
        ],
      ),
    );
  }
}
