import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Necesario si alguna pantalla usa Provider

// Importa las pantallas que irán en las pestañas
import '../inventory/inventory_list_screen.dart';
import '../transfers/transfers_screen.dart'; // Placeholder
import '../settings/settings_screen.dart'; // Placeholder con Logout

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Índice de la pestaña seleccionada actualmente

  // Lista de las pantallas principales correspondientes a cada pestaña
  static const List<Widget> _widgetOptions = <Widget>[
    InventoryListScreen(), // Índice 0
    TransfersScreen(),     // Índice 1
    SettingsScreen(),      // Índice 2
  ];

  // Método que se llama cuando se toca una pestaña
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // El cuerpo del Scaffold cambia según la pestaña seleccionada
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      // --- Barra de Navegación Inferior ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2), // Icono diferente cuando está activo
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_outlined),
            activeIcon: Icon(Icons.swap_horiz),
            label: 'Transferir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
        currentIndex: _selectedIndex, // Pestaña activa actualmente
        // --- Estilo Minimalista ---
        backgroundColor: colorScheme.surfaceContainerLowest, // Un color de fondo muy sutil
        selectedItemColor: colorScheme.primary,        // Color del ícono y texto activo
        unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.7), // Color de los inactivos
        selectedFontSize: 12, // Tamaño de fuente pequeño para el label activo
        unselectedFontSize: 12, // Tamaño de fuente pequeño para los inactivos
        type: BottomNavigationBarType.fixed, // Asegura que todos los items sean visibles
        elevation: 0, // Sin sombra para un look plano
        // showUnselectedLabels: false, // Opcional: Ocultar labels de items inactivos
        // --------------------------
        onTap: _onItemTapped, // Llama a este método al tocar una pestaña
      ),
    );
  }
}
