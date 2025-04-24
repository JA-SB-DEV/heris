import 'package:flutter/material.dart';
// Importar CategoryProvider y AddEditCategoryScreen cuando se creen
// import '../../providers/category_provider.dart';
// import 'add_edit_category_screen.dart';

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // TODO: Obtener lista de categorías desde CategoryProvider

    // Simulación de lista de categorías
    final List<Map<String, String>> categories = [
      {'id': 'cat1', 'name': 'Bebidas'},
      {'id': 'cat2', 'name': 'Carnes'},
      {'id': 'cat3', 'name': 'Limpieza'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Categorías'),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return ListTile(
            title: Text(category['name'] ?? 'Sin Nombre'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min, // Para que la Row ocupe solo lo necesario
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                  tooltip: 'Editar Categoría',
                  onPressed: () {
                    // TODO: Navegar a AddEditCategoryScreen pasando la categoría
                    print('Editar categoría: ${category['name']}');
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Funcionalidad Editar Categoría (Próximamente)'))
                     );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  tooltip: 'Eliminar Categoría',
                  onPressed: () {
                    // TODO: Implementar lógica de eliminación con confirmación
                    print('Eliminar categoría: ${category['name']}');
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Funcionalidad Eliminar Categoría (Próximamente)'))
                     );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nueva Categoría'),
        onPressed: () {
          // TODO: Navegar a AddEditCategoryScreen para añadir
          print('Navegar a Añadir Categoría');
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Pantalla "Añadir Categoría" (Próximamente)'))
           );
          // Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditCategoryScreen()));
        },
      ),
    );
  }
}
