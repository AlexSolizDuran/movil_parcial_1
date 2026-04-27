import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class NotificacionesScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? notificacionesIniciales;
  final Future Function()? onRefresh;
  
  const NotificacionesScreen({
    super.key, 
    this.notificacionesIniciales,
    this.onRefresh
  });

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final List<Map<String, dynamic>> _notificaciones = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.notificacionesIniciales != null) {
      final sortedData = List<Map<String, dynamic>>.from(widget.notificacionesIniciales!);
      sortedData.sort((a, b) {
        final fechaA = _parseFecha(a['fecha_envio']);
        final fechaB = _parseFecha(b['fecha_envio']);
        if (fechaA == null && fechaB == null) return 0;
        if (fechaA == null) return 1;
        if (fechaB == null) return -1;
        return fechaB.compareTo(fechaA);
      });
      _notificaciones.addAll(sortedData);
    }
  }

  Future<void> _cargarNotificaciones() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(ApiConfig.misNotificacionesUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.body.isNotEmpty 
            ? List.from(jsonDecode(response.body)) 
            : [];
        final sortedData = List<Map<String, dynamic>>.from(data);
        sortedData.sort((a, b) {
          final fechaA = _parseFecha(a['fecha_envio']);
          final fechaB = _parseFecha(b['fecha_envio']);
          if (fechaA == null && fechaB == null) return 0;
          if (fechaA == null) return 1;
          if (fechaB == null) return -1;
          return fechaB.compareTo(fechaA);
        });
        setState(() {
          _notificaciones.clear();
          _notificaciones.addAll(sortedData);
        });
      }
    } catch (e) {
    } catch (e) {
      debugPrint('Error cargar notificaciones: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar notificaciones: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  DateTime? _parseFecha(dynamic fecha) {
    if (fecha == null) return null;
    if (fecha is String) {
      try {
        return DateTime.parse(fecha);
      } catch (e) {
        return null;
      }
    }
    if (fecha is DateTime) {
      return fecha;
    }
    return null;
  }

  void agregarNotificacion(Map<String, dynamic> notificacion) {
    setState(() {
      _notificaciones.insert(0, notificacion);
    });
  }

  void limpiarNotificaciones() {
    setState(() {
      _notificaciones.clear();
    });
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'incidente_asignado':
        return Colors.green;
      case 'analisis_ia_completo':
        return Colors.purple;
      case 'taller_rechazo':
      case 'taller_expirado':
        return Colors.orange;
      case 'sin_talleres':
        return Colors.red;
      case 'cambio_estado':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'incidente_asignado':
        return Icons.check_circle;
      case 'analisis_ia_completo':
        return Icons.auto_awesome;
      case 'taller_rechazo':
      case 'taller_expirado':
        return Icons.warning;
      case 'sin_talleres':
        return Icons.location_off;
      case 'cambio_estado':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _cargarNotificaciones,
            tooltip: 'Actualizar',
          ),
          if (_notificaciones.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: limpiarNotificaciones,
              tooltip: 'Limpiar todas',
            ),
        ],
      ),
      body: _isLoading && _notificaciones.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarNotificaciones,
              child: _notificaciones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes notificaciones',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _cargarNotificaciones,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualizar'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _notificaciones.length,
                      itemBuilder: (context, index) {
                        final notif = _notificaciones[index];
                        final tipo = notif['tipo']?.toString() ?? 'default';
                        final titulo = notif['titulo']?.toString() ?? 'Notificación';
                        final mensaje = notif['mensaje']?.toString() ?? '';
                        final fecha = notif['fecha_envio'];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getTipoColor(tipo).withAlpha(30),
                              child: Icon(
                                _getTipoIcon(tipo),
                                color: _getTipoColor(tipo),
                              ),
                            ),
                            title: Text(
                              titulo,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(mensaje),
                                if (fecha != null)
                                  Text(
                                    _formatFecha(fecha),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.circle,
                              size: 10,
                              color: notif['leida'] == true
                                  ? Colors.transparent
                                  : Colors.blue,
                            ),
                            onTap: () {
                              setState(() {
                                notif['leida'] = true;
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '';
    if (fecha is String) {
      try {
        final dt = DateTime.parse(fecha);
        return _formatDateTime(dt);
      } catch (e) {
        return fecha;
      }
    }
    if (fecha is DateTime) {
      return _formatDateTime(fecha);
    }
    return '';
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'Ahora';
    } else if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} h';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}