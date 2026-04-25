class InfoTecnico {
  final int id;
  final bool disponible;
  final String? nombreTaller;
  final int? tallerId;
  final UsuarioInfo? usuario;

  InfoTecnico({
    required this.id,
    required this.disponible,
    this.nombreTaller,
    this.tallerId,
    this.usuario,
  });

  factory InfoTecnico.fromJson(Map<String, dynamic> json) {
    final tecnico = json['tecnico'] ?? json;
    return InfoTecnico(
      id: tecnico['id'] ?? 0,
      disponible: tecnico['disponible'] ?? true,
      nombreTaller: tecnico['nombre_taller'],
      tallerId: tecnico['taller_id'],
      usuario: tecnico['usuario'] != null
          ? UsuarioInfo.fromJson(tecnico['usuario'])
          : null,
    );
  }
}

class UsuarioInfo {
  final int id;
  final String nombre;
  final String? email;
  final String? telefono;
  final String? username;

  UsuarioInfo({
    required this.id,
    required this.nombre,
    this.email,
    this.telefono,
    this.username,
  });

  factory UsuarioInfo.fromJson(Map<String, dynamic> json) {
    return UsuarioInfo(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      email: json['email'],
      telefono: json['telefono'],
      username: json['username'],
    );
  }
}

class ClienteInfo {
  final int id;
  final String nombre;
  final String? telefono;

  ClienteInfo({
    required this.id,
    required this.nombre,
    this.telefono,
  });

  factory ClienteInfo.fromJson(Map<String, dynamic> json) {
    return ClienteInfo(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Cliente',
      telefono: json['telefono'],
    );
  }
}

class VehiculoInfo {
  final int id;
  final String? marca;
  final String? modelo;
  final String? patente;
  final int? anio;

  VehiculoInfo({
    required this.id,
    this.marca,
    this.modelo,
    this.patente,
    this.anio,
  });

  factory VehiculoInfo.fromJson(Map<String, dynamic> json) {
    return VehiculoInfo(
      id: json['id'] ?? 0,
      marca: json['marca'],
      modelo: json['modelo'],
      patente: json['patente'],
      anio: json['anio'],
    );
  }
}

class IncidenteTecnico {
  final int id;
  final String estado;
  final String? prioridad;
  final String? descripcion;
  final String? descripcionIa;
  final double? ubicacionLat;
  final double? ubicacionLng;
  final String? direccion;
  final DateTime? fechaCreacion;
  final ClienteInfo? cliente;
  final VehiculoInfo? vehiculo;

  IncidenteTecnico({
    required this.id,
    required this.estado,
    this.prioridad,
    this.descripcion,
    this.descripcionIa,
    this.ubicacionLat,
    this.ubicacionLng,
    this.direccion,
    this.fechaCreacion,
    this.cliente,
    this.vehiculo,
  });

  factory IncidenteTecnico.fromJson(Map<String, dynamic> json) {
    final incidente = json['incidente'] ?? json;
    return IncidenteTecnico(
      id: incidente['id'] ?? 0,
      estado: incidente['estado'] ?? 'pendiente',
      prioridad: incidente['prioridad'],
      descripcion: incidente['descripcion'],
      descripcionIa: incidente['descripcion_ia'],
      ubicacionLat: incidente['ubicacion_lat'] != null
          ? (incidente['ubicacion_lat'] as num).toDouble()
          : null,
      ubicacionLng: incidente['ubicacion_lng'] != null
          ? (incidente['ubicacion_lng'] as num).toDouble()
          : null,
      direccion: incidente['direccion'],
      fechaCreacion: incidente['fecha_creacion'] != null
          ? DateTime.parse(incidente['fecha_creacion'])
          : null,
      cliente: incidente['cliente'] != null
          ? ClienteInfo.fromJson(incidente['cliente'])
          : null,
      vehiculo: incidente['vehiculo'] != null
          ? VehiculoInfo.fromJson(incidente['vehiculo'])
          : null,
    );
  }
}

class IncidenteTecnicoResponse {
  final bool tieneIncidente;
  final InfoTecnico? tecnico;
  final IncidenteTecnico? incidente;

  IncidenteTecnicoResponse({
    required this.tieneIncidente,
    this.tecnico,
    this.incidente,
  });

  factory IncidenteTecnicoResponse.fromJson(Map<String, dynamic> json) {
    return IncidenteTecnicoResponse(
      tieneIncidente: json['tiene_incidente'] ?? false,
      tecnico: json['tecnico'] != null
          ? InfoTecnico.fromJson(json['tecnico'])
          : null,
      incidente: json['incidente'] != null
          ? IncidenteTecnico.fromJson(json['incidente'])
          : null,
    );
  }
}