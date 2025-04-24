import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para Timestamp

// Importa los servicios y modelos necesarios
import '../../data/datasources/firebase/firestore_service.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // --- INYECTAR FirestoreService ---
  final FirestoreService _firestoreService;
  // ---------------------------------

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _authStateSubscription;

  User? get currentUser => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // --- Constructor actualizado para recibir FirestoreService ---
  AuthProvider(this._firestoreService) {
    _authStateSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
    print("AuthProvider inicializado. Escuchando cambios de autenticación.");
    // Opcional: Cargar datos del usuario si ya hay uno logueado al iniciar
    if (_auth.currentUser != null) {
      _user = _auth.currentUser;
      // Podrías cargar datos de Firestore aquí si es necesario al inicio
      // _loadCurrentUserData();
    }
  }
  // -------------------------------------------------------------

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    print("AuthProvider: Estado de autenticación cambiado. Usuario: ${_user?.uid}");
    // Si el usuario cierra sesión, podríamos limpiar datos específicos del usuario aquí
    notifyListeners();
  }

  // --- Método signUp ACTUALIZADO ---
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName, // Nuevo
    required String lastName,  // Nuevo
    required String phone,     // Nuevo
  }) async {
    _setLoading(true);

    try {
      print("AuthProvider: Intentando crear usuario con email: $email");
      // 1. Crear usuario en Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Verificar si el usuario se creó correctamente
      if (userCredential.user == null) {
        throw Exception("Error inesperado: UserCredential no contiene usuario.");
      }
      final newUser = userCredential.user!;
      print("AuthProvider: Usuario creado en Auth con UID: ${newUser.uid}");

      // 2. Crear el objeto UserModel con los datos adicionales
      final userModel = UserModel(
        uid: newUser.uid, // Usar el UID del usuario recién creado
        firstName: firstName,
        lastName: lastName,
        email: email.trim(),
        phone: phone,
        role: 'user', // Rol por defecto (puedes cambiarlo)
        createdAt: Timestamp.now(), // Fecha actual
      );

      // 3. Guardar los datos adicionales en Firestore
      print("AuthProvider: Intentando guardar datos adicionales en Firestore para UID: ${newUser.uid}");
      await _firestoreService.saveUserData(userModel);

      // Si llegamos aquí, todo fue exitoso
      _errorMessage = null;
      print("AuthProvider: Registro y guardado de datos completos para UID: ${newUser.uid}");
      // El listener _onAuthStateChanged se encargará de actualizar _user y notificar

    } on FirebaseAuthException catch (e) {
      print("AuthProvider: Error de FirebaseAuth - Código: ${e.code}");
      _errorMessage = _mapFirebaseAuthExceptionMessage(e.code);
      _user = null; // Asegurarse que no haya usuario si falla el registro

    } catch (e) {
      print("AuthProvider: Error inesperado en signUp: $e");
      // Si el error ocurrió después de crear el usuario en Auth pero antes de guardar en Firestore,
      // podrías considerar eliminar el usuario de Auth para evitar inconsistencias,
      // aunque esto añade complejidad. Por ahora, solo mostramos un error genérico.
      _errorMessage = "Ocurrió un error inesperado durante el registro.";
      _user = null;

    } finally {
      _setLoading(false); // Termina la carga y notifica
    }
  }
  // --- FIN Método signUp ACTUALIZADO ---

  // --- Método signIn (sin cambios en la lógica principal por ahora) ---
  Future<void> signIn(String email, String password) async {
     _setLoading(true);
     try {
       await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
       _errorMessage = null;
       // Opcional: Cargar datos del usuario desde Firestore después del login
       // if (_auth.currentUser != null) await _loadCurrentUserData();
     } on FirebaseAuthException catch (e) {
        _errorMessage = _mapFirebaseAuthExceptionMessage(e.code);
        _user = null;
     } catch (e) {
        _errorMessage = "Ocurrió un error inesperado al iniciar sesión.";
        _user = null;
     } finally {
        _setLoading(false);
     }
  }

  // --- Método signOut (sin cambios) ---
  Future<void> signOut() async {
     _setLoading(true);
     try {
        await _auth.signOut();
        _user = null;
        _errorMessage = null;
     } catch (e) {
       _errorMessage = "Error al cerrar sesión: ${e.toString()}";
     } finally {
       _setLoading(false);
     }
  }

  // --- Helper _setLoading (sin cambios) ---
  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  // --- Helper _mapFirebaseAuthExceptionMessage (sin cambios) ---
  String _mapFirebaseAuthExceptionMessage(String code) {
    // ... (código del switch sin cambios) ...
     switch (code) {
      case 'weak-password': return 'La contraseña es demasiado débil.';
      case 'email-already-in-use': return 'Este correo electrónico ya está registrado.';
      case 'invalid-email': return 'El formato del correo electrónico no es válido.';
      case 'operation-not-allowed': return 'La creación de usuarios por email/contraseña no está habilitada.';
      case 'user-disabled': return 'Esta cuenta de usuario ha sido deshabilitada.';
      case 'user-not-found': return 'No se encontró un usuario con ese correo electrónico.';
      case 'wrong-password': return 'La contraseña es incorrecta.';
      default: return 'Ocurrió un error de autenticación ($code)';
    }
  }

  // --- Opcional: Método para cargar datos del usuario desde Firestore ---
  /*
  Future<void> _loadCurrentUserData() async {
    if (_user != null) {
      try {
        final userModel = await _firestoreService.getUserData(_user!.uid);
        if (userModel != null) {
          // Aquí podrías guardar el userModel en otra variable de estado si lo necesitas
          print("AuthProvider: Datos de Firestore cargados para ${_user!.uid}");
        } else {
          print("AuthProvider: No se encontraron datos de Firestore para ${_user!.uid}");
          // Quizás cerrar sesión si los datos son obligatorios? Depende de tu lógica.
          // await signOut();
        }
      } catch (e) {
        print("AuthProvider: Error cargando datos de Firestore: $e");
        _errorMessage = "Error al cargar datos del perfil.";
        notifyListeners();
      }
    }
  }
  */
}

