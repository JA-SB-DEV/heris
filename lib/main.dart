import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Importaciones de tu proyecto
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/firebase/firestore_service.dart';
import 'data/repositories/inventory_repository.dart'; // Asegúrate que tenga los métodos necesarios
import 'presentation/providers/inventory_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/location_provider.dart';
// --- IMPORTAR UserManagementProvider ---
import 'presentation/providers/user_management_provider.dart';
// ------------------------------------
// import 'presentation/providers/category_provider.dart'; // Añadir cuando se cree
import 'presentation/widgets/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Proveer Servicios y Repositorios primero
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        Provider<InventoryRepository>(
          // InventoryRepository depende de FirestoreService
          create: (context) => InventoryRepositoryImpl(
              context.read<FirestoreService>()),
        ),

        // Proveedores de Estado (ChangeNotifierProviders)
        ChangeNotifierProvider<AuthProvider>(
          // AuthProvider depende de FirestoreService
          create: (context) => AuthProvider(context.read<FirestoreService>()),
        ),
        ChangeNotifierProvider<InventoryProvider>(
          // InventoryProvider depende de InventoryRepository
          create: (context) => InventoryProvider(
            context.read<InventoryRepository>(),
          ),
        ),
        ChangeNotifierProvider<LocationProvider>(
          // LocationProvider depende de InventoryRepository
          create: (context) => LocationProvider(
            context.read<InventoryRepository>(),
          ),
        ),
        // --- AÑADIR UserManagementProvider ---
        ChangeNotifierProvider<UserManagementProvider>(
          // UserManagementProvider depende de InventoryRepository (que tiene getUsersStream)
          create: (context) => UserManagementProvider(
            context.read<InventoryRepository>(), // Pasa el repositorio
          ),
        ),
        // ------------------------------------
        // ChangeNotifierProvider<CategoryProvider>(...),
      ],
      child: MaterialApp(
        title: 'Heris App - Gestión Restaurante',
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(), // Usar AuthWrapper como home
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
