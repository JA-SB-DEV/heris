import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart'; // Para la lista de items y la acción
import '../../../data/models/item.dart'; // Para el tipo Item; // Para el tipo Item

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  Item? _selectedItem; // El item seleccionado en el dropdown
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveStockEntry() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    // Validar también que se haya seleccionado un item
    if (!isValid || _selectedItem == null) {
      if (_selectedItem == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('Por favor, selecciona un item.'),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    setState(() { _isLoading = true; });

    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;

    try {
      // Llama al método addStock del provider (¡lo crearemos!)
      await Provider.of<InventoryProvider>(context, listen: false).addStock(
        itemId: _selectedItem!.id, // ID del item seleccionado
        quantityReceived: quantity,
        // TODO: Necesitamos el ID de la bodega principal aquí
        locationId: 'EBn1UKx7rLrnk3QcItZe', // ¡REEMPLAZAR ESTO!
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock añadido correctamente para ${_selectedItem!.name}.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop(); // Regresar
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al añadir stock: $error'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Obtener la lista de items del provider para el Dropdown
    // Usamos 'watch' porque si la lista de items cambia, queremos que el dropdown se actualice
    final items = context.watch<InventoryProvider>().items;

    // Estilo común (similar a otras pantallas)
    final inputDecorationTheme = InputDecoration(
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      border: UnderlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.primary, width: 2), borderRadius: BorderRadius.circular(12)),
      errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.error, width: 2), borderRadius: BorderRadius.circular(12)),
      focusedErrorBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.error, width: 2), borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      prefixIconColor: colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Registrar Entrada de Stock'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Selector de Item ---
                DropdownButtonFormField<Item>(
                  value: _selectedItem,
                  // Usar el estilo de decoración común
                  decoration: inputDecorationTheme.copyWith(
                    labelText: 'Seleccionar Item',
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                  ),
                  // Generar los items del dropdown desde la lista del provider
                  items: items.map<DropdownMenuItem<Item>>((Item item) {
                    return DropdownMenuItem<Item>(
                      value: item,
                      child: Text("${item.name} (${item.unit})"), // Mostrar nombre y unidad
                    );
                  }).toList(),
                  onChanged: !_isLoading ? (Item? newValue) {
                    setState(() {
                      _selectedItem = newValue;
                    });
                  } : null, // Deshabilitar si está cargando
                  // Validación: Asegurarse de que se seleccione un item
                  validator: (value) => value == null ? 'Selecciona un item' : null,
                  isExpanded: true, // Para que ocupe el ancho
                   // Estilo del texto seleccionado
                  selectedItemBuilder: (BuildContext context) {
                    return items.map<Widget>((Item item) {
                      return Text(
                        "${item.name} (${item.unit})",
                        overflow: TextOverflow.ellipsis, // Evitar overflow si es largo
                      );
                    }).toList();
                  },
                ),
                const SizedBox(height: 16),

                // --- Campo Cantidad Recibida ---
                TextFormField(
                  controller: _quantityController,
                  enabled: !_isLoading,
                  decoration: inputDecorationTheme.copyWith(
                    labelText: 'Cantidad Recibida',
                    prefixIcon: const Icon(Icons.add_shopping_cart_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Introduce la cantidad.';
                    final quantity = int.tryParse(value.trim());
                    if (quantity == null) return 'Introduce un número entero válido.';
                    if (quantity <= 0) return 'La cantidad debe ser mayor que cero.';
                    return null;
                  },
                  onFieldSubmitted: (_) => _isLoading ? null : _saveStockEntry(),
                ),
                const SizedBox(height: 32),

                // --- Botón Guardar Entrada ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveStockEntry,
                  style: ElevatedButton.styleFrom( // Estilo consistente
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : const Text('Guardar Entrada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
