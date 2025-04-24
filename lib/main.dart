import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Importaciones de tu proyecto
import 'firebase_options.dart'; // Asegúrate que este archivo exista
import 'core/theme/app_theme.dart';
import 'data/datasources/firebase/firestore_service.dart';
import 'data/repositories/inventory_repository.dart';
import 'presentation/providers/inventory_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/location_provider.dart';
// import 'presentation/providers/category_provider.dart'; // Añadir cuando se cree
import 'presentation/widgets/auth/auth_wrapper.dart';

void main() async {
  // Asegura la inicialización de los bindings de Flutter
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Ejecuta la aplicación
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usar MultiProvider para registrar todos los providers necesarios
    return MultiProvider(
      providers: [
        // 1. Proveer Servicios y Repositorios primero (son dependencias)
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        // InventoryRepository depende de FirestoreService
        Provider<InventoryRepository>(
          create: (context) => InventoryRepositoryImpl(
              context.read<FirestoreService>()),
        ),

        // 2. Proveedores de Estado (ChangeNotifierProviders)
        // AuthProvider depende de FirestoreService
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(context.read<FirestoreService>()),
        ),
        // InventoryProvider depende de InventoryRepository
        ChangeNotifierProvider<InventoryProvider>(
          create: (context) => InventoryProvider(
            context.read<InventoryRepository>(),
          ),
        ),
        // LocationProvider depende de InventoryRepository
        ChangeNotifierProvider<LocationProvider>(
          create: (context) => LocationProvider(
            context.read<InventoryRepository>(),
          ),
        ),
        // ChangeNotifierProvider<CategoryProvider>( // Añadir cuando se cree
        //   create: (context) => CategoryProvider(
        //     context.read<InventoryRepository>(),
        //   ),
        // ),
      ],
      // Widget principal de la aplicación
      child: MaterialApp(
        title: 'Heris App - Gestión Restaurante', // Título de la app
        theme: AppTheme.lightTheme, // Aplicar el tema definido
        // Usar AuthWrapper para decidir qué pantalla mostrar (Login o Main)
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false, // Ocultar banner de debug
      ),
    );
  }
}
