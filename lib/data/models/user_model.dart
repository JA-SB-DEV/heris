import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid; // Corresponderá al UID de Firebase Auth
  final String firstName;
  final String lastName;
  final String email;
  final String phone; // Con indicativo
  final String? role; // Opcional por ahora (ej: 'admin', 'manager', 'staff')
  final Timestamp createdAt; // Fecha de creación

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.role, // Valor por defecto o asignado después
    required this.createdAt,
  });

  // Método para convertir este objeto UserModel a un Map para Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': createdAt,
      // Puedes añadir 'updatedAt': FieldValue.serverTimestamp() en actualizaciones
    };
  }

  // Fábrica para crear un UserModel desde un DocumentSnapshot de Firestore
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception("Documento de usuario no encontrado o datos inválidos!");
    }
    return UserModel(
      uid: data['uid'] ?? doc.id, // Usa el ID del documento si 'uid' no está en los datos
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] as String?,
      // Asegúrate de manejar el Timestamp correctamente
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
