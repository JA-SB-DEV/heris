    // Representa un item dentro de una transferencia
    class TransferItem {
      final String itemId;
      final String itemName; // Guardar nombre para mostrar fácilmente
      final String itemUnit; // Guardar unidad
      final int quantity;

      TransferItem({
        required this.itemId,
        required this.itemName,
        required this.itemUnit,
        required this.quantity,
      });

      // Convertir a JSON (para guardar dentro del documento Transfer)
      Map<String, dynamic> toJson() {
        return {
          'itemId': itemId,
          'itemName': itemName,
          'itemUnit': itemUnit,
          'quantity': quantity,
        };
      }

      // Crear desde JSON (leído desde el documento Transfer)
      factory TransferItem.fromJson(Map<String, dynamic> json) {
        return TransferItem(
          itemId: json['itemId'] ?? '',
          itemName: json['itemName'] ?? 'Desconocido',
          itemUnit: json['itemUnit'] ?? 'N/A',
          quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        );
      }
    }
    