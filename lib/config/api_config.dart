class ApiConfig {
  static const String defaultBaseUrl = 'http://192.168.0.6:8000';

  static String baseUrl = defaultBaseUrl;

  static String get apiUrl => baseUrl;

  // Auth endpoints
  static String get registerUrl => '$apiUrl/usuarios/usuario/register';
  static String get loginUrl => '$apiUrl/usuarios/usuario/login';
  static String get meUrl => '$apiUrl/usuarios/usuario/me';
  static String get usuariosUrl => '$apiUrl/usuarios/usuario';

  // Vehicle endpoints
  static String vehiculoUrl(int id) => '$apiUrl/activos/vehiculo/$id';
  static String get vehiculosUrl => '$apiUrl/activos/vehiculo';
  static String get misVehiculosUrl =>
      '$apiUrl/activos/vehiculo/mis-vehiculos/';

  // Incident endpoints
  static String get incidentesUrl => '$apiUrl/incidentes/';
  static String incidentesDetailUrl(int id) => '$apiUrl/incidentes/$id';
  static String get misIncidentesUrl => '$apiUrl/incidentes/mis-incidentes';
  static String get incidenteEnCursoUrl =>
      '$apiUrl/incidentes/incidente-en-curso';
  static String incidenteEvidenciasUrl(int id) =>
      '$apiUrl/incidentes/$id/evidencias';
  static String incidenteAnalizarUrl(int id) =>
      '$apiUrl/incidentes/$id/analizar';
  static String incidenteAsignarUrl(int id) => '$apiUrl/incidentes/$id/asignar';
  static String incidenteHistorialUrl(int id) =>
      '$apiUrl/incidentes/$id/historia';
  static String incidenteEstadisticasUrl(int id) =>
      '$apiUrl/incidentes/$id/estadisticas';

  // IA endpoints
  static String get iaAnalizarIncidenteUrl => '$apiUrl/ia/analizar-incidente';
  static String get iaTranscribirAudioUrl => '$apiUrl/ia/transcribir-audio';
  static String get iaAnalizarImagenUrl => '$apiUrl/ia/analizar-imagen';
}
