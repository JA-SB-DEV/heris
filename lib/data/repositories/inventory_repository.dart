import '../models/item.dart';
import '../models/stock_level.dart';
import '../models/location.dart';
import '../models/category.dart';
import '../datasources/firebase/firestore_service.dart';

// --- Interfaz (Contrato) ---
abstract class InventoryRepository {
  // Items
  Stream<List<Item>> getItemsStream();
  Future<void> addItem({ required String name, required String unit, String? description, required double price, required int initialStock });
  Future<void> updateItem(Item item);
  Future<void> deleteItem(String id);
  Future<bool> checkItemExistsByName(String name);
  // Stock
  Future<void> addStock({ required String itemId, required String locationId, required int quantityReceived });
  Future<StockLevel?> getStockLevel(String itemId, String locationId);
  // Locations
  Stream<List<Location>> getLocationsStream();
  Future<void> addLocation({ required String name, String? address, required bool isMainWarehouse });
  // Categories
  Stream<List<Category>> getCategoriesStream();
  Future<void> addCategory(String name);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String categoryId);
}

// --- Implementación ---
class InventoryRepositoryImpl implements InventoryRepository {
  final FirestoreService _firestoreService;
  InventoryRepositoryImpl(this._firestoreService);

  // Items
  @override Stream<List<Item>> getItemsStream() => _firestoreService.getItemsStream();
  @override Future<void> addItem({ required String name, required String unit, String? description, required double price, required int initialStock }) {
    const String mainLocationId = 'EBn1UKx7rLrnk3QcItZe'; // <-- USA TU ID REAL
    return _firestoreService.addItem( name: name, unit: unit, description: description, price: price, initialStock: initialStock, mainLocationId: mainLocationId );
  }
  @override Future<void> updateItem(Item item) => _firestoreService.updateItem(item);
  @override Future<void> deleteItem(String id) => _firestoreService.deleteItem(id);
  @override Future<bool> checkItemExistsByName(String name) => _firestoreService.checkItemExistsByName(name);
  // Stock
  @override Future<void> addStock({ required String itemId, required String locationId, required int quantityReceived }) => _firestoreService.updateStockQuantity( itemId: itemId, locationId: locationId, quantityChange: quantityReceived );
  @override Future<StockLevel?> getStockLevel(String itemId, String locationId) => _firestoreService.getStockLevel(itemId, locationId);
  // Locations
  @override Stream<List<Location>> getLocationsStream() => _firestoreService.getLocationsStream();
  @override Future<void> addLocation({ required String name, String? address, required bool isMainWarehouse }) => _firestoreService.addLocation( name: name, address: address, isMainWarehouse: isMainWarehouse );
  // Categories
  @override Stream<List<Category>> getCategoriesStream() => _firestoreService.getCategoriesStream();
  @override Future<void> addCategory(String name) => _firestoreService.addCategory(name);
  @override Future<void> updateCategory(Category category) => _firestoreService.updateCategory(category);
  @override Future<void> deleteCategory(String categoryId) => _firestoreService.deleteCategory(categoryId);
}
