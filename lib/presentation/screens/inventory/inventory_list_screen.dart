import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// Asegúrate que las rutas de import sean correctas
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

  // Método para mostrar el diálogo de detalles (sin cambios)
  void _showItemDetailsDialog(BuildContext context, Item item) {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final Location? mainWarehouse = locationProvider.mainWarehouse;
    if (mainWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error: Bodega Principal no configurada.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    final String locationId = mainWarehouse.id;
    final String locationName = mainWarehouse.name;

    inventoryProvider.fetchStockForItem(item.id, locationId);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            item.name,
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          contentPadding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0.0),
          content: Consumer<InventoryProvider>(
            builder: (context, provider, child) {
              if (provider.isLoadingStock) {
                return const SizedBox(height: 100, child: Center(child: LoadingIndicator()));
              }
              if (provider.errorFetchingStock != null) {
                return Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Error: ${provider.errorFetchingStock}', style: TextStyle(color: colorScheme.error))),
                  ],
                );
              }

              final stockLevel = provider.selectedItemStock;
              final quantity = stockLevel?.quantity ?? 0;
              final totalValue = quantity * item.price;
              final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '', decimalDigits: 0, customPattern: '\$ #,##0');

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildDetailRow(context, Icons.straighten_outlined, 'Unidad:', item.unit),
                  _buildDetailRow(context, Icons.sell_outlined, 'Precio Unitario:', currencyFormat.format(item.price)),
                  if (item.description != null && item.description!.isNotEmpty)
                     _buildDetailRow(context, Icons.notes_outlined, 'Descripción:', item.description!),
                  const Divider(height: 24, thickness: 0.5),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Text('Stock ($locationName):', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0, top: 4.0),
                    child: Text('$quantity', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(context, Icons.monetization_on_outlined, 'Valor Total Stock:', currencyFormat.format(totalValue), isHighlighted: true),
                   const SizedBox(height: 16),
                ],
              );
            },
          ),
          actions: <Widget>[
             TextButton(
              child: Text('Eliminar', style: TextStyle(color: colorScheme.error)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _confirmAndDeleteItem(context, item);
              },
            ),
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () { Navigator.of(dialogContext).pop(); },
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          backgroundColor: colorScheme.surface,
        );
      },
    );
  }

  // Método para confirmar y eliminar item (sin cambios)
  Future<void> _confirmAndDeleteItem(BuildContext context, Item item) async { /* ... */ }

  // Helper para construir filas de detalle (sin cambios)
  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {bool isHighlighted = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isHighlighted ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text('$label $value', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    // Leer estados necesarios del provider usando watch
    final inventoryProvider = context.watch<InventoryProvider>();
    final locationProvider = context.watch<LocationProvider>(); // Necesario para el ID/nombre de bodega
    final isLoadingList = inventoryProvider.isLoadingItems;
    final isGeneratingPdf = inventoryProvider.isGeneratingPdf; // Estado de carga del PDF

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          // --- BOTÓN GENERAR PDF ---
          // Mostrar indicador de carga si se está generando el PDF
          isGeneratingPdf
            ? const Padding(
                padding: EdgeInsets.only(right: 16.0), // Margen para alinear con otros iconos
                child: Center( // Centrar el indicador
                  child: SizedBox(
                    width: 24, // Tamaño similar al IconButton
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined), // Icono PDF
                tooltip: 'Generar Reporte PDF',
                // Deshabilitar si la lista está cargando o si ya se está generando un PDF
                onPressed: isLoadingList || isGeneratingPdf ? null : () async {
                  // Obtener bodega principal (necesario para saber de dónde es el reporte)
                  final Location? mainWarehouse = locationProvider.mainWarehouse;
                  if (mainWarehouse == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Error: Bodega Principal no configurada.'), backgroundColor: Colors.redAccent)
                    );
                    return;
                  }
                  // Llamar al método del provider para generar y mostrar
                  // Usamos listen: false porque estamos en un callback
                  // El estado isGeneratingPdf ya se maneja con watch en el build
                  await Provider.of<InventoryProvider>(context, listen: false)
                        .generateAndShowInventoryPdf(mainWarehouse.id, mainWarehouse.name);

                  // Mostrar error si ocurrió durante la generación del PDF
                  // Leemos el error directamente del provider después del await
                   final pdfError = Provider.of<InventoryProvider>(context, listen: false).pdfError;
                   if (context.mounted && pdfError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text(pdfError), backgroundColor: Colors.redAccent)
                      );
                   }
                },
              ),
          // -----------------------
          IconButton( // Botón Añadir Stock
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'Registrar Entrada Stock',
            // Deshabilitar si está cargando la lista o generando PDF
            onPressed: isLoadingList || isGeneratingPdf ? null : () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStockScreen()));
            },
          ),
          const SizedBox(width: 8), // Espacio final
        ],
      ),
      body: _buildBody(context, isLoadingList),
      floatingActionButton: FloatingActionButton(
        // Deshabilitar si está cargando la lista o generando PDF
        onPressed: isLoadingList || isGeneratingPdf ? null : () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditItemScreen()));
        },
        tooltip: 'Añadir Nuevo Item',
        child: const Icon(Icons.add),
      ),
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
            return Dismissible(
              key: Key(item.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Theme.of(context).colorScheme.errorContainer,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerRight,
                child: Icon(Icons.delete_sweep_outlined, color: Theme.of(context).colorScheme.onErrorContainer),
              ),
              confirmDismiss: (direction) async {
                 await _confirmAndDeleteItem(context, item);
                 return false;
              },
              child: ItemListTile(
                item: item,
                onTap: () {
                  _showItemDetailsDialog(context, item);
                },
              ),
            );
          },
        );
      }
    );
  }
}
