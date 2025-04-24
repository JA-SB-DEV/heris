import 'package:cloud_firestore/cloud_firestore.dart';

// Representa una categoría de items (ej: Carnes, Bebidas, Limpieza)
class Category {
  final String id; // ID del documento en Firestore
  final String name; // Nombre de la categoría (ej: "Vegetales")

  Category({
    required this.id,
    required this.name,
  });

  // Convertir a JSON para guardar en Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      // Podrías añadir 'createdAt', 'updatedAt' si lo necesitas
    };
    // No incluimos el ID aquí porque es la clave del documento
  }

  // Crear una instancia de Category desde un DocumentSnapshot de Firestore
  factory Category.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      // Manejar el caso donde el documento no tiene datos (poco probable si se guarda bien)
      throw Exception("Documento de categoría sin datos!");
    }
    return Category(
      id: doc.id, // Usar el ID del documento de Firestore
      name: data['name'] as String? ?? 'Sin Nombre', // Proveer valor por defecto
    );
  }

  // Sobrescribir == y hashCode si planeas comparar objetos Category
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Para facilitar la visualización en Dropdowns
  @override
  String toString() {
    return name;
  }
}
