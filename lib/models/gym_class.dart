class Horario {
  final String dia;
  final String horaInicio;
  final String horaFin;

  Horario({required this.dia, required this.horaInicio, required this.horaFin});

  factory Horario.fromJson(Map<String, dynamic> json) => Horario(
        dia: json['dia'] ?? '',
        horaInicio: json['horaInicio'] ?? '',
        horaFin: json['horaFin'] ?? '',
      );
}

class GymClass {
  final String id;
  final String nombre;
  final String profesor;
  final int diasPorSemana;
  final List<Horario> horarios;
  final double precio;
  final List<dynamic> inscritos;
  final bool activa;

  GymClass({
    required this.id,
    required this.nombre,
    required this.profesor,
    required this.diasPorSemana,
    required this.horarios,
    required this.precio,
    required this.inscritos,
    required this.activa,
  });

  factory GymClass.fromJson(Map<String, dynamic> json) => GymClass(
        id: json['_id'] ?? '',
        nombre: json['nombre'] ?? '',
        profesor: json['profesor'] ?? '',
        diasPorSemana: json['diasPorSemana'] ?? 1,
        horarios: (json['horarios'] as List?)
                ?.map((h) => Horario.fromJson(h))
                .toList() ??
            [],
        precio: (json['precio'] ?? 0).toDouble(),
        inscritos: json['inscritos'] ?? [],
        activa: json['activa'] ?? true,
      );
}
