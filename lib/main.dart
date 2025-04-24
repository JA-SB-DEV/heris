import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Importaciones de tu proyecto
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/firebase/firestore_service.dart';
import 'data/repositories/inventory_repository.dart';
// --- ASEGÚRATE QUE ESTOS ARCHIVOS EXISTAN, NO TENGAN ERRORES Y LAS RUTAS SEAN CORRECTAS ---
import 'presentation/providers/inventory_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/location_provider.dart';
// ------------------------------------------------------------------------------------
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
          create: (context) => InventoryRepositoryImpl(
              context.read<FirestoreService>()),
        ),

        // --- Proveedores de Estado ---
        // Si hay error aquí, revisa el archivo del provider correspondiente
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(context.read<FirestoreService>()),
        ),
        ChangeNotifierProvider<InventoryProvider>(
          create: (context) => InventoryProvider(
            context.read<InventoryRepository>(),
          ),
        ),
        ChangeNotifierProvider<LocationProvider>(
          create: (context) => LocationProvider(
            context.read<InventoryRepository>(),
          ),
        ),
        // -----------------------------
      ],
      child: MaterialApp(
        title: 'Gestión Restaurante',
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(), // Usar AuthWrapper como home
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
