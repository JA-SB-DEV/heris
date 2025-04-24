// lib/core/constants/app_constants.dart

class AppConstants {
  // Nombres de Colecciones en Firestore
  static const String itemsCollection = 'items'; // Colección para materia prima
  static const String locationsCollection = 'locations'; // Colección para sedes/bodegas
  static const String stockLevelsCollection = 'stockLevels'; // Colección para niveles de stock (itemId_locationId)
  static const String transfersCollection = 'transfers'; // Colección para transferencias
  static const String usersCollection = 'users'; // Colección para datos adicionales de usuarios
  static const String itemCategoriesCollection = 'itemCategories'; // Colección para categorías de items

  // Textos comunes (ejemplos)
  static const String appName = 'Heris App';
  // Puedes añadir más constantes aquí (ej: roles de usuario, estados de transferencia)
  static const String roleSuperAdmin = 'superAdmin';
  static const String roleSedeAdmin = 'sedeAdmin';
  static const String roleStaff = 'staff';
}
