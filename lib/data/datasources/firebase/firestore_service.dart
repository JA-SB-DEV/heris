import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/item.dart';
import '../../models/user_model.dart';
import '../../models/stock_level.dart'; // <-- Importar StockLevel
import '../../models/location.dart'; // <-- Importar Location
import '../../../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';
  // Asegúrate que AppConstants.locationsCollection y stockLevelsCollection estén definidos
  // static const String _locationsCollection = 'locations'; // O usar AppConstants
  // static const String _stockLevelsCollection = 'stockLevels'; // O usar AppConstants

  // --- Métodos para Usuarios (sin cambios) ---
  Future<void> saveUserData(UserModel user) async {
     try {
      await _db.collection(_usersCollection).doc(user.uid).set(user.toJson());
      print("FirestoreService: Datos del usuario ${user.uid} guardados correctamente.");
    } catch (e) {
      print("FirestoreService: Error al guardar datos del usuario ${user.uid}: $e");
      throw Exception("No se pudieron guardar los datos del usuario en Firestore.");
    }
  }
  Future<UserModel?> getUserData(String uid) async {
     try {
      final docSnapshot = await _db.collection(_usersCollection).doc(uid).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data() as Map<String, dynamic>;
         return UserModel(
           uid: uid,
           firstName: data['firstName'] ?? '',
           lastName: data['lastName'] ?? '',
           email: data['email'] ?? '',
           phone: data['phone'] ?? '',
           role: data['role'] as String?,
           createdAt: data['createdAt'] ?? Timestamp.now(),
         );
      } else {
        print("FirestoreService: No se encontró documento para el usuario $uid");
        return null;
      }
    } catch (e) {
      print("FirestoreService: Error al obtener datos del usuario $uid: $e");
      return null;
    }
  }


  // --- Métodos para Items y Stock ---
  Stream<List<Item>> getItemsStream() {
     return _db
        .collection(AppConstants.itemsCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Item.fromJson(doc.data(), doc.id))
            .toList());
   }
  Future<void> addItem({
    required String name,
    required String unit,
    String? description,
    required double price,
    required int initialStock,
    required String mainLocationId,
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
       print("FirestoreService: Error al añadir item '$name' o su stock inicial: $e");
       throw Exception("Error al guardar el item o su stock inicial.");
     }
   }
  Future<void> addInitialStock({
    required String itemId,
    required String locationId,
    required int quantity,
   }) async {
     final stockDocId = '${itemId}_$locationId';
     final stockRef = _db.collection(AppConstants.stockLevelsCollection).doc(stockDocId);
     final stockData = {
       'itemId': itemId,
       'locationId': locationId,
       'quantity': quantity,
       'lastUpdated': Timestamp.now(),
     };
     try {
       await stockRef.set(stockData);
       print("FirestoreService: Stock inicial ($quantity) añadido para item $itemId en $locationId");
     } catch (e) {
        print("FirestoreService: Error al añadir stock inicial para item $itemId en $locationId: $e");
        throw Exception("Error al guardar stock inicial.");
     }
   }
  Future<bool> checkItemExistsByName(String name) async {
     final lowercaseName = name.trim().toLowerCase();
     if (lowercaseName.isEmpty) return false;
     try {
       final querySnapshot = await _db
           .collection(AppConstants.itemsCollection)
           .where('nameLowercase', isEqualTo: lowercaseName)
           .limit(1)
           .get();
       return querySnapshot.docs.isNotEmpty;
     } catch (e) {
       print("FirestoreService: Error verificando existencia de item '$name': $e");
       throw Exception("Error al verificar el nombre del item.");
     }
   }
  Future<void> updateItem(Item item) {
      final updatedData = item.toJson();
      updatedData['updatedAt'] = FieldValue.serverTimestamp();
      return _db.collection(AppConstants.itemsCollection).doc(item.id).update(updatedData);
   }
   Future<void> deleteItem(String id) {
     return _db.collection(AppConstants.itemsCollection).doc(id).delete();
   }
  Future<void> updateStockQuantity({
    required String itemId,
    required String locationId,
    required int quantityChange,
   }) async {
     final stockDocId = '${itemId}_$locationId';
     final stockRef = _db.collection(AppConstants.stockLevelsCollection).doc(stockDocId);
     try {
       await stockRef.update({
         'quantity': FieldValue.increment(quantityChange),
         'lastUpdated': FieldValue.serverTimestamp(),
       });
       print("FirestoreService: Stock actualizado para item $itemId en $locationId (cambio: $quantityChange)");
     } on FirebaseException catch (e) {
       print("FirestoreService: Error de Firebase al actualizar stock para item $itemId en $locationId: ${e.code} - ${e.message}");
       if (e.code == 'not-found') {
         print("Error Crítico: El documento de stock $stockDocId NO EXISTE. No se puede actualizar.");
         throw Exception("No se encontró registro de stock para este item en esta ubicación. ¿Se añadió correctamente el stock inicial?");
       } else {
         throw Exception("Error de Firebase al actualizar stock: ${e.message}");
       }
     } catch (e) {
        print("FirestoreService: Error inesperado al actualizar stock para item $itemId en $locationId: $e");
        throw Exception("Error inesperado al actualizar el stock.");
     }
   }

  // --- ASEGÚRATE QUE ESTE MÉTODO EXISTA ---
  Future<StockLevel?> getStockLevel(String itemId, String locationId) async {
    final stockDocId = '${itemId}_$locationId';
    // Asegúrate que AppConstants.stockLevelsCollection esté definido
    final stockRef = _db.collection(AppConstants.stockLevelsCollection).doc(stockDocId);

    try {
      final docSnapshot = await stockRef.get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        // Usa el factory constructor del modelo StockLevel
        // Asegúrate que StockLevel.fromFirestore exista y funcione
        return StockLevel.fromFirestore(docSnapshot as DocumentSnapshot<Map<String, dynamic>>);
      } else {
        print("FirestoreService: No se encontró registro de stock para $stockDocId");
        // Devuelve null si no hay stock registrado
        return null;
      }
    } catch (e) {
      print("FirestoreService: Error al obtener stock para $stockDocId: $e");
      throw Exception("Error al obtener el nivel de stock.");
    }
  }
  // --- FIN MÉTODO getStockLevel ---

  // --- Métodos para Sedes ---
  Stream<List<Location>> getLocationsStream() {
    // Asegúrate que AppConstants.locationsCollection esté definido
    return _db
        .collection(AppConstants.locationsCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Location.fromFirestore(doc)) // Asegúrate que Location.fromFirestore exista
            .toList());
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
      // Asegúrate que AppConstants.locationsCollection esté definido
      await _db.collection(AppConstants.locationsCollection).add(newLocationData);
      print("FirestoreService: Sede '$name' añadida correctamente.");
    } catch (e) {
      print("FirestoreService: Error al añadir la sede '$name': $e");
      throw Exception("No se pudo guardar la nueva sede.");
    }
  }
  // --- FIN Métodos para Sedes ---

}
