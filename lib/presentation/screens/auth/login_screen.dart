import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importa el AuthProvider y las otras pantallas necesarias
import '../../providers/auth_provider.dart';
import 'sign_up_screen.dart';
import '../inventory/inventory_list_screen.dart';
import '../main/main_screen.dart'; // Importa MainScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true; // Estado para mostrar/ocultar contraseña

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- MÉTODO _login (Lógica sin cambios) ---
  Future<void> _login() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signIn(email, password);

    if (mounted) {
      if (authProvider.errorMessage == null && authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: ${authProvider.errorMessage ?? "Error desconocido"}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
  // --- FIN MÉTODO _login ---


  @override
  Widget build(BuildContext context) {
    final isLoadingFromProvider = context.watch<AuthProvider>().isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // --- ELIMINAR ESTA LÍNEA ---
    // final inputDecoration = theme.inputDecorationTheme;
    // --------------------------

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Título y Subtítulo ---
                  Text(
                    '¡Bienvenido de Nuevo!',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión en tu cuenta',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // --- Campo de Email ---
                  TextFormField(
                    controller: _emailController,
                    enabled: !isLoadingFromProvider,
                    // --- Usar InputDecoration directamente ---
                    // El estilo base (bordes, relleno) vendrá del tema
                    decoration: const InputDecoration( // Quitar .copyWith()
                      labelText: 'Correo Electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                      // hintText: 'tu@correo.com', // Opcional
                    ),
                    // --------------------------------------
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Por favor, introduce tu correo.';
                      if (!value.contains('@') || !value.contains('.')) return 'Introduce un correo válido.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- Campo de Contraseña ---
                  TextFormField(
                    controller: _passwordController,
                    enabled: !isLoadingFromProvider,
                    // --- Usar InputDecoration directamente ---
                    decoration: InputDecoration( // Quitar .copyWith()
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    // --------------------------------------
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Por favor, introduce tu contraseña.';
                      return null;
                    },
                    onFieldSubmitted: (_) => isLoadingFromProvider ? null : _login(),
                  ),
                  const SizedBox(height: 16),

                  // --- Botón Olvidé Contraseña ---
                   Align(
                     alignment: Alignment.centerRight,
                     child: TextButton(
                       onPressed: isLoadingFromProvider ? null : () {
                         print('Botón Olvidé Contraseña presionado');
                       },
                       child: const Text('¿Olvidaste contraseña?'),
                     ),
                   ),
                  const SizedBox(height: 32),

                  // --- Botón de Iniciar Sesión ---
                  ElevatedButton(
                    onPressed: isLoadingFromProvider ? null : _login,
                     style: ElevatedButton.styleFrom(
                       minimumSize: const Size(double.infinity, 52),
                       elevation: 3,
                     ),
                    child: isLoadingFromProvider
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                          )
                        : const Text('Ingresar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),

                  // --- Opción para Registrarse ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta?',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      TextButton(
                         onPressed: isLoadingFromProvider ? null : () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const SignUpScreen(),
                              transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
                            )
                          );
                        },
                        child: const Text('Regístrate'),
                      ),
                    ],
                  ),
                  // --- Sección comentada de Social Login (sin cambios) ---
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
