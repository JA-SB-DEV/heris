    import 'package:cloud_firestore/cloud_firestore.dart';

    class Location {
      final String id; // ID del documento en Firestore
      final String name;
      final String? address; // Dirección opcional
      final bool isMainWarehouse; // Para identificar la bodega principal

      Location({
        required this.id,
        required this.name,
        this.address,
        this.isMainWarehouse = false, // Por defecto no es la principal
      });

      // Convertir a JSON
      Map<String, dynamic> toJson() {
        return {
          'name': name,
          'address': address,
          'isMainWarehouse': isMainWarehouse,
          // No incluimos ID aquí
        };
      }

      // Crear desde Firestore
      factory Location.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
        final data = doc.data()!;
        return Location(
          id: doc.id,
          name: data['name'] ?? 'Sin Nombre',
          address: data['address'] as String?,
          isMainWarehouse: data['isMainWarehouse'] ?? false,
        );
      }
    }
    