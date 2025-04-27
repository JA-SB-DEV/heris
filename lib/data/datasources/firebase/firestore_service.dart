import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/item.dart';
import '../../models/user_model.dart';
import '../../models/stock_level.dart';
import '../../models/location.dart';
import '../../models/category.dart';
import '../../../core/constants/app_constants.dart'; // Asegúrate que las constantes existan

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Asegúrate que AppConstants tenga definidas las colecciones necesarias
  // static const String _usersCollection = AppConstants.usersCollection;
  // static const String _itemsCollection = AppConstants.itemsCollection;
  // static const String _stockLevelsCollection = AppConstants.stockLevelsCollection;
  // static const String _locationsCollection = AppConstants.locationsCollection;
  // static const String _itemCategoriesCollection = AppConstants.itemCategoriesCollection;

  // --- User Methods ---
  Future<void> saveUserData(UserModel user) async {
    try {
      // Ensure AppConstants.usersCollection is defined
      await _db
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(user.toJson());
      print("FirestoreService: User data ${user.uid} saved successfully.");
    } catch (e) {
      print("FirestoreService: Error saving user data ${user.uid}: $e");
      throw Exception("Could not save user data to Firestore.");
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      // Ensure AppConstants.usersCollection is defined
      final docSnapshot =
          await _db.collection(AppConstants.usersCollection).doc(uid).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        // Ensure UserModel.fromFirestore exists and works
        return UserModel.fromFirestore(
          docSnapshot as DocumentSnapshot<Map<String, dynamic>>,
        );
      } else {
        print("FirestoreService: No document found for user $uid");
        return null;
      }
    } catch (e) {
      print("FirestoreService: Error getting user data $uid: $e");
      return null; // Or rethrow
    }
  }

  // --- NUEVO: Método para obtener Stream de Usuarios ---
  // Devuelve un stream que emite la lista de todos los usuarios (UserModel)
  // Ordenados por nombre para una visualización consistente.
  Stream<List<UserModel>> getUsersStream() {
    print("FirestoreService: Obteniendo stream de usuarios...");
    return _db
        .collection(AppConstants.usersCollection)
        .orderBy('firstName') // Ordenar por nombre (o 'createdAt', etc.)
        .snapshots() // Escuchar cambios en tiempo real
        .map((snapshot) {
          // Transforma el QuerySnapshot
          print(
            "FirestoreService: Recibidos ${snapshot.docs.length} documentos de usuario.",
          );
          try {
            // Mapea cada documento a un objeto UserModel
            return snapshot.docs
                .map(
                  (doc) => UserModel.fromFirestore(
                    doc as DocumentSnapshot<Map<String, dynamic>>,
                  ),
                )
                .toList(); // Convierte a una lista
          } catch (e) {
            print("FirestoreService: Error mapeando documentos de usuario: $e");
            return <UserModel>[]; // Devuelve lista vacía en caso de error
          }
        });
  }
  // --- FIN NUEVO MÉTODO ---

  // --- Item and Stock Methods ---
  Stream<List<Item>> getItemsStream() {
    // Ensure AppConstants.itemsCollection is defined
    return _db
        .collection(AppConstants.itemsCollection)
        .orderBy('nameLowercase') // Order by name
        .snapshots()
        .map((snapshot) {
          print(
            "FirestoreService: Received ${snapshot.docs.length} items from stream.",
          );
          try {
            // Ensure Item.fromJson exists and works
            return snapshot.docs
                .map((doc) => Item.fromJson(doc.data(), doc.id))
                .toList();
          } catch (e) {
            print("FirestoreService: Error in getItemsStream map: $e");
            return <Item>[]; // Return empty list on mapping error
          }
        });
  }

  Future<void> addItem({
    required String name,
    required String unit,
    String? description,
    required double price,
    required int initialStock,
    required String mainLocationId, // Recibe el ID ya obtenido
  }) async {
    // Ensure Item constructor and toJson include nameLowercase
    final tempItem = Item(
      id: '',
      name: name,
      unit: unit,
      description: description,
      price: price,
    );
    final newItemData = tempItem.toJson();
    newItemData['createdAt'] = Timestamp.now(); // Add creation timestamp
    try {
      // Ensure AppConstants.itemsCollection is defined
      DocumentReference itemRef = await _db
          .collection(AppConstants.itemsCollection)
          .add(newItemData);
      String newItemId = itemRef.id;
      print("FirestoreService: Item '$name' added with ID: $newItemId");
      // Ensure addInitialStock is defined and works
      await addInitialStock(
        itemId: newItemId,
        locationId: mainLocationId,
        quantity: initialStock,
      );
    } catch (e) {
      print(
        "FirestoreService: Error adding item '$name' or its initial stock: $e",
      );
      throw Exception("Error saving item or its initial stock.");
    }
  }

  // Ensure this method definition is correct
  Future<void> addInitialStock({
    required String itemId,
    required String locationId,
    required int quantity,
  }) async {
    final stockDocId = '${itemId}_$locationId';
    // Ensure AppConstants.stockLevelsCollection is defined
    final stockRef = _db
        .collection(AppConstants.stockLevelsCollection)
        .doc(stockDocId);
    final stockData = {
      'itemId': itemId,
      'locationId': locationId,
      'quantity': quantity,
      'lastUpdated': Timestamp.now(), // Use client timestamp for initial stock
    };
    try {
      await stockRef.set(stockData); // Use set to create/overwrite
      print(
        "FirestoreService: Initial stock ($quantity) added for item $itemId at $locationId",
      );
    } catch (e) {
      print(
        "FirestoreService: Error adding initial stock for item $itemId at $locationId: $e",
      );
      throw Exception("Error saving initial stock.");
    }
  }

  Future<bool> checkItemExistsByName(String name) async {
    final lowercaseName = name.trim().toLowerCase();
    if (lowercaseName.isEmpty) return false;
    print(
      "FirestoreService: Checking existence for item name (lowercase): '$lowercaseName'",
    );
    try {
      // Ensure AppConstants.itemsCollection is defined
      final querySnapshot =
          await _db
              .collection(AppConstants.itemsCollection)
              .where('nameLowercase', isEqualTo: lowercaseName)
              .limit(1)
              .get();
      bool exists = querySnapshot.docs.isNotEmpty;
      print(
        "FirestoreService: Item '$name' ${exists ? 'EXISTS' : 'does NOT exist'}.",
      );
      return exists;
    } catch (e) {
      print("FirestoreService: ERROR checking item existence '$name': $e");
      throw Exception("Error checking item name: ${e.toString()}");
    }
  }

  Future<void> updateItem(Item item) async {
    // Ensure item.toJson exists and includes nameLowercase
    final updatedData = item.toJson();
    updatedData['updatedAt'] =
        FieldValue.serverTimestamp(); // Add update timestamp
    print("FirestoreService: Updating item ${item.id} with data: $updatedData");
    try {
      // Ensure AppConstants.itemsCollection is defined
      await _db
          .collection(AppConstants.itemsCollection)
          .doc(item.id)
          .update(updatedData);
      print("FirestoreService: Item ${item.id} updated successfully.");
    } catch (e) {
      print("FirestoreService: Error updating item ${item.id}: $e");
      throw Exception("Error updating item: ${e.toString()}");
    }
  }

  Future<void> deleteItem(String itemId, String mainLocationId) async {
    // Ensure AppConstants.itemsCollection and stockLevelsCollection are defined
    final itemRef = _db.collection(AppConstants.itemsCollection).doc(itemId);
    final stockDocId = '${itemId}_$mainLocationId';
    final stockRef = _db
        .collection(AppConstants.stockLevelsCollection)
        .doc(stockDocId);
    WriteBatch batch = _db.batch();
    try {
      print(
        "FirestoreService: Checking stock to delete item $itemId at $mainLocationId",
      );
      DocumentSnapshot stockSnapshot = await stockRef.get();
      int currentStock = 0;
      if (stockSnapshot.exists && stockSnapshot.data() != null) {
        currentStock =
            (stockSnapshot.data() as Map<String, dynamic>)['quantity'] ?? 0;
      }
      print("FirestoreService: Current stock found: $currentStock");

      if (currentStock > 0) {
        print(
          "FirestoreService: Cannot delete item $itemId, stock is $currentStock.",
        );
        throw Exception(
          "Cannot delete item with stock ($currentStock units). Adjust stock to zero first.",
        );
      }

      print(
        "FirestoreService: Stock is 0. Proceeding to delete item and stock record.",
      );
      batch.delete(itemRef); // Add item deletion to batch
      if (stockSnapshot.exists) {
        batch.delete(stockRef);
      } // Add stock record deletion if exists
      // TODO: Consider deleting stock records from OTHER locations as well

      await batch.commit(); // Execute the batch
      print(
        "FirestoreService: Item $itemId and its stock at $mainLocationId deleted successfully.",
      );
    } on FirebaseException catch (e) {
      print(
        "FirestoreService: Firebase error deleting item $itemId: ${e.code} - ${e.message}",
      );
      throw Exception("Database error deleting item: ${e.message}");
    } catch (e) {
      print("FirestoreService: Error deleting item $itemId: $e");
      throw e; // Re-throw original exception
    }
  }

  Future<void> updateStockQuantity({
    required String itemId,
    required String locationId,
    required int quantityChange, // Parameter name corrected
  }) async {
    final stockDocId = '${itemId}_$locationId';
    // Ensure AppConstants.stockLevelsCollection is defined
    final stockRef = _db
        .collection(AppConstants.stockLevelsCollection)
        .doc(stockDocId);
    try {
      // Use FieldValue.increment with the correct parameter name
      await stockRef.update({
        'quantity': FieldValue.increment(quantityChange), // Use quantityChange
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print(
        "FirestoreService: Stock updated for item $itemId at $locationId (change: $quantityChange)",
      );
    } on FirebaseException catch (e) {
      print(
        "FirestoreService: Firebase error updating stock for item $itemId at $locationId: ${e.code} - ${e.message}",
      );
      if (e.code == 'not-found') {
        print(
          "CRITICAL Error: Stock document $stockDocId DOES NOT EXIST. Cannot update.",
        );
        throw Exception(
          "Stock record not found for this item/location. Was initial stock added correctly?",
        );
      } else {
        throw Exception("Firebase error updating stock: ${e.message}");
      }
    } catch (e) {
      print(
        "FirestoreService: Unexpected error updating stock for item $itemId at $locationId: $e",
      );
      throw Exception("Unexpected error updating stock.");
    }
  }

  Future<StockLevel?> getStockLevel(String itemId, String locationId) async {
    final stockDocId = '${itemId}_$locationId';
    // Ensure AppConstants.stockLevelsCollection is defined
    final stockRef = _db
        .collection(AppConstants.stockLevelsCollection)
        .doc(stockDocId);
    try {
      print("FirestoreService: Getting stock document: $stockDocId");
      final docSnapshot = await stockRef.get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        print("FirestoreService: Document $stockDocId found.");
        // Ensure StockLevel.fromFirestore exists and works
        return StockLevel.fromFirestore(
          docSnapshot as DocumentSnapshot<Map<String, dynamic>>,
        );
      } else {
        print("FirestoreService: No stock record found for $stockDocId");
        return null; // Return null if no stock record exists
      }
    } catch (e) {
      print("FirestoreService: Error getting stock for $stockDocId: $e");
      throw Exception("Error getting stock level.");
    }
  }

  // --- METHOD TO GET ALL STOCK LEVELS FOR A LOCATION ---
  Future<Map<String, int>> getStockLevelsForLocation(String locationId) async {
    print(
      "FirestoreService: Getting all stock levels for Location ID: $locationId",
    );
    Map<String, int> stockMap = {}; // Map to store itemId -> quantity
    try {
      // Query the stockLevels collection, filtering by locationId
      // Ensure AppConstants.stockLevelsCollection is defined
      final querySnapshot =
          await _db
              .collection(AppConstants.stockLevelsCollection)
              .where(
                'locationId',
                isEqualTo: locationId,
              ) // Filter by the specific location
              .get();

      // Iterate over the documents found
      for (var doc in querySnapshot.docs) {
        final data = doc.data(); // Get the document data
        final itemId = data['itemId'] as String?; // Get the item ID
        final quantity =
            (data['quantity'] as num?)?.toInt() ?? 0; // Get the quantity
        // If itemId is not null, add it to the map
        if (itemId != null) {
          stockMap[itemId] = quantity;
        }
      }
      print(
        "FirestoreService: Found ${stockMap.length} stock records for $locationId.",
      );
      return stockMap; // Return the map of stocks
    } catch (e) {
      // Handle any errors during the query
      print("FirestoreService: Error getting stocks for $locationId: $e");
      throw Exception("Error getting stock levels: ${e.toString()}");
    }
  }
  // --- END METHOD ---

  // --- Location Methods ---
  Stream<List<Location>> getLocationsStream() {
    // Ensure Location.fromFirestore exists and AppConstants.locationsCollection defined
    return _db
        .collection(AppConstants.locationsCollection)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Location.fromFirestore(doc)).toList(),
        );
  }

  Future<void> addLocation({
    required String name,
    String? address,
    required bool isMainWarehouse,
  }) async {
    final newLocationData = {
      'name': name.trim(),
      'address': address?.trim(),
      'isMainWarehouse': isMainWarehouse,
      'createdAt': Timestamp.now(),
    };
    try {
      // Ensure AppConstants.locationsCollection is defined
      await _db
          .collection(AppConstants.locationsCollection)
          .add(newLocationData);
      print("FirestoreService: Location '$name' added.");
    } catch (e) {
      print("FirestoreService: Error adding location '$name': $e");
      throw Exception("Could not save the new location.");
    }
  }

  // --- MÉTODO PARA OBTENER EL ID DE LA BODEGA PRINCIPAL ---
  // ASEGÚRATE DE QUE ESTE MÉTODO ESTÉ PRESENTE
  Future<String> getMainLocationId() async {
    print("FirestoreService: Getting Main Warehouse ID...");
    try {
      // Ensure AppConstants.locationsCollection is defined
      final querySnapshot =
          await _db
              .collection(AppConstants.locationsCollection)
              .where('isMainWarehouse', isEqualTo: true)
              .limit(1)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        final mainWarehouseId = querySnapshot.docs.first.id;
        print("FirestoreService: Main Warehouse ID found: $mainWarehouseId");
        return mainWarehouseId;
      } else {
        print(
          "FirestoreService ERROR: No location marked as Main Warehouse found.",
        );
        throw Exception('Required Setup: No Main Warehouse found.');
      }
    } catch (e) {
      print("FirestoreService ERROR getting Main Warehouse ID: $e");
      throw Exception('Error getting Main Warehouse ID: ${e.toString()}');
    }
  }
  // --- FIN MÉTODO ---

  // --- Category Methods ---
  Stream<List<Category>> getCategoriesStream() {
    // Ensure Category.fromFirestore exists and AppConstants.itemCategoriesCollection defined
    return _db
        .collection(AppConstants.itemCategoriesCollection)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList(),
        );
  }

  Future<void> addCategory(String name) async {
    final categoryData = {'name': name.trim()};
    try {
      // Ensure AppConstants.itemCategoriesCollection is defined
      await _db
          .collection(AppConstants.itemCategoriesCollection)
          .add(categoryData);
      print("FirestoreService: Category '$name' added.");
    } catch (e) {
      throw Exception("Could not save category.");
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      // Ensure category.toJson() exists and AppConstants.itemCategoriesCollection defined
      await _db
          .collection(AppConstants.itemCategoriesCollection)
          .doc(category.id)
          .update(category.toJson());
      print("FirestoreService: Category '${category.name}' updated.");
    } catch (e) {
      throw Exception("Could not update category.");
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      // Ensure AppConstants.itemCategoriesCollection is defined
      await _db
          .collection(AppConstants.itemCategoriesCollection)
          .doc(categoryId)
          .delete();
      print("FirestoreService: Category $categoryId deleted.");
    } catch (e) {
      throw Exception("Could not delete category.");
    }
  }
}
