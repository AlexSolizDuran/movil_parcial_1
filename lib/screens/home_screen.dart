import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/incidente_service.dart';
import '../services/cliente_notificacion_service.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/usuario.dart';
import 'login_screen.dart';
import 'perfil_screen.dart';
import 'vehiculos_list_screen.dart';
import 'incidente/reportar_emergencia_screen.dart';
import 'incidente/mis_incidentes_screen.dart';
import 'incidente/detalle_incidente_screen.dart';
import 'notificaciones_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Usuario? _usuario;
  List<Map<String, dynamic>> _notificaciones = [];
  final ClienteNotificacionService _notificacionService = ClienteNotificacionService();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _initNotificaciones();
    _cargarNotificaciones();
  }

  @override
  void dispose() {
    _notificacionService.disconnect();
    super.dispose();
  }

  Future<void> _cargarNotificaciones() async {
    try {
      final response = await ApiService.get(ApiConfig.misNotificacionesUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.body.isNotEmpty ? List.from(jsonDecode(response.body)) : [];
        setState(() {
          _notificaciones = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error cargar notificaciones: $e');
    }
  }

  Future<void> _initNotificaciones() async {
    await _notificacionService.connect();
    _notificacionService.onNotificacion.listen((notif) {
      _mostrarNotificacion(notif);
      _cargarNotificaciones();
    });
  }

  void _mostrarNotificacion(NotificacionPush notificacion) {
    if (!mounted) return;
    
    Color color;
    IconData icon;
    
    switch (notificacion.type) {
      case 'taller_rechazo':
        color = Colors.orange;
        icon = Icons.warning_amber;
        break;
      case 'taller_expirado':
        color = Colors.orange;
        icon = Icons.timer_off;
        break;
      case 'sin_talleres':
        color = Colors.red;
        icon = Icons.location_off;
        break;
      case 'incidente_asignado':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'cambio_estado':
        color = Colors.blue;
        icon = Icons.info;
        break;
      case 'analisis_ia_completo':
        color = Colors.purple;
        icon = Icons.auto_awesome;
        break;
      default:
        color = Colors.grey;
        icon = Icons.notifications;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notificacion.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (notificacion.mensaje.isNotEmpty)
                    Text(
                      notificacion.mensaje,
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () {
            if (notificacion.data != null && notificacion.data!['incidente_id'] != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetalleIncidenteScreen(
                    incidenteId: notificacion.data!['incidente_id'],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted && user != null) {
      setState(() => _usuario = user);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(usuario: _usuario, onRefresh: _loadUser, onLogout: _logout),
          MisIncidentesScreen(),
          NotificacionesScreen(
              notificacionesIniciales: _notificaciones,
              onRefresh: _cargarNotificaciones,
            ),
          PerfilScreen(usuario: _usuario, onUpdate: _loadUser),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem),
            label: 'Incidentes',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final Usuario? usuario;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const _HomeTab({
    required this.usuario,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final IncidenteService _incidenteService = IncidenteService();
  Map<String, dynamic>? _incidenteEnCurso;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarIncidenteEnCurso();
  }

  Future<void> _cargarIncidenteEnCurso() async {
    setState(() => _isLoading = true);
    try {
      final resultado = await _incidenteService.obtenerIncidenteEnCurso();
      if (mounted) {
        setState(() {
          _incidenteEnCurso = resultado;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado) {
      case 'reportado':
        return 'En espera de análisis';
      case 'asignado':
        return 'Asignado';
      case 'en_camino':
        return 'En camino';
      case 'en_sitio':
        return 'En sitio';
      case 'finalizado':
        return 'Finalizado';
      case 'cancelado':
        return 'Cancelado';
      case 'sin_talleres':
        return 'Sin talleres disponibles';
      case 'incluido':
        return 'Análisis inconcluso';
      default:
        return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'reportado':
        return Colors.orange;
      case 'asignado':
        return Colors.blue;
      case 'en_camino':
        return Colors.orange;
      case 'en_sitio':
        return Colors.green;
      case 'finalizado':
        return Colors.grey;
      case 'cancelado':
        return Colors.red;
      case 'sin_talleres':
        return Colors.red;
      case 'incluido':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : Colors.blue[700]!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.directions_car, color: primaryColor),
            const SizedBox(width: 8),
            const Text('AUXIA'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _cargarIncidenteEnCurso();
              widget.onRefresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _cargarIncidenteEnCurso();
          widget.onRefresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_incidenteEnCurso != null &&
                  _incidenteEnCurso!['tiene_incidente'] == true) ...[
                _IncidenteEnCursoCard(
                  data: _incidenteEnCurso!,
                  getEstadoLabel: _getEstadoLabel,
                  getEstadoColor: _getEstadoColor,
                  onVerDetalle: () {
                    final incidenteId = _incidenteEnCurso!['incidente']['id'];
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            DetalleIncidenteScreen(incidenteId: incidenteId),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: primaryColor,
                        child: Text(
                          widget.usuario?.nombre.isNotEmpty == true
                              ? widget.usuario!.nombre[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenido',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              widget.usuario?.nombre ?? 'Cargando...',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Cliente',
                              style: TextStyle(
                                fontSize: 14,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade700],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withAlpha(102),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReportarEmergenciaScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  icon: const Icon(Icons.emergency, color: Colors.white, size: 28),
                  label: const Text(
                    'REPORTAR EMERGENCIA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.directions_car,
                      title: 'Mis Vehículos',
                      subtitle: 'Gestionar',
                      color: primaryColor,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const VehiculosListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.history,
                      title: 'Historial',
                      subtitle: 'Incidentes',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MisIncidentesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            '¿Necesitas ayuda?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Contacta a nuestros servicios de emergencia vehicular las 24 horas del día.',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.phone),
                        label: const Text('Llamar ahora'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncidenteEnCursoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(String) getEstadoLabel;
  final Color Function(String) getEstadoColor;
  final VoidCallback onVerDetalle;

  const _IncidenteEnCursoCard({
    required this.data,
    required this.getEstadoLabel,
    required this.getEstadoColor,
    required this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    final brillo = MediaQuery.platformBrightnessOf(context);
    final isDark = brillo == Brightness.dark;
    final incidente = data['incidente'] as Map<String, dynamic>?;
    final taller = data['taller'] as Map<String, dynamic>?;
    final tecnico = data['tecnico'] as Map<String, dynamic>?;
    final historial = data['historial'] as List<dynamic>? ?? [];
    final estado = incidente?['estado'] ?? '';

    final esEstadoInicial = estado == 'reportado' || estado == 'incluido';
    final cardColor = esEstadoInicial ? Colors.orange[50] : Colors.blue[50];
    final iconColor = esEstadoInicial ? Colors.orange[700] : Colors.blue[700];

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  esEstadoInicial ? 'Incidente en Análisis' : 'Incidente en Curso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getEstadoColor(
                      incidente?['estado'] ?? '',
                    ).withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    getEstadoLabel(incidente?['estado'] ?? ''),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: getEstadoColor(incidente?['estado'] ?? ''),
                    ),
                  ),
                ),
              ],
            ),
            
            if (incidente?['especialidad_ia'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    'Especialidad: ${incidente?['especialidad_ia'] ?? 'Analizando...'}',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            
            if (incidente?['descripcion_ia'] != null && incidente!['descripcion_ia'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(128),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análisis de IA:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      incidente?['descripcion_ia'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
            
            if (incidente?['mensaje_solicitud'] != null && incidente!['mensaje_solicitud'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        incidente?['mensaje_solicitud'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            if (taller != null) ...[
              Row(
                children: [
                  Icon(Icons.build, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Taller: ${taller['nombre'] ?? 'Por asignar'}',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (tecnico != null) ...[
              Row(
                children: [
                  Icon(Icons.person, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Tecnico: ${tecnico['nombre'] ?? 'Por asignar'}',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              if (tecnico['ubicacion_lat'] != null &&
                  tecnico['ubicacion_lng'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Ubicacion del tecnico disponible',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
            ],
            if (historial.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Historial:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...historial
                  .take(3)
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h['titulo'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                if (h['descripcion'] != null)
                                  Text(
                                    h['descripcion'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onVerDetalle,
                child: const Text('Ver Detalles'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
