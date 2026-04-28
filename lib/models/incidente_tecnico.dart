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
  final String? email;
  final String? telefono;

  ClienteInfo({
    required this.id,
    required this.nombre,
    this.email,
    this.telefono,
  });

  factory ClienteInfo.fromJson(Map<String, dynamic> json) {
    return ClienteInfo(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? 'Cliente',
      email: json['email'],
      telefono: json['telefono'],
    );
  }
}

class VehiculoInfo {
  final int id;
  final String? marca;
  final String? modelo;
  final String? patente;
  final String? color;

  VehiculoInfo({
    required this.id,
    this.marca,
    this.modelo,
    this.patente,
    this.color,
  });

  factory VehiculoInfo.fromJson(Map<String, dynamic> json) {
    return VehiculoInfo(
      id: json['id'] ?? 0,
      marca: json['marca'],
      modelo: json['modelo'],
      patente: json['patente'],
      color: json['color'],
    );
  }
}

class EvidenciaInfo {
  final int id;
  final String tipo;
  final String? urlArchivo;
  final String? contenido;
  final String? descripcion;

  EvidenciaInfo({
    required this.id,
    required this.tipo,
    this.urlArchivo,
    this.contenido,
    this.descripcion,
  });

  factory EvidenciaInfo.fromJson(Map<String, dynamic> json) {
    return EvidenciaInfo(
      id: json['id'] ?? 0,
      tipo: json['tipo'] ?? 'texto',
      urlArchivo: json['url_archivo'],
      contenido: json['contenido'],
      descripcion: json['descripcion'],
    );
  }
}

class HistoriaInfo {
  final int id;
  final String? titulo;
  final String? descripcion;
  final DateTime? fechaHora;

  HistoriaInfo({
    required this.id,
    this.titulo,
    this.descripcion,
    this.fechaHora,
  });

  factory HistoriaInfo.fromJson(Map<String, dynamic> json) {
    return HistoriaInfo(
      id: json['id'] ?? 0,
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fechaHora: json['fecha_hora'] != null
          ? DateTime.tryParse(json['fecha_hora'])
          : null,
    );
  }
}

class IncidenteTecnico {
  final int id;
  final String estado;
  final String? prioridad;
  final String? descripcionOriginal;
  final String? descripcion;
  final String? descripcionIa;
  final double? ubicacionLat;
  final double? ubicacionLng;
  final String? direccion;
  final String? mensajeSolicitud;
  final DateTime? fechaCreacion;
  final ClienteInfo? cliente;
  final VehiculoInfo? vehiculo;
  final List<EvidenciaInfo>? evidencias;
  final List<HistoriaInfo>? historial;

  IncidenteTecnico({
    required this.id,
    required this.estado,
    this.prioridad,
    this.descripcionOriginal,
    this.descripcion,
    this.descripcionIa,
    this.ubicacionLat,
    this.ubicacionLng,
    this.direccion,
    this.mensajeSolicitud,
    this.fechaCreacion,
    this.cliente,
    this.vehiculo,
    this.evidencias,
    this.historial,
  });

  factory IncidenteTecnico.fromJson(Map<String, dynamic> json) {
    final incidente = json['incidente'] ?? json;
    List<EvidenciaInfo>? evidencias;
    if (incidente['evidencias'] != null) {
      evidencias = (incidente['evidencias'] as List)
          .map((e) => EvidenciaInfo.fromJson(e))
          .toList();
    }
    List<HistoriaInfo>? historial;
    if (incidente['historial'] != null) {
      historial = (incidente['historial'] as List)
          .map((h) => HistoriaInfo.fromJson(h))
          .toList();
    }
    return IncidenteTecnico(
      id: incidente['id'] ?? 0,
      estado: incidente['estado'] ?? 'pendiente',
      prioridad: incidente['prioridad'],
      descripcionOriginal: incidente['descripcion_original'],
      descripcion: incidente['descripcion'],
      descripcionIa: incidente['descripcion_ia'],
      ubicacionLat: incidente['ubicacion_lat'] != null
          ? (incidente['ubicacion_lat'] as num).toDouble()
          : null,
      ubicacionLng: incidente['ubicacion_lng'] != null
          ? (incidente['ubicacion_lng'] as num).toDouble()
          : null,
      direccion: incidente['direccion'],
      mensajeSolicitud: incidente['mensaje_solicitud'],
      fechaCreacion: incidente['fecha_creacion'] != null
          ? DateTime.parse(incidente['fecha_creacion'])
          : null,
      cliente: incidente['cliente'] != null
          ? ClienteInfo.fromJson(incidente['cliente'])
          : null,
      vehiculo: incidente['vehiculo'] != null
          ? VehiculoInfo.fromJson(incidente['vehiculo'])
          : null,
      evidencias: evidencias,
      historial: historial,
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