class User {
  final String id;
  final String nombre;
  final String? cedula;
  final String email;
  final int edad;
  final double? peso;
  final String role;
  final bool isMinor;
  final String? representantName;
  final String? representantPhone;
  final String? representantCedula;

  User({
    required this.id,
    required this.nombre,
    this.cedula,
    required this.email,
    required this.edad,
    this.peso,
    required this.role,
    this.isMinor = false,
    this.representantName,
    this.representantPhone,
    this.representantCedula,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['_id'] ?? '',
        nombre: json['nombre'] ?? '',
        cedula: json['cedula'],
        email: json['email'] ?? '',
        edad: json['edad'] ?? 0,
        peso: json['peso']?.toDouble(),
        role: json['role'] ?? 'client',
        isMinor: json['isMinor'] ?? false,
        representantName: json['representantName'],
        representantPhone: json['representantPhone'],
        representantCedula: json['representantCedula'],
      );
}
