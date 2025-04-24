import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/location_provider.dart';
import '../../../data/models/item.dart';
import '../../../data/models/location.dart';
import '../../widgets/inventory/item_list_tile.dart';
import '../../widgets/common/loading_indicator.dart';
import 'add_edit_item_screen.dart';
import 'add_stock_screen.dart';

class InventoryListScreen extends StatelessWidget {
  const InventoryListScreen({super.key});

  // --- Método para mostrar el diálogo ---
  void _showItemDetailsDialog(BuildContext context, Item item) {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    final Location? mainWarehouse = locationProvider.mainWarehouse;
    if (mainWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Bodega Principal no configurada.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    final String locationId = mainWarehouse.id;
    final String locationName = mainWarehouse.name;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Consumer<InventoryProvider>(
            builder: (context, provider, child) {
              if (provider.isLoadingStock) {
                return const SizedBox(height: 60, child: Center(child: LoadingIndicator()));
              }
              if (provider.errorFetchingStock != null) {
                return Text('Error: ${provider.errorFetchingStock}', style: const TextStyle(color: Colors.red));
              }

              final stockLevel = provider.selectedItemStock;
              final quantity = stockLevel?.quantity ?? 0;
              final totalValue = quantity * item.price;
              final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

              return SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    _buildDetailRow(context, 'Unidad:', item.unit),
                    if (item.description != null && item.description!.isNotEmpty)
                       _buildDetailRow(context, 'Descripción:', item.description!),
                    _buildDetailRow(context, 'Precio Unitario:', currencyFormat.format(item.price)),
                    const Divider(height: 20, thickness: 0.5),
                    _buildDetailRow(context, 'Stock ($locationName):', '$quantity ${item.unit}', isBold: true),
                    _buildDetailRow(context, 'Valor Total Stock:', currencyFormat.format(totalValue), isBold: true),
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

  // Helper para construir filas de detalle
  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isBold = false}) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 15),
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
  Widget build(BuildContext context) {
    final isLoadingList = context.watch<InventoryProvider>().isLoadingItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'Registrar Entrada Stock',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddStockScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, isLoadingList),

      // --- VERIFICAR ESTE BLOQUE ---
      floatingActionButton: FloatingActionButton(
        // Asegúrate que onPressed esté definido
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditItemScreen()),
          );
        },
        tooltip: 'Añadir Nuevo Item',
        child: const Icon(Icons.add),
      ),
      // ---------------------------
    );
  }

  Widget _buildBody(BuildContext context, bool isLoadingList) {
    if (isLoadingList) {
      return const Center(child: LoadingIndicator());
    }

    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        if (provider.errorMessage != null) {
          return Center(
             child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${provider.errorMessage}', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ),
          );
        }
        if (provider.items.isEmpty) {
          return const Center(child: Text('No hay items en el inventario.'));
        }

        return ListView.builder(
          itemCount: provider.items.length,
          itemBuilder: (context, index) {
            final item = provider.items[index];
            return ItemListTile(
              item: item,
              onTap: () {
                _showItemDetailsDialog(context, item); // Llamar al diálogo
              },
            );
          },
        );
      }
    );
  }
}
