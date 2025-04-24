// lib/data/models/item.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para Timestamp si lo usas

class Item {
  final String id;
  final String name;
  final String unit;
  final String? description;
  final double price;
  // --- NUEVO: Campo para búsqueda insensible a mayúsculas ---
  final String nameLowercase;
  // -------------------------------------------------------

  Item({
    required this.id,
    required this.name,
    required this.unit,
    this.description,
    required this.price,
  }) : nameLowercase = name.toLowerCase(); // Inicializar aquí

  // Fábrica para crear un Item desde un Map de Firestore
  factory Item.fromJson(Map<String, dynamic> json, String id) {
    final name = json['name'] as String? ?? 'Sin Nombre';
    return Item(
      id: id,
      name: name,
      unit: json['unit'] as String? ?? 'N/A',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      // nameLowercase se calcula en el constructor, no se lee directamente
      // a menos que también lo guardes y quieras leerlo.
    );
  }

  // Método para convertir un Item a un Map para Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit': unit,
      'description': description,
      'price': price,
      'nameLowercase': nameLowercase, // <-- Añadir campo en minúsculas
      // Considera añadir 'createdAt' si no lo tienes
      // 'createdAt': FieldValue.serverTimestamp(), // O Timestamp.now() si lo estableces al crear
    };
  }
}
