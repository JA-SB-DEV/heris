import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart'; // Importar el modelo de usuario
import '../../data/repositories/inventory_repository.dart'; // Importar el repositorio

// Provider para gestionar la lista de usuarios (para la pantalla de administración)
class UserManagementProvider extends ChangeNotifier {
  final InventoryRepository _repository; // Dependencia del repositorio
  StreamSubscription? _usersSubscription; // Suscripción al stream de usuarios

  // --- Estado ---
  List<UserModel> _users = []; // Lista de usuarios cargados
  bool _isLoading = false; // Estado de carga de la lista
  String? _errorMessage; // Mensaje de error si falla la carga
  // ----------------

  // --- Getters ---
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  // ---------------

  // Constructor: Recibe el repositorio e inicia la carga de usuarios
  UserManagementProvider(this._repository) {
    print("UserManagementProvider initialized. Fetching users...");
    fetchUsers();
  }

  // Método para obtener/escuchar la lista de usuarios
  void fetchUsers() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Notificar inicio de carga

    _usersSubscription?.cancel(); // Cancelar suscripción anterior
    // Escuchar el stream de usuarios desde el repositorio
    _usersSubscription = _repository.getUsersStream().listen(
      (usersData) {
        // Éxito al recibir datos
        _users = usersData;
        _isLoading = false;
        _errorMessage = null; // Limpiar error en caso de éxito
        print("UserManagementProvider: Received ${usersData.length} users.");
        notifyListeners(); // Notificar con la nueva lista
      },
      onError: (error) {
        // Error al recibir datos del stream
        _errorMessage = "Error loading users: ${error.toString()}";
        print("UserManagementProvider ERROR fetching users: $_errorMessage");
        _isLoading = false;
        _users = []; // Limpiar lista en caso de error
        notifyListeners(); // Notificar sobre el error
      },
    );
  }

  // TODO: Añadir métodos para editar/eliminar usuarios aquí si es necesario
  // Future<void> updateUser(...) async { ... }
  // Future<void> deleteUser(...) async { ... }

  // Limpiar la suscripción al stream cuando el provider se deseche
  @override
  void dispose() {
    print("UserManagementProvider disposed. Cancelling subscription.");
    _usersSubscription?.cancel();
    super.dispose();
  }
}
