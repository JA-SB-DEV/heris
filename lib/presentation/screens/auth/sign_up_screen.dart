import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para input formatters (teléfono)
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  // --- NUEVOS Controladores ---
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  // ---------------------------
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    // --- Limpiar nuevos controladores ---
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    // ---------------------------------
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- MÉTODO _signUp ACTUALIZADO para pasar más datos ---
  Future<void> _signUp() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    // Obtener todos los datos del formulario
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim(); // Incluye indicativo
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Llamar al método signUp del provider con los datos adicionales
    // (¡Tendremos que modificar AuthProvider para aceptar estos!)
    await authProvider.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );

    // --- Lógica de resultado (sin cambios) ---
    if (mounted) {
      if (authProvider.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Registro exitoso! Ahora puedes iniciar sesión.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en registro: ${authProvider.errorMessage}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
  // --- FIN MÉTODO _signUp ACTUALIZADO ---

  @override
  Widget build(BuildContext context) {
    final isLoadingFromProvider = context.watch<AuthProvider>().isLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final inputDecorationTheme = InputDecoration( // Estilo común (sin cambios)
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      border: UnderlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.primary, width: 2), borderRadius: BorderRadius.circular(12)),
      errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.error, width: 2), borderRadius: BorderRadius.circular(12)),
      focusedErrorBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.error, width: 2), borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      prefixIconColor: colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0), // Ajustar padding vertical
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Completa tus datos', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  const SizedBox(height: 24), // Espacio reducido

                  // --- NUEVO: Campo de Nombres ---
                  TextFormField(
                    controller: _firstNameController,
                    enabled: !isLoadingFromProvider,
                    decoration: inputDecorationTheme.copyWith(
                      labelText: 'Nombres',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words, // Poner mayúscula inicial
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Introduce tus nombres.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16), // Espacio estándar

                  // --- NUEVO: Campo de Apellidos ---
                  TextFormField(
                    controller: _lastNameController,
                    enabled: !isLoadingFromProvider,
                    decoration: inputDecorationTheme.copyWith(
                      labelText: 'Apellidos',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                     keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Introduce tus apellidos.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- NUEVO: Campo de Teléfono ---
                   TextFormField(
                    controller: _phoneController,
                    enabled: !isLoadingFromProvider,
                    decoration: inputDecorationTheme.copyWith(
                      labelText: 'Teléfono (con indicativo)',
                      hintText: '+573...', // Ejemplo para Colombia
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    // Permitir solo números y el signo '+' al inicio (opcional pero útil)
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\+?[0-9]*')),
                    ],
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Introduce tu teléfono.';
                      // Validación simple (puedes mejorarla)
                      if (!value.startsWith('+') || value.length < 7) return 'Incluye el indicativo (+XX) y un número válido.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Campo de Email (sin cambios) ---
                  TextFormField(
                    controller: _emailController,
                    enabled: !isLoadingFromProvider,
                    decoration: inputDecorationTheme.copyWith(labelText: 'Correo Electrónico', prefixIcon: const Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Introduce tu correo.';
                      if (!value.contains('@') || !value.contains('.')) return 'Introduce un correo válido.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Campo de Contraseña (sin cambios) ---
                  TextFormField(
                    controller: _passwordController,
                    enabled: !isLoadingFromProvider,
                    decoration: inputDecorationTheme.copyWith(labelText: 'Contraseña', prefixIcon: const Icon(Icons.lock_outline)),
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Introduce una contraseña.';
                      if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Campo de Confirmar Contraseña (sin cambios) ---
                  TextFormField(
                    controller: _confirmPasswordController,
                    enabled: !isLoadingFromProvider,
                    decoration: inputDecorationTheme.copyWith(labelText: 'Confirmar Contraseña', prefixIcon: const Icon(Icons.lock_reset_outlined)),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Confirma tu contraseña.';
                      if (value != _passwordController.text) return 'Las contraseñas no coinciden.';
                      return null;
                    },
                    onFieldSubmitted: (_) => isLoadingFromProvider ? null : _signUp(),
                  ),
                  const SizedBox(height: 24), // Espacio antes del botón

                  // --- Botón de Registrarse (sin cambios) ---
                  ElevatedButton(
                    onPressed: isLoadingFromProvider ? null : _signUp,
                    style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(double.infinity, 50), elevation: 2),
                    child: isLoadingFromProvider ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : const Text('Crear Cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16), // Espacio reducido

                   // --- Opción para ir a Login (sin cambios) ---
                   Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('¿Ya tienes cuenta?', style: TextStyle(color: colorScheme.onSurfaceVariant)), TextButton(onPressed: isLoadingFromProvider ? null : () { Navigator.of(context).pop(); }, child: Text('Inicia Sesión', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)))]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

