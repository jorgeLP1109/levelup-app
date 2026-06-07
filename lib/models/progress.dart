class Progress {
  final String id;
  final String alumno;
  final Map<String, dynamic>? clase;
  final String descripcion;
  final DateTime fecha;

  Progress({
    required this.id,
    required this.alumno,
    this.clase,
    required this.descripcion,
    required this.fecha,
  });

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
        id: json['_id'] ?? '',
        alumno: json['alumno'] is String ? json['alumno'] : json['alumno']['_id'] ?? '',
        clase: json['clase'] is Map ? json['clase'] : null,
        descripcion: json['descripcion'] ?? '',
        fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      );
}
