class Incidente {
  final int id;
  final int clienteId;
  final int? vehiculoId;
  final double ubicacionLat;
  final double ubicacionLng;
  final String? especialidadIa;
  final String? descripcionIa;
  final String? prioridad;
  final String estado;
  final String? descripcionOriginal;
  final String? descripcion;
  final int? requiereMasEvidencia;
  final String? mensajeSolicitud;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Incidente({
    required this.id,
    required this.clienteId,
    this.vehiculoId,
    required this.ubicacionLat,
    required this.ubicacionLng,
    this.especialidadIa,
    this.descripcionIa,
    this.prioridad,
    required this.estado,
    this.descripcionOriginal,
    this.descripcion,
    this.requiereMasEvidencia,
    this.mensajeSolicitud,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory Incidente.fromJson(Map<String, dynamic> json) {
    return Incidente(
      id: json['id'],
      clienteId: json['cliente_id'],
      vehiculoId: json['vehiculo_id'],
      ubicacionLat: (json['ubicacion_lat'] as num).toDouble(),
      ubicacionLng: (json['ubicacion_lng'] as num).toDouble(),
      especialidadIa: json['especialidad_ia'],
      descripcionIa: json['descripcion_ia'],
      prioridad: json['prioridad'],
      estado: json['estado'],
      descripcionOriginal: json['descripcion_original'],
      descripcion: json['descripcion'],
      requiereMasEvidencia: json['requiere_mas_evidencia'],
      mensajeSolicitud: json['mensaje_solicitud'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaActualizacion: DateTime.parse(json['fecha_actualizacion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'vehiculo_id': vehiculoId,
      'ubicacion_lat': ubicacionLat,
      'ubicacion_lng': ubicacionLng,
      'especialidad_ia': especialidadIa,
      'descripcion_ia': descripcionIa,
      'prioridad': prioridad,
      'estado': estado,
      'descripcion_original': descripcionOriginal,
      'descripcion': descripcion,
      'requiere_mas_evidencia': requiereMasEvidencia,
      'mensaje_solicitud': mensajeSolicitud,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    };
  }
}

class Evidencia {
  final int id;
  final int incidenteId;
  final String tipo;
  final String? urlArchivo;
  final String? contenido;
  final String? transcripcion;
  final String? descripcion;
  final DateTime fechaSubida;

  Evidencia({
    required this.id,
    required this.incidenteId,
    required this.tipo,
    this.urlArchivo,
    this.contenido,
    this.transcripcion,
    this.descripcion,
    required this.fechaSubida,
  });

  factory Evidencia.fromJson(Map<String, dynamic> json) {
    return Evidencia(
      id: json['id'],
      incidenteId: json['incidente_id'],
      tipo: json['tipo'],
      urlArchivo: json['url_archivo'],
      contenido: json['contenido'],
      transcripcion: json['transcripcion'],
      descripcion: json['descripcion'],
      fechaSubida: DateTime.parse(json['fecha_subida']),
    );
  }
}

class HistoriaIncidente {
  final int id;
  final int incidenteId;
  final String titulo;
  final String? descripcion;
  final DateTime fechaHora;

  HistoriaIncidente({
    required this.id,
    required this.incidenteId,
    required this.titulo,
    this.descripcion,
    required this.fechaHora,
  });

  factory HistoriaIncidente.fromJson(Map<String, dynamic> json) {
    return HistoriaIncidente(
      id: json['id'],
      incidenteId: json['incidente_id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fechaHora: DateTime.parse(json['fecha_hora']),
    );
  }
}

class IncidenteCompleto {
  final Incidente incidente;
  final List<Evidencia> evidencias;
  final List<HistoriaIncidente> historial;
  final List<dynamic> asignaciones;
  final int totalEvidencias;
  final bool tieneFoto;
  final bool tieneAudio;

  IncidenteCompleto({
    required this.incidente,
    required this.evidencias,
    required this.historial,
    required this.asignaciones,
    required this.totalEvidencias,
    required this.tieneFoto,
    required this.tieneAudio,
  });

  factory IncidenteCompleto.fromJson(Map<String, dynamic> json) {
    return IncidenteCompleto(
      incidente: Incidente.fromJson(json['incidente']),
      evidencias: (json['evidencias'] as List)
          .map((e) => Evidencia.fromJson(e))
          .toList(),
      historial: (json['historial'] as List)
          .map((h) => HistoriaIncidente.fromJson(h))
          .toList(),
      asignaciones: json['asignaciones'] as List,
      totalEvidencias: json['total_evidencias'],
      tieneFoto: json['tiene_foto'],
      tieneAudio: json['tiene_audio'],
    );
  }
}
