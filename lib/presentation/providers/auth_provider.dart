import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para Timestamp

// Importa los servicios y modelos necesarios
import '../../data/datasources/firebase/firestore_service.dart'; // Asegúrate que tenga getUserData
import '../../data/models/user_model.dart'; // Asegúrate que este modelo exista y tenga 'role'

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService; // Asegúrate que el constructor lo reciba

  User? _user; // Usuario de Firebase Auth
  // --- Estado para datos del usuario de Firestore ---
  UserModel? _currentUserData; // Datos completos del usuario (incluye rol)
  bool _isLoadingUserData = false; // Estado de carga para los datos de Firestore
  // ------------------------------------------------------

  bool _isLoading = false; // Estado de carga para login/signup/createUserByAdmin
  String? _errorMessage;
  StreamSubscription? _authStateSubscription;

  // --- Getters ---
  User? get currentUser => _user;
  bool get isLoading => _isLoading; // Para login/signup/createUserByAdmin
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  // --- Getters para datos de usuario ---
  UserModel? get currentUserData => _currentUserData;
  bool get isLoadingUserData => _isLoadingUserData;
  // --- ASEGÚRATE QUE ESTE GETTER EXISTA ---
  String? get currentUserRole => _currentUserData?.role; // Acceso directo al rol
  // -----------------------------------------

  AuthProvider(this._firestoreService) { // Asegúrate que reciba FirestoreService
    _authStateSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
    print("AuthProvider inicializado.");
    // Cargar datos si ya hay un usuario al iniciar
    if (_auth.currentUser != null) {
      _user = _auth.currentUser;
      _loadCurrentUserData(); // Cargar datos al inicio si ya está logueado
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // --- Actualizado para cargar/limpiar datos de usuario ---
  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    print("AuthProvider: Estado de autenticación cambiado. Usuario: ${_user?.uid}");
    if (_user != null) {
      // Si hay usuario, intentar cargar sus datos de Firestore
      await _loadCurrentUserData();
    } else {
      // Si no hay usuario (logout), limpiar los datos
      _currentUserData = null;
      _isLoadingUserData = false; // Asegurar que no se quede cargando
      _errorMessage = null; // Limpiar errores al cerrar sesión
    }
    // Notificar SOLO después de cargar/limpiar datos (evita notificaciones múltiples)
    // La llamada a _loadCurrentUserData ya notifica al final.
    // Si _user es null, notificamos aquí.
    if (_user == null) {
        notifyListeners();
    }
  }
  // ----------------------------------------------------

  // --- Método para cargar datos del usuario desde Firestore ---
  Future<void> _loadCurrentUserData() async {
    if (_user == null) return;

    _isLoadingUserData = true;
    _errorMessage = null;
    notifyListeners(); // Notificar inicio de carga de datos

    try {
      print("AuthProvider: Cargando datos de Firestore para UID: ${_user!.uid}");
      // Asegúrate que firestoreService tenga el método getUserData
      _currentUserData = await _firestoreService.getUserData(_user!.uid);
      if (_currentUserData == null) {
        print("AuthProvider WARNING: No se encontraron datos en Firestore para el usuario ${_user!.uid}.");
        _errorMessage = "No se pudieron cargar los detalles del perfil.";
      } else {
         print("AuthProvider: Datos cargados: Rol=${_currentUserData?.role}");
         _errorMessage = null;
      }
    } catch (e) {
      print("AuthProvider ERROR cargando datos de Firestore: $e");
      _errorMessage = "Error al cargar datos del perfil.";
      _currentUserData = null;
    } finally {
      _isLoadingUserData = false;
      notifyListeners(); // Notificar fin de carga de datos
    }
  }
  // --- FIN Método para cargar datos ---


  // --- signUp (para auto-registro) ---
  Future<void> signUp({
    required String email, required String password, required String firstName,
    required String lastName, required String phone,
  }) async {
    _setLoading(true);
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password.trim(),
      );
      if (userCredential.user == null) throw Exception("Error: UserCredential no contiene usuario.");
      final newUser = userCredential.user!;
      final userModel = UserModel(
        uid: newUser.uid, firstName: firstName, lastName: lastName,
        email: email.trim(), phone: phone, role: 'user', // Rol por defecto
        createdAt: Timestamp.now(),
      );
      await _firestoreService.saveUserData(userModel);
      _errorMessage = null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthExceptionMessage(e.code);
      _user = null; _currentUserData = null; // Limpiar si falla
    } catch (e) {
      _errorMessage = "Ocurrió un error inesperado durante el registro.";
      _user = null; _currentUserData = null;
    } finally {
      _setLoading(false);
    }
  }

  // --- createUserByAdmin ---
  Future<void> createUserByAdmin({
    required String email, required String password, required String firstName,
    required String lastName, required String phone, required String role,
    String? assignedLocationId, String? assignedLocationName,
  }) async {
    _setLoading(true);
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password.trim(),
      );
      if (userCredential.user == null) throw Exception("Error: UserCredential no contiene usuario tras creación.");
      final newUser = userCredential.user!;
      final userModel = UserModel(
        uid: newUser.uid, firstName: firstName, lastName: lastName,
        email: email.trim(), phone: phone, role: role,
        // Asegúrate que UserModel maneje estos campos nullable
        // assignedLocationId: assignedLocationId,
        // assignedLocationName: assignedLocationName,
        createdAt: Timestamp.now(),
      );
      await _firestoreService.saveUserData(userModel);
      _errorMessage = null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthExceptionMessage(e.code);
    } catch (e) {
      _errorMessage = "Ocurrió un error inesperado al crear el usuario.";
    } finally {
      _setLoading(false);
    }
  }

  // --- signIn ---
  Future<void> signIn(String email, String password) async {
     _setLoading(true);
     _currentUserData = null;
     _isLoadingUserData = false;
     try {
       await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
       _errorMessage = null;
       // _onAuthStateChanged se encargará de llamar a _loadCurrentUserData
     } on FirebaseAuthException catch (e) {
        _errorMessage = _mapFirebaseAuthExceptionMessage(e.code);
        _user = null; _currentUserData = null;
     } catch (e) {
        _errorMessage = "Ocurrió un error inesperado al iniciar sesión.";
        _user = null; _currentUserData = null;
     } finally {
        _setLoading(false);
     }
  }

  // --- signOut ---
  Future<void> signOut() async {
     _setLoading(true); // Usar isLoading general para signOut
     try {
        await _auth.signOut();
        // _onAuthStateChanged limpiará _user y _currentUserData
        _errorMessage = null;
     } catch (e) {
       _errorMessage = "Error al cerrar sesión: ${e.toString()}";
     } finally {
       _setLoading(false); // Terminar estado de carga general
     }
  }

  // --- Helper _setLoading ---
  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  // --- Helper _mapFirebaseAuthExceptionMessage ---
  String _mapFirebaseAuthExceptionMessage(String code) {
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
}
