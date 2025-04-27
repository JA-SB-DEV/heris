import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid; // Corresponderá al UID de Firebase Auth
  final String firstName;
  final String lastName;
  final String email;
  final String phone; // Con indicativo
  final String? role; // ej: 'superAdmin', 'sedeAdmin', 'staff'
  // --- NUEVOS CAMPOS (Nullables) ---
  final String? assignedLocationId;   // ID de la sede asignada (si aplica)
  final String? assignedLocationName; // Nombre de la sede asignada (si aplica)
  // ---------------------------------
  final Timestamp createdAt; // Fecha de creación

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.role,
    this.assignedLocationId,      // Añadir al constructor
    this.assignedLocationName,    // Añadir al constructor
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
      'assignedLocationId': assignedLocationId,      // <-- Añadir al JSON
      'assignedLocationName': assignedLocationName,    // <-- Añadir al JSON
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
      uid: data['uid'] ?? doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] as String?,
      assignedLocationId: data['assignedLocationId'] as String?, // <-- Leer del JSON
      assignedLocationName: data['assignedLocationName'] as String?, // <-- Leer del JSON
      createdAt: data['createdAt'] ?? Timestamp.now(), // Manejar Timestamp
    );
  }
}
