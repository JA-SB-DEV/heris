    import 'package:cloud_firestore/cloud_firestore.dart';
    import 'transfer_item.dart'; // Importa el modelo de item de transferencia

    enum TransferStatus { pending, shipped, received, cancelled } // Posibles estados

    class Transfer {
      final String id; // ID del documento de transferencia
      final String originLocationId;
      final String originLocationName; // Guardar nombre para mostrar
      final String destinationLocationId;
      final String destinationLocationName; // Guardar nombre para mostrar
      final Timestamp createdAt;
      final String createdByUserId; // Quién la creó (UID de Auth)
      final TransferStatus status;
      final List<TransferItem> items; // Lista de items transferidos

      Transfer({
        required this.id,
        required this.originLocationId,
        required this.originLocationName,
        required this.destinationLocationId,
        required this.destinationLocationName,
        required this.createdAt,
        required this.createdByUserId,
        required this.status,
        required this.items,
      });

      // Convertir a JSON
      Map<String, dynamic> toJson() {
        return {
          'originLocationId': originLocationId,
          'originLocationName': originLocationName,
          'destinationLocationId': destinationLocationId,
          'destinationLocationName': destinationLocationName,
          'createdAt': createdAt,
          'createdByUserId': createdByUserId,
          'status': status.name, // Guardar el nombre del enum ('pending', 'shipped', etc.)
          // Convertir la lista de TransferItem a una lista de Mapas JSON
          'items': items.map((item) => item.toJson()).toList(),
        };
      }

      // Crear desde Firestore
      factory Transfer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
        final data = doc.data()!;
        // Convertir la lista de mapas JSON de items a una lista de TransferItem
        final itemsList = (data['items'] as List<dynamic>? ?? [])
            .map((itemData) => TransferItem.fromJson(itemData as Map<String, dynamic>))
            .toList();
        // Convertir el string del estado al enum TransferStatus
        final statusString = data['status'] as String? ?? 'pending';
        final status = TransferStatus.values.firstWhere(
                (e) => e.name == statusString,
                orElse: () => TransferStatus.pending // Valor por defecto si no coincide
        );

        return Transfer(
          id: doc.id,
          originLocationId: data['originLocationId'] ?? '',
          originLocationName: data['originLocationName'] ?? 'Origen Desconocido',
          destinationLocationId: data['destinationLocationId'] ?? '',
          destinationLocationName: data['destinationLocationName'] ?? 'Destino Desconocido',
          createdAt: data['createdAt'] ?? Timestamp.now(),
          createdByUserId: data['createdByUserId'] ?? '',
          status: status,
          items: itemsList,
        );
      }
    }
    