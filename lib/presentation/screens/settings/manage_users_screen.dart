import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para input formatters
import 'package:provider/provider.dart';
// Importar modelos y providers necesarios
import '../../../data/models/user_model.dart'; // Importar UserModel
import '../../../data/models/location.dart'; // Importar Location
import '../../providers/user_management_provider.dart'; // Importar el provider de usuarios
import '../../providers/location_provider.dart'; // Importar provider de sedes
import '../../widgets/common/loading_indicator.dart'; // Importar widget de carga
import 'create_user_screen.dart'; // Pantalla para crear usuario

// Pantalla para que el superAdmin gestione los usuarios de la aplicación
class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  // Helper para obtener un nombre legible para mostrar el rol
  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'superAdmin': return 'Super Admin';
      case 'sedeAdmin': return 'Admin Sede';
      case 'staff': return 'Personal';
      default: return 'Rol Desconocido';
    }
  }

  // --- MÉTODO PARA MOSTRAR EL DIÁLOGO DE EDICIÓN ---
  void _showEditUserDialog(BuildContext context, UserModel userToEdit) {
    showDialog(
      context: context,
      // barrierDismissible: false, // Evitar cerrar tocando fuera mientras guarda
      builder: (_) => _EditUserDialog(user: userToEdit), // Pasa el usuario al diálogo
    );
  }
  // -----------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.watch<UserManagementProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Usuarios'),
      ),
      body: userProvider.isLoading
          ? const Center(child: LoadingIndicator())
          : userProvider.errorMessage != null
              ? Center( /* ... Error Message ... */ )
              : userProvider.users.isEmpty
                  ? const Center(child: Text('No hay usuarios registrados.'))
                  : ListView.builder(
                      itemCount: userProvider.users.length,
                      itemBuilder: (context, index) {
                        final user = userProvider.users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(_getRoleDisplayName(user.role)[0]),
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            foregroundColor: theme.colorScheme.onSecondaryContainer,
                          ),
                          title: Text('${user.firstName} ${user.lastName}'),
                          subtitle: Text("${user.email} (${_getRoleDisplayName(user.role)})"),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Editar Usuario',
                            // --- LLAMAR AL DIÁLOGO AL PRESIONAR ---
                            onPressed: () {
                              _showEditUserDialog(context, user); // Llama al método que muestra el diálogo
                            },
                            // ------------------------------------
                          ),
                          // TODO: Añadir opción de eliminar usuario
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Añadir Usuario'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateUserScreen()),
          );
        },
      ),
    );
  }
}


// --- WIDGET DEL DIÁLOGO DE EDICIÓN ---
class _EditUserDialog extends StatefulWidget {
  final UserModel user; // Recibe el usuario a editar

  const _EditUserDialog({required this.user});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  // Controladores inicializados con los datos del usuario
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  // Email no suele ser editable, pero lo mostramos
  // late TextEditingController _emailController;

  // Estado para los dropdowns inicializado con datos del usuario
  String? _selectedRole;
  Location? _selectedLocation;

  bool _isLoading = false; // Estado de carga para guardar

  // Lista de roles disponibles para asignar (quizás no todos)
  final List<String> _editableRoles = ['sedeAdmin', 'staff']; // Excluir superAdmin?

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con los datos existentes
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phone);
    // _emailController = TextEditingController(text: widget.user.email); // Si fuera editable

    _selectedRole = widget.user.role; // Rol actual

    // Preseleccionar la sede si existe (requiere acceso a LocationProvider)
    // Hacemos esto después del primer frame para tener acceso al context
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final locationProvider = Provider.of<LocationProvider>(context, listen: false);
       if (widget.user.assignedLocationId != null) {
         try {
            _selectedLocation = locationProvider.allLocations.firstWhere(
                (loc) => loc.id == widget.user.assignedLocationId);
            // Forzar actualización si encontramos la sede
            if (mounted) setState(() {});
         } catch (e) {
           print("Advertencia: No se encontró la sede asignada (${widget.user.assignedLocationId}) en la lista.");
           _selectedLocation = null;
         }
       }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    // _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
     // Validar rol y sede si es necesario
    if (_selectedRole == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un rol.'))); return;
    }
    if (_selectedRole == 'sedeAdmin' && _selectedLocation == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una sede para Admin Sede.'))); return;
    }

    setState(() { _isLoading = true; });

    // Crear un UserModel actualizado (o un mapa con los datos a actualizar)
    final updatedUserData = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'role': _selectedRole,
      'assignedLocationId': _selectedLocation?.id, // Puede ser null
      'assignedLocationName': _selectedLocation?.name, // Puede ser null
      // No actualizamos email ni createdAt
      // Podríamos añadir 'updatedAt': FieldValue.serverTimestamp()
    };

    try {
      // TODO: Llamar a un método updateUser en UserManagementProvider o AuthProvider
      print("Actualizando usuario: ${widget.user.uid}");
      print("Nuevos datos: $updatedUserData");
      // Simulación
      await Future.delayed(const Duration(seconds: 1));

      // await Provider.of<UserManagementProvider>(context, listen: false).updateUser(widget.user.uid, updatedUserData);

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Usuario actualizado (simulación).'), backgroundColor: Colors.green),
         );
         Navigator.of(context).pop(); // Cerrar el diálogo
      }
    } catch (error) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error al actualizar: $error'), backgroundColor: Colors.redAccent),
         );
       }
    } finally {
       if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Obtener lista de sedes para el dropdown
    final locationProvider = context.watch<LocationProvider>();
    final allLocations = locationProvider.allLocations;

    return AlertDialog(
      title: Text('Editar Usuario', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
      contentPadding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0), // Ajustar padding
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mostrar Email (no editable)
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico (No editable)',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: InputBorder.none,
                ),
                child: Text(widget.user.email, style: theme.textTheme.bodyLarge),
              ),
              const SizedBox(height: 16),
              // Nombres
              TextFormField(
                controller: _firstNameController,
                enabled: !_isLoading,
                decoration: const InputDecoration(labelText: 'Nombres', prefixIcon: Icon(Icons.person_outline)),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              // Apellidos
              TextFormField(
                controller: _lastNameController,
                enabled: !_isLoading,
                decoration: const InputDecoration(labelText: 'Apellidos', prefixIcon: Icon(Icons.person_outline)),
                textCapitalization: TextCapitalization.words,
                 validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              // Teléfono
              TextFormField(
                controller: _phoneController,
                enabled: !_isLoading,
                decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
                 validator: (v) {
                   if (v == null || v.trim().isEmpty) return 'Requerido';
                   if (!v.startsWith('+') || v.length < 7) return 'Formato inválido (+XX...).';
                   return null;
                 },
              ),
              const SizedBox(height: 16),
              // Rol
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Rol', prefixIcon: Icon(Icons.badge_outlined)),
                items: _editableRoles.map((String role) {
                  return DropdownMenuItem<String>(value: role, child: Text(_getRoleDisplayName(role)));
                }).toList(),
                onChanged: _isLoading ? null : (String? newValue) { setState(() { _selectedRole = newValue; }); },
                validator: (v) => v == null ? 'Selecciona un rol' : null,
              ),
              const SizedBox(height: 16),
              // Sede Asignada (si aplica)
              if (_selectedRole == 'sedeAdmin')
                DropdownButtonFormField<Location>(
                  value: _selectedLocation,
                  decoration: const InputDecoration(labelText: 'Sede Asignada', prefixIcon: Icon(Icons.store_outlined)),
                  items: allLocations.map((Location loc) {
                    return DropdownMenuItem<Location>(value: loc, child: Text(loc.name));
                  }).toList(),
                  onChanged: _isLoading ? null : (Location? newValue) { setState(() { _selectedLocation = newValue; }); },
                  validator: (v) => (_selectedRole == 'sedeAdmin' && v == null) ? 'Selecciona sede' : null,
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(), // Cerrar diálogo
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateUser, // Guardar cambios
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }

  // Reutilizar helper de SettingsScreen
  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'superAdmin': return 'Super Admin';
      case 'sedeAdmin': return 'Admin Sede';
      case 'staff': return 'Personal';
      default: return 'Rol Desconocido';
    }
  }
}
