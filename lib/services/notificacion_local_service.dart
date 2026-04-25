import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificacionLocalService {
  static final NotificacionLocalService _instance = NotificacionLocalService._internal();
  factory NotificacionLocalService() => _instance;
  NotificacionLocalService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> inicializar() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _isInitialized = true;
  }

  Future<void> solicitarPermisos() async {
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> mostrarNotificacion({
    required int id,
    required String titulo,
    required String cuerpo,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await inicializar();
    }

    const androidDetails = AndroidNotificationDetails(
      'canal_notificaciones',
      'Notificaciones AUXIA',
      channelDescription: 'Notificaciones de incidentes y emergencias',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, titulo, cuerpo, details, payload: payload);
  }

  Future<void> mostrarNotificacionAnalisis({
    required int incidenteId,
    required String especialidad,
  }) async {
    await mostrarNotificacion(
      id: incidenteId,
      titulo: 'Incidente Analizado',
      cuerpo: 'Tu incidente ha sido analizado. Especialidad: $especialidad',
      payload: 'analisis_$incidenteId',
    );
  }

  Future<void> mostrarNotificacionAsignado({
    required int incidenteId,
    required String tallerNombre,
  }) async {
    await mostrarNotificacion(
      id: incidenteId + 10000,
      titulo: 'Taller Asignado',
      cuerpo: 'El taller $tallerNombre ha aceptado tu incidente',
      payload: 'asignado_$incidenteId',
    );
  }

  Future<void> mostrarNotificacionRechazo({
    required int incidenteId,
    required String mensaje,
  }) async {
    await mostrarNotificacion(
      id: incidenteId + 20000,
      titulo: 'Taller no disponible',
      cuerpo: mensaje,
      payload: 'rechazo_$incidenteId',
    );
  }

  Future<void> mostrarNotificacionCambioEstado({
    required int incidenteId,
    required String nuevoEstado,
  }) async {
    await mostrarNotificacion(
      id: incidenteId + 30000,
      titulo: 'Estado Actualizado',
      cuerpo: 'Tu incidente ahora está: $nuevoEstado',
      payload: 'estado_$incidenteId',
    );
  }

  Future<void> cancelarNotificacion(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelarTodas() async {
    await _notifications.cancelAll();
  }
}