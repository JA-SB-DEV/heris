import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para formateadores de entrada
import 'package:provider/provider.dart';
// --- ASEGÚRATE QUE ESTA LÍNEA ESTÉ Y LA RUTA SEA CORRECTA ---
import '../../providers/inventory_provider.dart'; // Importa tu provider
// ----------------------------------------------------------
// import 'package:heris/presentation/providers/location_provider.dart'; // Import innecesario aquí

class AddEditItemScreen extends StatefulWidget {
  // Podríamos añadir un 'Item? item' aquí en el futuro para editar
  const AddEditItemScreen({super.key});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _initialStockController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() { _isLoading = true; });

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final initialStock = int.tryParse(_initialStockController.text.trim()) ?? 0;

    try {
      // Ahora debería encontrar InventoryProvider gracias al import
      await Provider.of<InventoryProvider>(context, listen: false).addItem(
        name: _nameController.text.trim(),
        unit: _unitController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: price,
        initialStock: initialStock,
      );

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar( // Quitado el const si usas shape
            content: Text('Item añadido correctamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop(); // Regresar a la lista
      }
    } catch (error) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('Error al añadir item: $error'),
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
    // Ya no necesitamos inputDecorationTheme aquí, se aplica desde AppTheme

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Añadir Nuevo Item'),
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
                // --- Campo Nombre ---
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration( // Usar InputDecoration directamente
                    labelText: 'Nombre del Item',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Por favor, introduce un nombre.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Campo Unidad ---
                TextFormField(
                  controller: _unitController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration( // Usar InputDecoration directamente
                    labelText: 'Unidad de Medida',
                    hintText: 'Kg, Lt, Unidades...',
                    prefixIcon: Icon(Icons.straighten_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Por favor, introduce la unidad.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Campo Precio ---
                TextFormField(
                  controller: _priceController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration( // Usar InputDecoration directamente
                    labelText: 'Precio Unitario',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Introduce el precio.';
                    if (double.tryParse(value.trim()) == null) return 'Introduce un número válido.';
                    if (double.parse(value.trim()) < 0) return 'El precio no puede ser negativo.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Campo Stock Inicial ---
                TextFormField(
                  controller: _initialStockController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration( // Usar InputDecoration directamente
                    labelText: 'Stock Inicial (Bodega Principal)',
                    prefixIcon: Icon(Icons.inventory_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Introduce el stock inicial.';
                    if (int.tryParse(value.trim()) == null) return 'Introduce un número entero válido.';
                     if (int.parse(value.trim()) < 0) return 'El stock no puede ser negativo.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Campo Descripción (Opcional) ---
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration( // Usar InputDecoration directamente
                    labelText: 'Descripción (Opcional)',
                     prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),

                // --- Botón Guardar ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveForm,
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
                      : const Text('Guardar Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
