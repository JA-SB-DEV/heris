import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; // Para el botón de cerrar sesión y rol
import 'add_edit_location_screen.dart'; // Para navegar a añadir sede
import 'manage_users_screen.dart'; // Para navegar a gestión de usuarios
// --- IMPORTAR LA PANTALLA DE GESTIÓN DE CATEGORÍAS ---
import 'manage_categories_screen.dart'; // Asegúrate que este archivo exista
// ---------------------------------------------------
import '../../widgets/common/loading_indicator.dart'; // Para mostrar carga

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usar watch para leer el rol y el estado de carga
    final authProvider = context.watch<AuthProvider>();
    final userRole = authProvider.currentUserRole;
    final isLoadingUserData = authProvider.isLoadingUserData;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: isLoadingUserData // Mostrar indicador mientras cargan los datos del usuario
          ? const Center(child: LoadingIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              children: [
                // --- Opción para Gestionar Usuarios (Condicional) ---
                if (userRole == 'superAdmin')
                  ListTile(
                    leading: Icon(Icons.manage_accounts_outlined, color: theme.colorScheme.primary),
                    title: Text('Gestionar Usuarios', style: theme.textTheme.titleMedium),
                    subtitle: Text('Añadir o editar usuarios y roles'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageUsersScreen()), // Navega a Gestionar Usuarios
                      );
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                // Separador si la opción anterior es visible
                if (userRole == 'superAdmin') const SizedBox(height: 8),

                // --- Opción para Gestionar Sedes (Condicional) ---
                if (userRole == 'superAdmin' || userRole == 'sedeAdmin')
                  ListTile(
                    leading: Icon(Icons.store_outlined, color: theme.colorScheme.primary),
                    title: Text('Gestionar Sedes', style: theme.textTheme.titleMedium),
                    subtitle: Text('Añadir o editar sedes/bodegas'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddEditLocationScreen()), // Navega a Añadir/Editar Sede
                      );
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                // Separador si alguna opción de gestión es visible
                if (userRole == 'superAdmin' || userRole == 'sedeAdmin') const SizedBox(height: 8),

                // --- Opción para Gestionar Categorías (Condicional) ---
                // Ajusta la condición del rol según tus necesidades (ej: solo superAdmin)
                if (userRole == 'superAdmin' || userRole == 'sedeAdmin')
                  ListTile(
                    leading: Icon(Icons.category_outlined, color: theme.colorScheme.primary),
                    title: Text('Gestionar Categorías', style: theme.textTheme.titleMedium),
                    subtitle: Text('Añadir o editar categorías de items'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navegar a la pantalla de gestión de categorías
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()), // Navega a Gestionar Categorías
                      );
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                // -----------------------------------------

                const Divider(height: 32, thickness: 0.5),

                // --- Botón Cerrar Sesión ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Cerrar Sesión'),
                    onPressed: () async {
                         // Usar listen: false aquí porque solo se llama a la acción
                         await Provider.of<AuthProvider>(context, listen: false).signOut();
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
