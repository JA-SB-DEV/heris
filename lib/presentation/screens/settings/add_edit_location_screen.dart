import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// --- ASEGÚRATE QUE ESTA LÍNEA ESTÉ DESCOMENTADA Y LA RUTA SEA CORRECTA ---
import '../../providers/location_provider.dart'; // Importar LocationProvider
// -----------------------------------------------------------------------
// Importar el modelo si lo necesitas directamente (aunque no parece necesario aquí)
// import '../../../data/models/location.dart';


class AddEditLocationScreen extends StatefulWidget {
  // Podríamos pasar un Location? para editar en el futuro
  const AddEditLocationScreen({super.key});

  @override
  State<AddEditLocationScreen> createState() => _AddEditLocationScreenState();
}

class _AddEditLocationScreenState extends State<AddEditLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isMainWarehouse = false; // Estado local para el interruptor
  // bool _isLoading = false; // Ya no usamos estado de carga local

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- MÉTODO _saveLocation ACTUALIZADO ---
  Future<void> _saveLocation() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // No guardar si el formulario no es válido
    }

    // El estado de carga (_isSaving) ahora se maneja en LocationProvider
    // setState(() { _isLoading = true; }); // QUITAR

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    // Obtener el provider (listen: false porque estamos en un callback, no necesitamos reconstruir aquí)
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    try {
      // Llamar al método addLocation del LocationProvider
      await locationProvider.addLocation(
        name: name,
        address: address.isEmpty ? null : address, // Pasar null si está vacío
        isMainWarehouse: _isMainWarehouse,
      );

      // Si la operación fue exitosa (no lanzó excepción)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('Sede guardada correctamente.'), // Mensaje de éxito
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop(); // Volver a la pantalla anterior
      }
    } catch (error) {
      // Si el provider lanzó una excepción (ej: ya existe bodega principal)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Mostrar el mensaje de error que viene del provider
            content: Text('Error al guardar sede: $error'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
    // El estado de carga (isSaving) se actualiza automáticamente por el provider
    // y el widget se reconstruirá gracias a context.watch() en el build.
    // No necesitamos finally aquí para setState.
  }
  // --- FIN MÉTODO _saveLocation ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // --- Leer estado de guardado del Provider con watch ---
    // Usamos 'watch' aquí para que la UI se reconstruya cuando 'isSaving' cambie
    final isSaving = context.watch<LocationProvider>().isSaving;
    // -----------------------------------------------------
    // Ya no necesitamos obtener inputDecoration explícitamente

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Añadir Nueva Sede'), // O 'Editar Sede'
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // Usar ListView para evitar overflow si hay más campos
            children: [
              // --- Campo Nombre de la Sede ---
              TextFormField(
                controller: _nameController,
                enabled: !isSaving, // Usar estado del provider
                decoration: const InputDecoration( // Usar InputDecoration directamente
                  labelText: 'Nombre de la Sede/Bodega',
                  prefixIcon: Icon(Icons.store_mall_directory_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduce el nombre de la sede.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Campo Dirección (Opcional) ---
              TextFormField(
                controller: _addressController,
                enabled: !isSaving, // Usar estado del provider
                decoration: const InputDecoration( // Usar InputDecoration directamente
                  labelText: 'Dirección (Opcional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // --- Interruptor Bodega Principal ---
              SwitchListTile(
                title: const Text('¿Es la Bodega Principal?'),
                subtitle: const Text('Marca esta opción si esta es tu bodega central de inventario.'),
                value: _isMainWarehouse,
                onChanged: isSaving ? null : (bool value) { // Usar estado del provider
                  setState(() {
                    _isMainWarehouse = value;
                  });
                },
                secondary: Icon(
                  Icons.warehouse_outlined,
                  color: _isMainWarehouse ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
                activeColor: colorScheme.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
              ),
              const SizedBox(height: 32),

              // --- Botón Guardar ---
              ElevatedButton(
                // Usar estado de guardado del provider para habilitar/deshabilitar
                onPressed: isSaving ? null : _saveLocation,
                style: theme.elevatedButtonTheme.style?.copyWith(
                   minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50)),
                ),
                // Mostrar indicador si está guardando (leyendo del provider)
                 child: isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Row( // Usar Row para icono y texto
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save_alt_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Guardar Sede', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
