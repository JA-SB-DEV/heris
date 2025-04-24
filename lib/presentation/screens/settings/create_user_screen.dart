import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// Importar modelos y providers necesarios
import '../../../data/models/location.dart';
import '../../providers/location_provider.dart';
import '../../providers/auth_provider.dart'; // <-- Descomentar para usar la lógica real

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedRole;
  Location? _selectedLocation;

  // bool _isLoading = false; // Usaremos el estado del AuthProvider
  bool _obscurePassword = true;

  final List<String> _availableRoles = ['sedeAdmin', 'staff'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un rol para el usuario.')));
      return;
    }
    if (_selectedRole == 'sedeAdmin' && _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una sede para este rol.')));
      return;
    }

    // Usar el provider para la lógica y el estado de carga
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // setState(() { _isLoading = true; }); // El provider maneja esto

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // --- LLAMAR AL MÉTODO REAL DEL PROVIDER ---
      // Necesitamos crear este método en AuthProvider
      await authProvider.createUserByAdmin(
        email: email,
        password: password, // Firebase Auth crea el usuario
        firstName: firstName, // Estos datos van a Firestore
        lastName: lastName,
        phone: phone,
        role: _selectedRole!,
        assignedLocationId: _selectedLocation?.id, // Puede ser null
        assignedLocationName: _selectedLocation?.name,
      );
      // -----------------------------------------

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('Usuario creado correctamente.'), // Mensaje real
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear usuario: $error'), // Mostrar error real
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
    // El estado isLoading lo maneja el provider
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locationProvider = context.watch<LocationProvider>();
    final allLocations = locationProvider.allLocations;
    // --- Leer estado de carga del AuthProvider ---
    final isLoading = context.watch<AuthProvider>().isLoading;
    // -----------------------------------------

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Añadir Nuevo Usuario'),
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- Campos de Texto (Nombres, Apellidos, Teléfono, Email, Contraseña) ---
              TextFormField(
                controller: _firstNameController,
                enabled: !isLoading,
                decoration: const InputDecoration(labelText: 'Nombres', prefixIcon: Icon(Icons.person_outline)),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Introduce los nombres.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                enabled: !isLoading,
                decoration: const InputDecoration(labelText: 'Apellidos', prefixIcon: Icon(Icons.person_outline)),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Introduce los apellidos.' : null,
              ),
              const SizedBox(height: 16),
               TextFormField(
                controller: _phoneController,
                enabled: !isLoading,
                decoration: const InputDecoration(labelText: 'Teléfono (con indicativo)', prefixIcon: Icon(Icons.phone_outlined), hintText: '+57...'),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\+?[0-9]*'))],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Introduce el teléfono.';
                  if (!value.startsWith('+') || value.length < 7) return 'Incluye el indicativo (+XX) y un número válido.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                enabled: !isLoading,
                decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Introduce el correo.';
                  if (!value.contains('@') || !value.contains('.')) return 'Introduce un correo válido.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Contraseña Inicial',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Introduce una contraseña inicial.';
                  if (value.length < 6) return 'Debe tener al menos 6 caracteres.';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Selectores (Rol, Sede) ---
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Rol del Usuario', prefixIcon: Icon(Icons.badge_outlined)),
                items: _availableRoles.map((String role) {
                  return DropdownMenuItem<String>(value: role, child: Text(role == 'sedeAdmin' ? 'Admin Sede' : 'Personal'));
                }).toList(),
                onChanged: isLoading ? null : (String? newValue) { setState(() { _selectedRole = newValue; }); },
                validator: (value) => value == null ? 'Selecciona un rol' : null,
                isExpanded: true,
              ),
              const SizedBox(height: 16),
              if (_selectedRole == 'sedeAdmin') // Mostrar solo si es Admin Sede
                DropdownButtonFormField<Location>(
                  value: _selectedLocation,
                  decoration: const InputDecoration(labelText: 'Sede Asignada', prefixIcon: Icon(Icons.store_outlined)),
                  items: allLocations.map((Location loc) {
                    return DropdownMenuItem<Location>(value: loc, child: Text(loc.name));
                  }).toList(),
                  onChanged: isLoading ? null : (Location? newValue) { setState(() { _selectedLocation = newValue; }); },
                  validator: (value) => (_selectedRole == 'sedeAdmin' && value == null) ? 'Selecciona una sede' : null,
                  isExpanded: true,
                ),
              const SizedBox(height: 32),

              // --- Botón Crear Usuario (Corregido) ---
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add_alt_1_outlined),
                // --- MOVER LA LÓGICA AL PARÁMETRO label ---
                label: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Crear Usuario', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                // -----------------------------------------
                onPressed: isLoading ? null : _createUser,
                style: theme.elevatedButtonTheme.style?.copyWith(
                   minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50)),
                ),
                // --- ELIMINAR EL PARÁMETRO child ---
                // child: isLoading ...
                // ---------------------------------
              ),
            ],
          ),
        ),
      ),
    );
  }
}
