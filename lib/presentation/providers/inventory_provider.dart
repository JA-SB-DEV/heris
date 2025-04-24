import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/item.dart';
import '../../data/models/stock_level.dart'; // <-- RE-AÑADIR Import StockLevel
import '../../data/repositories/inventory_repository.dart'; // Asegúrate que este repositorio TENGA getStockLevel

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;
  StreamSubscription? _itemsSubscription;

  List<Item> _items = [];
  bool _isLoadingItems = false;
  String? _errorMessage; // Error general

  // --- RE-AÑADIR: Estado para el stock del item seleccionado ---
  StockLevel? _selectedItemStock;
  bool _isLoadingStock = false; // Estado de carga específico para buscar stock
  String? _errorFetchingStock; // Error específico para buscar stock
  // ----------------------------------------------------------

  List<Item> get items => _items;
  bool get isLoadingItems => _isLoadingItems;
  String? get errorMessage => _errorMessage;

  // --- RE-AÑADIR: Getters para el estado del stock ---
  // Asegúrate de que estos getters existan en tu archivo
  StockLevel? get selectedItemStock => _selectedItemStock;
  bool get isLoadingStock => _isLoadingStock;
  String? get errorFetchingStock => _errorFetchingStock; // <-- GETTER NECESARIO
  // ---------------------------------------------------

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

  // --- addItem con verificación (sin cambios) ---
  Future<void> addItem({
    required String name,
    required String unit,
    String? description,
    required double price,
    required int initialStock,
  }) async {
    _errorMessage = null;
    try {
      bool exists = await _repository.checkItemExistsByName(name);
      if (exists) {
        _errorMessage = "Ya existe un item con el nombre '$name'.";
        notifyListeners();
        throw Exception(_errorMessage);
      }
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

  // --- MÉTODO addStock (sin cambios) ---
  Future<void> addStock({
    required String itemId,
    required String locationId, // Aún necesita el ID de la bodega
    required int quantityReceived,
  }) async {
    _errorMessage = null;
    try {
      await _repository.addStock(
        itemId: itemId,
        locationId: locationId, // Pasar el ID de la ubicación
        quantityReceived: quantityReceived,
      );
      print("InventoryProvider: Llamada a addStock completada para item $itemId.");
    } catch (e) {
       _errorMessage = "Error al añadir stock: ${e.toString()}";
       notifyListeners();
       throw e;
    }
  }
  // --- FIN MÉTODO addStock ---


  // --- RE-AÑADIR: Método para buscar el stock de un item específico ---
  // Asegúrate de que este método exista en tu archivo
  Future<void> fetchStockForItem(String itemId, String locationId) async {
    _isLoadingStock = true; // Iniciar carga específica
    _errorFetchingStock = null; // Limpiar error específico previo
    _selectedItemStock = null; // Limpiar stock anterior
    notifyListeners(); // Notificar inicio de carga de stock

    try {
      // Llama al método del repositorio (que ahora debe existir)
      _selectedItemStock = await _repository.getStockLevel(itemId, locationId);
      print("InventoryProvider: Stock para $itemId en $locationId: ${_selectedItemStock?.quantity}");

    } catch (e) {
      print("InventoryProvider: Error buscando stock para $itemId: $e");
      _errorFetchingStock = "Error al obtener stock: ${e.toString()}"; // Guardar error específico
    } finally {
      _isLoadingStock = false; // Finalizar carga específica
      notifyListeners(); // Notificar fin de carga (con datos o error)
    }
  }
  // --- FIN RE-AÑADIR MÉTODO ---

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    super.dispose();
  }
}
