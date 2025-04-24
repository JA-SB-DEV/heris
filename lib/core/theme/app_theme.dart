import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de Colores Sugerida (Puedes ajustarla)
  static const Color primaryColor = Color(0xFF00695C); // Un verde azulado oscuro (elegante)
  static const Color primaryContainer = Color(0xFFB2DFDB); // Un verde azulado muy claro
  static const Color secondaryColor = Color(0xFFFFA000); // Un ámbar/dorado como acento
  static const Color surfaceColor = Color(0xFFFFFFFF); // Fondo principal blanco
  static const Color backgroundColor = Color(0xFFF5F5F5); // Fondo ligeramente gris para contraste
  static const Color surfaceVariant = Color(0xFFE0E0E0); // Para fondos sutiles de campos/cards
  static const Color onPrimaryColor = Colors.white;
  static const Color onSecondaryColor = Colors.black;
  static const Color onSurfaceColor = Colors.black87; // Texto principal
  static const Color onSurfaceVariantColor = Colors.black54; // Texto secundario/iconos
  static const Color errorColor = Color(0xFFB00020);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true, // Habilitar Material 3 para estilos más modernos
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: onPrimaryColor,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFF00201D), // Texto/iconos sobre primaryContainer
      secondary: secondaryColor,
      onSecondary: onSecondaryColor,
      secondaryContainer: Color(0xFFFFECB3), // Ámbar claro
      onSecondaryContainer: Color(0xFF261A00),
      tertiary: primaryColor, // Puedes definir un color terciario si lo necesitas
      onTertiary: onPrimaryColor,
      tertiaryContainer: primaryContainer,
      onTertiaryContainer: Color(0xFF00201D),
      error: errorColor,
      onError: Colors.white,
      errorContainer: Color(0xFFFCD8DF),
      onErrorContainer: Color(0xFF3E0510),
      surface: surfaceColor, // Fondo principal de Scaffolds, Dialogs
      onSurface: onSurfaceColor, // Color de texto principal sobre surface
      surfaceVariant: surfaceVariant, // Usado para fondos de Cards, Chip, etc.
      onSurfaceVariant: onSurfaceVariantColor, // Texto/iconos sobre surfaceVariant
      outline: Colors.black26, // Bordes sutiles
      outlineVariant: Colors.black12,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: Color(0xFF2F3030),
      onInverseSurface: Color(0xFFF0F1F1),
      inversePrimary: Color(0xFF4FD8C4),
      surfaceTint: primaryColor, // Tinte aplicado a superficies elevadas
    ),
    // Definir fuentes si quieres una específica (ej: GoogleFonts.lato())
    // fontFamily: GoogleFonts.lato().fontFamily,

    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor, // AppBar blanco
      foregroundColor: onSurfaceColor, // Iconos y texto oscuros en AppBar
      elevation: 0.5, // Sombra muy sutil o 0 para plano
      centerTitle: true,
      titleTextStyle: TextStyle(
        // fontFamily: GoogleFonts.montserrat().fontFamily, // Fuente diferente para títulos
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurfaceColor,
      ),
    ),

    // Estilo para la barra de navegación inferior
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white, // Fondo blanco
      selectedItemColor: primaryColor, // Color del ítem activo
      unselectedItemColor: onSurfaceVariantColor.withOpacity(0.7), // Color de ítems inactivos
      selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      type: BottomNavigationBarType.fixed,
      elevation: 1.0, // Sombra sutil
    ),

    // Estilo para botones flotantes
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: secondaryColor, // Usar color de acento
      foregroundColor: onSecondaryColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),

    // Estilo para Cards
    cardTheme: CardTheme(
      elevation: 1.0, // Sombra sutil
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Bordes más redondeados
        side: BorderSide(color: Colors.grey.shade300, width: 0.5), // Borde muy sutil
      ),
      color: surfaceColor, // Fondo blanco para cards
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    ),

     // Estilo para TextFormFields (usado en Login/SignUp/Add)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100.withOpacity(0.5), // Fondo muy claro
      border: OutlineInputBorder( // Borde general
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder( // Borde cuando está habilitado
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder( // Borde cuando está enfocado
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder( // Borde en error
         borderRadius: BorderRadius.circular(12),
         borderSide: const BorderSide(color: errorColor, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder( // Borde en error y enfocado
         borderRadius: BorderRadius.circular(12),
         borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      prefixIconColor: onSurfaceVariantColor,
      labelStyle: TextStyle(color: onSurfaceVariantColor.withOpacity(0.8)),
      hintStyle: TextStyle(color: onSurfaceVariantColor.withOpacity(0.6)),
    ),

    // Estilo para botones elevados
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 2,
      ),
    ),

    // Estilo para botones de texto
    textButtonTheme: TextButtonThemeData(
       style: TextButton.styleFrom(
         foregroundColor: primaryColor, // Color del texto
         textStyle: const TextStyle(fontWeight: FontWeight.w600),
       )
    ),

    // Otros ajustes del tema...
    scaffoldBackgroundColor: backgroundColor, // Fondo general de la app
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
