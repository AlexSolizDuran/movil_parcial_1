import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/incidente_service.dart';
import '../services/notificacion_service.dart';
import '../models/usuario.dart';
import 'login_screen.dart';
import 'perfil_screen.dart';
import 'vehiculos_list_screen.dart';
import 'incidente/reportar_emergencia_screen.dart';
import 'incidente/mis_incidentes_screen.dart';
import 'incidente/detalle_incidente_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Usuario? _usuario;
  final NotificacionService _notificacionService = NotificacionService();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _notificacionService.iniciarEscucha();
    _notificacionService.onNotificacion.listen(_mostrarNotificacion);
  }

  @override
  void dispose() {
    _notificacionService.detenerEscucha();
    super.dispose();
  }

  void _mostrarNotificacion(Notificacion notificacion) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(notificacion.cuerpo),
        backgroundColor: notificacion.tipo == 'nuevo_incidente'
            ? Colors.green
            : Colors.blue,
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () {
            setState(() => _currentIndex = 1);
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
      case 'asignado':
        return 'Asignado';
      case 'en_camino':
        return 'En camino';
      case 'en_sitio':
        return 'En sitio';
      default:
        return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'asignado':
        return Colors.blue;
      case 'en_camino':
        return Colors.orange;
      case 'en_sitio':
        return Colors.green;
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
              Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
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
                      icon: Icons.report_problem,
                      title: 'Reportar',
                      subtitle: 'Emergencia',
                      color: Colors.red,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ReportarEmergenciaScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.search,
                      title: 'Buscar',
                      subtitle: 'Talleres',
                      color: Colors.green,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Próximamente: Buscar talleres'),
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

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Incidente en Curso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
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
