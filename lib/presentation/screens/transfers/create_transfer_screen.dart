    import 'package:flutter/material.dart';
    import 'package:flutter/services.dart';
    import 'package:provider/provider.dart';
    import '../../../data/models/item.dart';
    import '../../../data/models/location.dart';
    import '../../../data/models/transfer_item.dart';
    // --- ASEGÚRATE QUE ESTE IMPORT ESTÉ Y SEA CORRECTO ---
    import '../../providers/inventory_provider.dart'; // Importar InventoryProvider
    // ----------------------------------------------------
    import '../../widgets/common/loading_indicator.dart'; // Asegúrate que este import sea correcto
    // import '../../providers/location_provider.dart'; // Comentado porque usamos lista simulada

    class CreateTransferScreen extends StatefulWidget {
      const CreateTransferScreen({super.key});

      @override
      State<CreateTransferScreen> createState() => _CreateTransferScreenState();
    }

    class _CreateTransferScreenState extends State<CreateTransferScreen> {
      final _formKey = GlobalKey<FormState>();

      Location? _selectedDestination;
      final List<TransferItem> _transferItems = [];
      bool _isSaving = false; // Renombrado de _isLoading

      // --- Origen y Destinos Simulados (Volvimos al estado anterior) ---
      final String _originLocationId = 'bodega_principal_id'; // ¡REEMPLAZAR LUEGO!
      final String _originLocationName = 'Bodega Principal';

      final List<Location> _availableLocations = [ // ¡DEBE VENIR DE LocationProvider LUEGO!
        Location(id: 'sede_centro_id', name: 'Sede Centro'),
        Location(id: 'sede_norte_id', name: 'Sede Norte'),
      ];
      // ----------------------------------------------------------------

      void _addItemToTransfer() { // Ya no necesita originLocationId aquí directamente
        showDialog(
          context: context,
          builder: (_) => _AddItemDialog(
            // originLocationId: _originLocationId, // Ya no se pasa si no se usa para fetch
            onAddItem: (transferItem) {
              setState(() {
                final existingIndex = _transferItems.indexWhere((i) => i.itemId == transferItem.itemId);
                if (existingIndex >= 0) {
                   _transferItems[existingIndex] = TransferItem(
                       itemId: transferItem.itemId,
                       itemName: transferItem.itemName,
                       itemUnit: transferItem.itemUnit,
                       quantity: _transferItems[existingIndex].quantity + transferItem.quantity
                   );
                   print("Item ya en la lista, cantidad actualizada.");
                } else {
                  _transferItems.add(transferItem);
                }
              });
            },
          ),
        );
      }

      Future<void> _saveTransfer() async { // Ya no necesita recibir originLocation
        if (_selectedDestination == null) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una sede de destino.'), backgroundColor: Colors.orangeAccent));
           return;
        }
        if (_transferItems.isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Añade al menos un item a la transferencia.'), backgroundColor: Colors.orangeAccent));
           return;
        }

        setState(() { _isSaving = true; });

        try {
          // TODO: Llamar al método del TransferProvider para crear la transferencia
          print('Guardando Transferencia...');
          print('Origen: $_originLocationName ($_originLocationId)'); // Usar datos simulados/fijos por ahora
          print('Destino: ${_selectedDestination!.name} (${_selectedDestination!.id})');
          print('Items:');
          for (var item in _transferItems) { print('- ${item.itemName}: ${item.quantity} ${item.itemUnit}'); }
          await Future.delayed(const Duration(seconds: 2)); // Simulación

           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transferencia creada (simulación).'), backgroundColor: Colors.green));
             Navigator.of(context).pop();
           }

        } catch (error) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear transferencia: $error'), backgroundColor: Colors.redAccent));
           }
        } finally {
           if (mounted) {
             setState(() { _isSaving = false; });
           }
        }
      }


      @override
      Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        // --- Ya no obtenemos datos de LocationProvider aquí ---

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: const Text('Crear Transferencia'),
            elevation: 0.5,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mostrar Origen Fijo
                   InputDecorator(
                     decoration: const InputDecoration(
                       labelText: 'Desde (Origen)',
                       prefixIcon: Icon(Icons.warehouse_outlined),
                       border: InputBorder.none,
                     ),
                     child: Text(
                       _originLocationName, // Usar nombre fijo
                       style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                     ),
                  ),
                  const SizedBox(height: 16),

                  // --- Selector Sede Destino (usa lista simulada) ---
                  DropdownButtonFormField<Location>(
                    value: _selectedDestination,
                    decoration: const InputDecoration(
                      labelText: 'Enviar a (Destino)',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    items: _availableLocations.map<DropdownMenuItem<Location>>((Location loc) {
                      return DropdownMenuItem<Location>(
                        value: loc,
                        child: Text(loc.name),
                      );
                    }).toList(),
                    onChanged: !_isSaving ? (Location? newValue) {
                      setState(() {
                        _selectedDestination = newValue;
                      });
                    } : null,
                    validator: (value) => value == null ? 'Selecciona un destino' : null,
                    isExpanded: true,
                  ),
                  const SizedBox(height: 24),

                  // --- Lista de Items a Transferir ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Items a Enviar', style: theme.textTheme.titleMedium),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
                        tooltip: 'Añadir Item',
                        onPressed: !_isSaving ? _addItemToTransfer : null, // Llama al método sin ID de origen
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: _transferItems.isEmpty
                        ? Center(child: Text('Añade items a la transferencia', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)))
                        : ListView.builder(
                            itemCount: _transferItems.length,
                            itemBuilder: (context, index) {
                              final item = _transferItems[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(item.itemName.isNotEmpty ? item.itemName[0] : '?'),
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                ),
                                title: Text(item.itemName),
                                subtitle: Text('Cantidad: ${item.quantity} ${item.itemUnit}'),
                                trailing: IconButton(
                                  icon: Icon(Icons.remove_circle_outline, color: colorScheme.error.withOpacity(0.8)),
                                  tooltip: 'Quitar Item',
                                  onPressed: !_isSaving ? () {
                                    setState(() {
                                      _transferItems.removeAt(index);
                                    });
                                  } : null,
                                ),
                                dense: true,
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),

                  // --- Botón Guardar Transferencia ---
                  ElevatedButton(
                    onPressed: (_isSaving || _transferItems.isEmpty || _selectedDestination == null)
                                ? null
                                : _saveTransfer, // Llama al método sin pasar origen
                    style: theme.elevatedButtonTheme.style,
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Confirmar Envío', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }


    // --- Diálogo _AddItemDialog (Simplificado - Sin fetchStock) ---
    class _AddItemDialog extends StatefulWidget {
      final Function(TransferItem) onAddItem;
      // final String originLocationId; // Ya no necesita recibir ID de origen

      const _AddItemDialog({
        required this.onAddItem,
        // required this.originLocationId,
      });

      @override
      State<_AddItemDialog> createState() => _AddItemDialogState();
    }

    class _AddItemDialogState extends State<_AddItemDialog> {
      final _dialogFormKey = GlobalKey<FormState>();
      final _quantityController = TextEditingController();
      Item? _selectedItem;
      // --- ESTADO DE STOCK ELIMINADO ---

      @override
      void dispose() {
        _quantityController.dispose();
        super.dispose();
      }

      // --- MÉTODO fetchItemStock ELIMINADO ---

      void _confirmAddItem() {
        if (_dialogFormKey.currentState?.validate() ?? false) {
          if (_selectedItem != null) {
            final quantity = int.parse(_quantityController.text.trim());
            widget.onAddItem(TransferItem(
              itemId: _selectedItem!.id,
              itemName: _selectedItem!.name,
              itemUnit: _selectedItem!.unit,
              quantity: quantity,
            ));
            Navigator.of(context).pop();
          }
        }
      }


      @override
      Widget build(BuildContext context) {
        final theme = Theme.of(context);
        // --- Obtener items desde InventoryProvider (Ahora debería encontrarlo) ---
        final availableItems = context.watch<InventoryProvider>().items;
        // --------------------------------------------------------------------

        return AlertDialog(
          title: const Text('Añadir Item a Transferencia'),
          content: Form(
            key: _dialogFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<Item>(
                    value: _selectedItem,
                    decoration: const InputDecoration(labelText: 'Seleccionar Item'),
                    items: availableItems.map<DropdownMenuItem<Item>>((Item item) {
                      return DropdownMenuItem<Item>(value: item, child: Text("${item.name} (${item.unit})"));
                    }).toList(),
                    onChanged: (Item? newValue) {
                      setState(() { _selectedItem = newValue; });
                      // Ya no llama a _fetchItemStock
                    },
                    validator: (value) => value == null ? 'Selecciona un item' : null,
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),

                  // --- WIDGET DE STOCK DISPONIBLE ELIMINADO ---

                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Cantidad a Enviar', prefixIcon: Icon(Icons.production_quantity_limits)),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Introduce cantidad.';
                      final quantity = int.tryParse(value.trim());
                      if (quantity == null) return 'Número inválido.';
                      if (quantity <= 0) return 'Cantidad debe ser > 0.';
                      // Ya no podemos validar contra stock disponible aquí
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            // Ya no deshabilita por _isLoadingStock
            ElevatedButton(onPressed: _confirmAddItem, child: const Text('Añadir')),
          ],
        );
      }
    }
    