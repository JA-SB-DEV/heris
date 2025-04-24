import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/main/main_screen.dart'; // Importa MainScreen

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha los cambios en el estado de autenticación
    final authProvider = context.watch<AuthProvider>();

    print("AuthWrapper: Usuario autenticado? ${authProvider.isAuthenticated}");

    // Decide qué pantalla mostrar basado en el estado de autenticación
    if (authProvider.isAuthenticated) {
      // Si está autenticado, muestra la pantalla principal con navegación
      return const MainScreen();
    } else {
      // Si no, muestra la pantalla de login
      return const LoginScreen();
    }
  }
}
