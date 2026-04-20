class Tecnico {
  final int id;
  final int usuarioId;
  final int? tallerId;
  final bool disponible;
  final double? ubicacionLat;
  final double? ubicacionLng;

  Tecnico({
    required this.id,
    required this.usuarioId,
    this.tallerId,
    this.disponible = true,
    this.ubicacionLat,
    this.ubicacionLng,
  });

  factory Tecnico.fromJson(Map<String, dynamic> json) {
    return Tecnico(
      id: json['id'],
      usuarioId: json['usuario_id'],
      tallerId: json['taller_id'],
      disponible: json['disponible'] ?? true,
      ubicacionLat: json['ubicacion_lat'] != null
          ? (json['ubicacion_lat'] as num).toDouble()
          : null,
      ubicacionLng: json['ubicacion_lng'] != null
          ? (json['ubicacion_lng'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'taller_id': tallerId,
      'disponible': disponible,
      'ubicacion_lat': ubicacionLat,
      'ubicacion_lng': ubicacionLng,
    };
  }
}

class TecnicoResponse {
  final int id;
  final String nombre;
  final String? telefono;
  final bool disponible;
  final double? ubicacionLat;
  final double? ubicacionLng;
  final String? nombreTaller;

  TecnicoResponse({
    required this.id,
    required this.nombre,
    this.telefono,
    this.disponible = true,
    this.ubicacionLat,
    this.ubicacionLng,
    this.nombreTaller,
  });

  factory TecnicoResponse.fromJson(Map<String, dynamic> json) {
    return TecnicoResponse(
      id: json['id'],
      nombre: json['nombre'],
      telefono: json['telefono'],
      disponible: json['disponible'] ?? true,
      ubicacionLat: json['ubicacion_lat'] != null
          ? (json['ubicacion_lat'] as num).toDouble()
          : null,
      ubicacionLng: json['ubicacion_lng'] != null
          ? (json['ubicacion_lng'] as num).toDouble()
          : null,
      nombreTaller: json['nombre_taller'],
    );
  }
}
