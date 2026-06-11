class User {
  final String id;
  final String nombre;
  final String? cedula;
  final String email;
  final int edad;
  final double? peso;
  final double? estatura;
  final String? tipoSangre;
  final String? alergias;
  final String? medicamentos;
  final String? contactoEmergenciaNombre;
  final String? contactoEmergenciaTelefono;
  final String? fotoUrl;
  final String role;
  final bool isMinor;
  final String? representantName;
  final String? representantPhone;
  final String? representantCedula;
  final DateTime? fechaVencimiento;

  User({
    required this.id,
    required this.nombre,
    this.cedula,
    required this.email,
    required this.edad,
    this.peso,
    this.estatura,
    this.tipoSangre,
    this.alergias,
    this.medicamentos,
    this.contactoEmergenciaNombre,
    this.contactoEmergenciaTelefono,
    this.fotoUrl,
    required this.role,
    this.isMinor = false,
    this.representantName,
    this.representantPhone,
    this.representantCedula,
    this.fechaVencimiento,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['_id'] ?? '',
        nombre: json['nombre'] ?? '',
        cedula: json['cedula'],
        email: json['email'] ?? '',
        edad: json['edad'] ?? 0,
        peso: json['peso']?.toDouble(),
        estatura: json['estatura']?.toDouble(),
        tipoSangre: json['tipoSangre'],
        alergias: json['alergias'],
        medicamentos: json['medicamentos'],
        contactoEmergenciaNombre: json['contactoEmergenciaNombre'],
        contactoEmergenciaTelefono: json['contactoEmergenciaTelefono'],
        fotoUrl: json['fotoUrl'],
        role: json['role'] ?? 'client',
        isMinor: json['isMinor'] ?? false,
        representantName: json['representantName'],
        representantPhone: json['representantPhone'],
        representantCedula: json['representantCedula'],
        fechaVencimiento: json['fechaVencimiento'] != null
            ? DateTime.tryParse(json['fechaVencimiento'])
            : null,
      );

  int? get diasRestantes {
    if (fechaVencimiento == null) return null;
    return fechaVencimiento!.difference(DateTime.now()).inDays;
  }

  bool get mensualidadVencida => diasRestantes != null && diasRestantes! < 0;
  bool get mensualidadPorVencer => diasRestantes != null && diasRestantes! >= 0 && diasRestantes! <= 5;
}
