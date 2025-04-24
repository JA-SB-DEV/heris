import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/item.dart';
// import '../../data/models/stock_level.dart'; // No se necesita en esta versión simplificada
import '../../data/repositories/inventory_repository.dart'; // Asegúrate que este repo tenga checkItemExistsByName y addItem con description

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;
  StreamSubscription? _itemsSubscription;

  List<Item> _items = [];
  bool _isLoadingItems = false;
  String? _errorMessage; // Error general para carga, add, etc.

  // --- ESTADO Y GETTERS DE STOCK DETALLADO ELIMINADOS ---

  List<Item> get items => _items;
  bool get isLoadingItems => _isLoadingItems;
  String? get errorMessage => _errorMessage;


  InventoryProvider(this._repository) {
    fetchItems();
  }

  void fetchItems() {
    _isLoadingItems = true;
    _errorMessage = null;
    notifyListeners();

    _itemsSubscription?.cancel();
    _itemsSubscription = _repository.getItemsStream().listen(
      (itemsData) {
        _items = itemsData;
        _isLoadingItems = false;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = "Error al cargar items: ${error.toString()}";
        _isLoadingItems = false;
        _items = [];
        notifyListeners();
      },
    );
  }

  // --- addItem con verificación de nombre duplicado ---
  Future<void> addItem({
    required String name,
    required String unit,
    String? description,
    required double price,
    required int initialStock,
  }) async {
    _errorMessage = null; // Limpiar error previo
    try {
      // 1. Verificar si el nombre ya existe
      bool exists = await _repository.checkItemExistsByName(name);
      if (exists) {
        _errorMessage = "Ya existe un item con el nombre '$name'.";
        notifyListeners();
        throw Exception(_errorMessage);
      }
      // 2. Si no existe, añadir (asegúrate que el repo también acepte description)
      await _repository.addItem(
        name: name,
        unit: unit,
        description: description,
        price: price,
        initialStock: initialStock,
      );
       print("InventoryProvider: Item '$name' añadido exitosamente.");
    } catch (e) {
      if (_errorMessage == null) {
         _errorMessage = "Error al añadir item: ${e.toString()}";
      }
      print("InventoryProvider: Error final en addItem: $_errorMessage");
      notifyListeners();
      throw e;
    }
  }
  // --- FIN addItem ---

  // --- MÉTODO addStock (Para registrar entradas) ---
  Future<void> addStock({
    required String itemId,
    required String locationId, // Aún necesita el ID de la bodega
    required int quantityReceived,
  }) async {
    _errorMessage = null;
    try {
      // Llama al repositorio para actualizar el stock
      await _repository.addStock(
        itemId: itemId,
        locationId: locationId, // Pasar el ID de la ubicación
        quantityReceived: quantityReceived,
      );
      print("InventoryProvider: Llamada a addStock completada para item $itemId.");
      // Podríamos necesitar refrescar datos de stock si los mostráramos en la lista
    } catch (e) {
       _errorMessage = "Error al añadir stock: ${e.toString()}";
       notifyListeners();
       throw e;
    }
  }
  // --- FIN MÉTODO addStock ---

  // --- MÉTODO fetchStockForItem ELIMINADO ---

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    super.dispose();
  }
}
