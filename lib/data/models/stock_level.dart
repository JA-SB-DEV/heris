import 'package:cloud_firestore/cloud_firestore.dart';

class StockLevel {
  final String id; // ID del documento de stock (ej: itemId_locationId)
  final String itemId;
  final String locationId; // ID de la sede/bodega
  final int quantity;
  final Timestamp lastUpdated;

  StockLevel({
    required this.id,
    required this.itemId,
    required this.locationId,
    required this.quantity,
    required this.lastUpdated,
  });

  // Método para convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'locationId': locationId,
      'quantity': quantity,
      'lastUpdated': lastUpdated,
      // No incluimos el 'id' porque es la clave del documento
    };
  }

  // Fábrica para crear desde Firestore (si necesitas leerlo)
  factory StockLevel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return StockLevel(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      locationId: data['locationId'] ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      lastUpdated: data['lastUpdated'] ?? Timestamp.now(),
    );
  }
}
