import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// --- CORREGIR/VERIFICAR IMPORTS ---
import '../../providers/inventory_provider.dart'; // Asegúrate que este archivo exista y no tenga errores
import '../../providers/location_provider.dart';
import '../../../data/models/item.dart'; // <-- RUTA CORREGIDA
import '../../../data/models/location.dart';
import '../../widgets/inventory/item_list_tile.dart'; // Asegúrate que este archivo exista y no tenga errores
import '../../widgets/common/loading_indicator.dart';
import 'add_edit_item_screen.dart';
import 'add_stock_screen.dart';
// ----------------------------------

class InventoryListScreen extends StatelessWidget {
  const InventoryListScreen({super.key});

  // --- Método para mostrar el diálogo ---
  void _showItemDetailsDialog(BuildContext context, Item item) { // 'context' se recibe aquí
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    final Location? mainWarehouse = locationProvider.mainWarehouse;
    if (mainWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar( /* ... error bodega ... */ );
      return;
    }
    final String locationId = mainWarehouse.id;
    final String locationName = mainWarehouse.name;

    showDialog(
      context: context, // Usar el context recibido
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Consumer<InventoryProvider>(
            builder: (context, provider, child) { // 'context' del Consumer
              if (provider.isLoadingStock) { /* ... */ }
              if (provider.errorFetchingStock != null) { /* ... */ }

              final stockLevel = provider.selectedItemStock;
              final quantity = stockLevel?.quantity ?? 0;
              final totalValue = quantity * item.price;
              final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

              return SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    // --- Pasar context al helper ---
                    _buildDetailRow(context, 'Unidad:', item.unit),
                    if (item.description != null && item.description!.isNotEmpty)
                       _buildDetailRow(context, 'Descripción:', item.description!),
                    _buildDetailRow(context, 'Precio Unitario:', currencyFormat.format(item.price)),
                    const Divider(height: 20, thickness: 0.5),
                    _buildDetailRow(context, 'Stock ($locationName):', '$quantity ${item.unit}', isBold: true),
                    _buildDetailRow(context, 'Valor Total Stock:', currencyFormat.format(totalValue), isBold: true),
                    // -------------------------------
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () { Navigator.of(dialogContext).pop(); },
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        );
      },
    );
    Future.microtask(() => inventoryProvider.fetchStockForItem(item.id, locationId));
  }

  // --- Helper actualizado para recibir context ---
  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isBold = false}) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15), // Usar context aquí
          children: <TextSpan>[
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
 }
  // --- FIN Diálogo ---


  @override
  Widget build(BuildContext context) { // 'context' se recibe aquí
    // Usar el context recibido para acceder al provider
    final isLoadingList = context.watch<InventoryProvider>().isLoadingItems;

    return Scaffold(
      appBar: AppBar( /* ... */ ),
      body: _buildBody(context, isLoadingList), // Pasar el context a _buildBody
      floatingActionButton: FloatingActionButton( /* ... */ ),
    );
  }

  // --- Actualizado para recibir context ---
  Widget _buildBody(BuildContext context, bool isLoadingList) { // Recibir context
    if (isLoadingList) {
      return const Center(child: LoadingIndicator());
    }

    return Consumer<InventoryProvider>(
      builder: (context, provider, child) { // 'context' del Consumer
        if (provider.errorMessage != null) { /* ... */ }
        if (provider.items.isEmpty) { /* ... */ }

        return ListView.builder(
          itemCount: provider.items.length,
          itemBuilder: (context, index) { // 'context' del builder
            final item = provider.items[index];
            return ItemListTile(
              item: item,
              onTap: () {
                // Pasar el context del builder al método del diálogo
                _showItemDetailsDialog(context, item);
              },
            );
          },
        );
      }
    );
  }
}
