import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/item.dart';
import '../../models/user_model.dart';
import '../../models/stock_level.dart';
import '../../models/location.dart';
import '../../models/category.dart';
import '../../../core/constants/app_constants.dart'; // Asegúrate que las constantes existan

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Métodos para Usuarios ---
  Future<void> saveUserData(UserModel user) async {
     try {
      await _db.collection(AppConstants.usersCollection).doc(user.uid).set(user.toJson());
      print("FirestoreService: Datos del usuario ${user.uid} guardados.");
    } catch (e) {
      print("FirestoreService: Error guardando datos usuario ${user.uid}: $e");
      throw Exception("No se pudieron guardar los datos del usuario.");
    }
  }
  Future<UserModel?> getUserData(String uid) async {
     try {
      final docSnapshot = await _db.collection(AppConstants.usersCollection).doc(uid).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return UserModel.fromFirestore(docSnapshot as DocumentSnapshot<Map<String, dynamic>>);
      } else {
        print("FirestoreService: No se encontró documento para usuario $uid");
        return null;
      }
    } catch (e) {
      print("FirestoreService: Error obteniendo datos usuario $uid: $e");
      return null; // O relanzar
    }
  }
  // TODO: Añadir método para obtener lista de usuarios (para ManageUsersScreen)
  // Stream<List<UserModel>> getUsersStream() { ... }


  // --- Métodos para Items ---
  Stream<List<Item>> getItemsStream() {
     return _db.collection(AppConstants.itemsCollection)
        .orderBy('nameLowercase') // Ordenar por nombre en minúsculas
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Item.fromJson(doc.data(), doc.id))
            .toList());
   }
  Future<void> addItem({
    required String name, required String unit, String? description,
    required double price, required int initialStock, required String mainLocationId,
   }) async {
     final tempItem = Item(id: '', name: name, unit: unit, description: description, price: price);
     final newItemData = tempItem.toJson();
     newItemData['createdAt'] = Timestamp.now();
     try {
       DocumentReference itemRef = await _db.collection(AppConstants.itemsCollection).add(newItemData);
       String newItemId = itemRef.id;
       print("FirestoreService: Item '$name' añadido con ID: $newItemId");
       await addInitialStock(itemId: newItemId, locationId: mainLocationId, quantity: initialStock);
     } catch (e) {
       print("FirestoreService: Error añadiendo item '$name': $e");
       throw Exception("Error al guardar el item o su stock inicial.");
     }
   }
  Future<bool> checkItemExistsByName(String name) async {
     final lowercaseName = name.trim().toLowerCase();
     if (lowercaseName.isEmpty) return false;
     try {
       final querySnapshot = await _db.collection(AppConstants.itemsCollection)
           .where('nameLowercase', isEqualTo: lowercaseName).limit(1).get();
       return querySnapshot.docs.isNotEmpty;
     } catch (e) {
       print("FirestoreService: Error verificando item '$name': $e");
       throw Exception("Error al verificar el nombre del item.");
     }
   }
  Future<void> updateItem(Item item) {
      final updatedData = item.toJson();
      updatedData['updatedAt'] = FieldValue.serverTimestamp();
      return _db.collection(AppConstants.itemsCollection).doc(item.id).update(updatedData);
   }
   Future<void> deleteItem(String id) {
     // TODO: Considerar borrar stock asociado
     return _db.collection(AppConstants.itemsCollection).doc(id).delete();
   }

   // --- Métodos para Stock ---
   Future<void> addInitialStock({
    required String itemId, required String locationId, required int quantity,
   }) async {
     final stockDocId = '${itemId}_$locationId';
     final stockRef = _db.collection(AppConstants.stockLevelsCollection).doc(stockDocId);
     final stockData = {'itemId': itemId, 'locationId': locationId, 'quantity': quantity, 'lastUpdated': Timestamp.now()};
     try {
       await stockRef.set(stockData); // Usar set para crear o sobrescribir
       print("FirestoreService: Stock inicial ($quantity) añadido para $stockDocId");
     } catch (e) {
        print("FirestoreService: Error añadiendo stock inicial para $stockDocId: $e");
        throw Exception("Error al guardar stock inicial.");
     }
   }
   Future<void> updateStockQuantity({
    required String itemId, required String locationId, required int quantityChange,
   }) async {
     final stockDocId = '${itemId}_$locationId';
     final stockRef = _db.collection(AppConstants.stockLevelsCollection).doc(stockDocId);
     try {
       await stockRef.update({
         'quantity': FieldValue.increment(quantityChange),
         'lastUpdated': FieldValue.serverTimestamp(),
       });
       print("FirestoreService: Stock actualizado para $stockDocId (cambio: $quantityChange)");
     } on FirebaseException catch (e) {
       print("FirestoreService: Error Firebase actualizando stock $stockDocId: ${e.code}");
       if (e.code == 'not-found') {
         throw Exception("No se encontró registro de stock para este item/ubicación.");
       } else { throw Exception("Error Firebase al actualizar stock: ${e.message}"); }
     } catch (e) {
        print("FirestoreService: Error inesperado actualizando stock $stockDocId: $e");
        throw Exception("Error inesperado al actualizar el stock.");
     }
   }
   Future<StockLevel?> getStockLevel(String itemId, String locationId) async {
    final stockDocId = '${itemId}_$locationId';
    final stockRef = _db.collection(AppConstants.stockLevelsCollection).doc(stockDocId);
    try {
      final docSnapshot = await stockRef.get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return StockLevel.fromFirestore(docSnapshot as DocumentSnapshot<Map<String, dynamic>>);
      } else { return null; }
    } catch (e) {
      print("FirestoreService: Error obteniendo stock $stockDocId: $e");
      throw Exception("Error al obtener el nivel de stock.");
    }
  }

  // --- Métodos para Sedes ---
  Stream<List<Location>> getLocationsStream() {
    return _db.collection(AppConstants.locationsCollection)
        .orderBy('name') // Ordenar por nombre
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Location.fromFirestore(doc)).toList());
  }
  Future<void> addLocation({
    required String name, String? address, required bool isMainWarehouse,
  }) async {
    final newLocationData = {
      'name': name.trim(), 'address': address?.trim(),
      'isMainWarehouse': isMainWarehouse, 'createdAt': Timestamp.now(),
    };
    try {
      // TODO: Añadir validación para asegurar solo una isMainWarehouse=true
      await _db.collection(AppConstants.locationsCollection).add(newLocationData);
      print("FirestoreService: Sede '$name' añadida.");
    } catch (e) {
      print("FirestoreService: Error añadiendo sede '$name': $e");
      throw Exception("No se pudo guardar la nueva sede.");
    }
  }
  // TODO: Añadir updateLocation, deleteLocation

  // --- Métodos para Categorías ---
  Stream<List<Category>> getCategoriesStream() {
    return _db.collection(AppConstants.itemCategoriesCollection).orderBy('name').snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList());
  }
  Future<void> addCategory(String name) async {
    final categoryData = {'name': name.trim()};
    try {
      // TODO: Añadir validación nombre duplicado
      await _db.collection(AppConstants.itemCategoriesCollection).add(categoryData);
      print("FirestoreService: Categoría '$name' añadida.");
    } catch (e) { throw Exception("No se pudo guardar la categoría."); }
  }
  Future<void> updateCategory(Category category) async {
    try {
      await _db.collection(AppConstants.itemCategoriesCollection).doc(category.id).update(category.toJson());
      print("FirestoreService: Categoría '${category.name}' actualizada.");
    } catch (e) { throw Exception("No se pudo actualizar la categoría."); }
  }
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _db.collection(AppConstants.itemCategoriesCollection).doc(categoryId).delete();
      print("FirestoreService: Categoría $categoryId eliminada.");
    } catch (e) { throw Exception("No se pudo eliminar la categoría."); }
  }
  // --- FIN Métodos para Categorías ---

  // --- Métodos para Transferencias (Pendientes) ---
  // Future<void> createTransfer(...) async { ... } // Usará Transacción
  // Stream<List<Transfer>> getTransfersStream() { ... }

}
