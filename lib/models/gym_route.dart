class GymRoute {
  final String id;
  final String driverName;
  final double lat;
  final double lng;
  final String status;

  GymRoute({
    required this.id,
    required this.driverName,
    required this.lat,
    required this.lng,
    required this.status,
  });

  factory GymRoute.fromJson(Map<String, dynamic> json) => GymRoute(
        id: json['_id'] ?? json['id'] ?? '',
        driverName: json['driverName'] ?? '',
        lat: (json['lat'] ?? 0).toDouble(),
        lng: (json['lng'] ?? 0).toDouble(),
        status: json['status'] ?? 'inactive',
      );
}
