import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../models/incidente_tecnico.dart';
import '../../services/tecnico_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../login_screen.dart';
import '../notificaciones_screen.dart';
import 'mapa_tecnico_screen.dart';

class TecnicoHomeScreen extends StatefulWidget {
  const TecnicoHomeScreen({super.key});

  @override
  State<TecnicoHomeScreen> createState() => _TecnicoHomeScreenState();
}

class _TecnicoHomeScreenState extends State<TecnicoHomeScreen> {
  int _currentIndex = 0;
  IncidenteTecnicoResponse? _incidente;
  List<dynamic> _historial = [];
  List<Map<String, dynamic>> _notificaciones = [];
  bool _isLoading = true;
  String? _errorMessage;
  Position? _posicionActual;
  Timer? _ubicacionTimer;
  bool _ubicacionEnviada = false;

  @override
  void initState() {
    super.initState();
    _cargarIncidente();
    _cargarNotificaciones();
    _obtenerYEnviarUbicacion();
    _iniciarTimerUbicacion();
  }

  @override
  void dispose() {
    _ubicacionTimer?.cancel();
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

  void _iniciarTimerUbicacion() {
    _ubicacionTimer?.cancel();
    _ubicacionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_incidente?.tecnico?.disponible == true) {
        _obtenerYEnviarUbicacion();
      }
    });
  }

  Future<void> _obtenerYEnviarUbicacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      _posicionActual = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_posicionActual != null && mounted) {
        setState(() {});
        
        if (_incidente?.tecnico != null) {
          await _enviarUbicacionBackend(_posicionActual!.latitude, _posicionActual!.longitude);
        }
      }
    } catch (e) {
      debugPrint('Error al obtener ubicación: $e');
    }
  }

  Future<void> _enviarUbicacionBackend(double lat, double lng) async {
    if (_incidente?.tecnico == null) return;

    final resultado = await TecnicoService.actualizarUbicacion(
      _incidente!.tecnico!.id,
      lat,
      lng,
    );

    if (resultado['success'] && !_ubicacionEnviada) {
      _ubicacionEnviada = true;
      debugPrint('Ubicación enviada al backend: $lat, $lng');
    }
  }

  Future<void> _cargarIncidente() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final resultado = await TecnicoService.getMiIncidente();

    setState(() {
      _isLoading = false;
      if (resultado != null) {
        _incidente = resultado;
      } else {
        _errorMessage = 'Error al cargar incidente';
      }
    });
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);
    
    _historial = await TecnicoService.getHistorial();
    
    setState(() => _isLoading = false);
  }

  Future<void> _toggleDisponibilidad() async {
    if (_incidente?.tecnico == null) return;

    final nuevoEstado = !_incidente!.tecnico!.disponible;
    
    double? lat;
    double? lng;
    
    if (nuevoEstado) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            _posicionActual = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            if (_posicionActual != null) {
              lat = _posicionActual!.latitude;
              lng = _posicionActual!.longitude;
            }
          }
        }
      } catch (e) {
        debugPrint('Error al obtener ubicación: $e');
      }
    }

    final resultado = await TecnicoService.toggleDisponibilidad(
      _incidente!.tecnico!.id,
      nuevoEstado,
      lat: lat,
      lng: lng,
    );

    if (resultado['success']) {
      await _cargarIncidente();
      if (mounted) setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['error'] ?? 'Error al cambiar disponibilidad'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _logout() async {
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
            onPressed: () =>Navigator.pop(context, true),
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

  Future<void> _cambiarEstado(String nuevoEstado) async {
    if (_incidente?.tecnico == null) return;

    setState(() => _isLoading = true);

    final resultado = await TecnicoService.actualizarEstado(
      _incidente!.tecnico!.id,
      nuevoEstado,
    );

    setState(() => _isLoading = false);

    if (resultado['success']) {
      await _cargarIncidente();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a ${_getEstadoTexto(nuevoEstado)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['error'] ?? 'Error al cambiar estado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _finalizarConMonto(double monto) async {
    if (_incidente?.incidente == null) return;

    setState(() => _isLoading = true);

    final resultado = await TecnicoService.crearPagoYFinalizar(
      _incidente!.incidente!.id,
      monto,
    );

    setState(() => _isLoading = false);

    if (resultado['success']) {
      await _cargarIncidente();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incidente finalizado. Monto: Bs ${monto.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['error'] ?? 'Error al finalizar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<double?> _mostrarDialogoMonto() async {
    final TextEditingController montoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.attach_money, color: Colors.green),
            SizedBox(width: 8),
            Text('Finalizar Incidente'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingrese el monto del servicio:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: montoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto (Bs)',
                  prefixText: 'Bs ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el monto';
                  }
                  final monto = double.tryParse(value);
                  if (monto == null || monto <= 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final monto = double.parse(montoController.text);
                Navigator.pop(dialogContext, monto);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aceptar y Finalizar'),
          ),
        ],
      ),
    );
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'pendiente': return 'Pendiente';
      case 'asignado': return 'Asignado';
      case 'en_camino': return 'En Camino';
      case 'en_sitio': return 'En Sitio';
      case 'finalizado': return 'Finalizado';
      default: return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente': return Colors.orange;
      case 'asignado': return Colors.blue;
      case 'en_camino': return Colors.amber;
      case 'en_sitio': return Colors.green;
      case 'finalizado': return Colors.grey;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : const Color(0xFF2563EB);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(
            incidente: _incidente,
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            onRefresh: _cargarIncidente,
            onToggleDisponibilidad: _toggleDisponibilidad,
            onLogout: _logout,
            onCambiarEstado: _cambiarEstado,
            onFinalizarConMonto: _finalizarConMonto,
            onShowMontoDialog: _mostrarDialogoMonto,
            onVerMapa: () {
              if (_incidente?.incidente != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MapaTecnicoScreen(incidente: _incidente!.incidente!),
                  ),
                );
              }
            },
          ),
          _HistorialTab(
            historial: _historial,
            isLoading: _isLoading,
            onRefresh: _cargarHistorial,
          ),
          NotificacionesScreen(
              notificacionesIniciales: _notificaciones,
              onRefresh: _cargarNotificaciones,
            ),
          _PerfilTab(
            incidente: _incidente,
            onLogout: _logout,
            onToggleDisponibilidad: _toggleDisponibilidad,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 1 && _historial.isEmpty) {
            _cargarHistorial();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
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

class _HomeTab extends StatelessWidget {
  final IncidenteTecnicoResponse? incidente;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;
  final VoidCallback onToggleDisponibilidad;
  final VoidCallback onLogout;
  final Function(String) onCambiarEstado;
  final Function(double) onFinalizarConMonto;
  final VoidCallback onVerMapa;
  final Future<double?> Function() onShowMontoDialog;

  const _HomeTab({
    required this.incidente,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onToggleDisponibilidad,
    required this.onLogout,
    required this.onCambiarEstado,
    required this.onFinalizarConMonto,
    required this.onVerMapa,
    required this.onShowMontoDialog,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : const Color(0xFF2563EB);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.build_circle, color: primaryColor),
            const SizedBox(width: 8),
            const Text('AUXIA'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            onPressed: onLogout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => onRefresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTallerCard(primaryColor, isDark),
                    const SizedBox(height: 16),
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(child: Text(errorMessage!, style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    if (incidente?.tieneIncidente == true && incidente?.incidente != null) ...[
                      const SizedBox(height: 16),
                      _buildIncidenteCard(primaryColor, isDark),
                      const SizedBox(height: 16),
                      _buildEstadoButtons(primaryColor, isDark),
                    ] else
                      _buildNoIncidenteCard(primaryColor, isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTallerCard(Color primaryColor, bool isDark) {
    final disponible = incidente?.tecnico?.disponible ?? false;
    final taller = incidente?.tecnico?.nombreTaller ?? 'Taller';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [Colors.grey[800]!, Colors.grey[900]!] : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.build, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taller,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (incidente?.tecnico?.tallerId != null)
                      Text(
                        'ID: #${incidente?.tecnico?.tallerId}',
                        style: TextStyle(fontSize: 12, color: primaryColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onToggleDisponibilidad,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: disponible ? Colors.green.withAlpha(30) : Colors.grey.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: disponible ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    disponible ? Icons.check_circle : Icons.circle_outlined,
                    size: 20,
                    color: disponible ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    disponible ? 'Disponible' : 'No disponible',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: disponible ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: disponible,
                    onChanged: (_) => onToggleDisponibilidad(),
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidenteCard(Color primaryColor, bool isDark) {
    final incidente = this.incidente!.incidente!;
    final estado = incidente.estado;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A5F), const Color(0xFF0D1B2A)]
              : [const Color(0xFFEBF5FF), const Color(0xFFDBEAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withAlpha(77)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_car, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Incidente Activo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(estado),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getEstadoTexto(estado),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black : Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (incidente.vehiculo != null)
              _buildInfoRow(Icons.directions_car, 'Vehículo',
                  '${incidente.vehiculo!.marca ?? ''} ${incidente.vehiculo!.modelo ?? ''} (${incidente.vehiculo!.patente ?? ''})'),
            if (incidente.descripcion != null)
              _buildInfoRow(Icons.description, 'Problema', incidente.descripcion!),
            if (incidente.cliente != null)
              _buildInfoRow(Icons.person, 'Cliente', incidente.cliente!.nombre),
            if (incidente.direccion != null)
              _buildInfoRow(Icons.location_on, 'Dirección', incidente.direccion!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'pendiente': return 'Pendiente';
      case 'asignado': return 'Asignado';
      case 'en_camino': return 'En Camino';
      case 'en_sitio': return 'En Sitio';
      case 'finalizado': return 'Finalizado';
      default: return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente': return Colors.orange;
      case 'asignado': return Colors.blue;
      case 'en_camino': return Colors.amber;
      case 'en_sitio': return Colors.green;
      case 'finalizado': return Colors.grey;
      default: return Colors.blue;
    }
  }

  Widget _buildNoIncidenteCard(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin Incidentes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Se te asignará un incidente cuando haya uno disponible',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoButtons(Color primaryColor, bool isDark) {
    final estado = incidente?.incidente?.estado ?? 'pendiente';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: onVerMapa,
          icon: const Icon(Icons.map),
          label: const Text('Ver Mapa'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        if (estado == 'asignado')
          ElevatedButton.icon(
            onPressed: () => onCambiarEstado('en_camino'),
            icon: const Icon(Icons.directions_car),
            label: const Text('Voy en Camino'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        if (estado == 'en_camino')
          ElevatedButton.icon(
            onPressed: () => onCambiarEstado('en_sitio'),
            icon: const Icon(Icons.location_on),
            label: const Text('Llegué al Sitio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        if (estado == 'en_sitio')
          ElevatedButton.icon(
            onPressed: () async {
              final monto = await onShowMontoDialog();
              if (monto != null && monto > 0) {
                onFinalizarConMonto(monto);
              }
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Finalizar Incidencia'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }
}

class _HistorialTab extends StatelessWidget {
  final List<dynamic> historial;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _HistorialTab({
    required this.historial,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : const Color(0xFF2563EB);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: primaryColor),
            const SizedBox(width: 8),
            const Text('Historial'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : historial.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Sin historial',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aún no has atendido incidentes',
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => onRefresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: historial.length,
                    itemBuilder: (context, index) {
                      final item = historial[index];
                      return _buildHistorialItem(item, isDark, primaryColor);
                    },
                  ),
                ),
    );
  }

  Widget _buildHistorialItem(Map<String, dynamic> item, bool isDark, Color primaryColor) {
    final String estado = item['estado']?.toString() ?? '';
    final String descripcion = item['descripcion']?.toString() ?? 'Sin descripción';
    final Map<String, dynamic>? vehiculo = item['vehiculo'] as Map<String, dynamic>?;
    final Map<String, dynamic>? cliente = item['cliente'] as Map<String, dynamic>?;
    final dynamic fechaFin = item['fecha_fin'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getEstadoColor(estado),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getEstadoTexto(estado),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (fechaFin != null)
                Text(
                  _formatFecha(fechaFin.toString()),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (vehiculo != null && vehiculo.isNotEmpty)
            Text(
              '${vehiculo['marca'] ?? ''} ${vehiculo['modelo'] ?? ''} (${vehiculo['patente'] ?? ''})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            descripcion,
            style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
          ),
          if (cliente != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  cliente['nombre'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'pendiente': return 'Pendiente';
      case 'asignado': return 'Asignado';
      case 'en_camino': return 'En Camino';
      case 'en_sitio': return 'En Sitio';
      case 'finalizado': return 'Finalizado';
      default: return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente': return Colors.orange;
      case 'asignado': return Colors.blue;
      case 'en_camino': return Colors.amber;
      case 'en_sitio': return Colors.green;
      case 'finalizado': return Colors.grey;
      default: return Colors.blue;
    }
  }

  String _formatFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return fecha;
    }
  }
}

class _PerfilTab extends StatelessWidget {
  final IncidenteTecnicoResponse? incidente;
  final VoidCallback onLogout;
  final VoidCallback onToggleDisponibilidad;

  const _PerfilTab({
    required this.incidente,
    required this.onLogout,
    required this.onToggleDisponibilidad,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : const Color(0xFF2563EB);
    final disponible = incidente?.tecnico?.disponible ?? false;
    final taller = incidente?.tecnico?.nombreTaller ?? 'Taller';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, color: primaryColor),
            const SizedBox(width: 8),
            const Text('Mi Perfil'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: primaryColor,
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
),
            const SizedBox(height: 16),
            if (incidente?.tecnico?.usuario != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: primaryColor),
                        const SizedBox(width: 12),
                        const Text(
                          'Mis Datos',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.badge, 'Nombre', incidente!.tecnico!.usuario!.nombre),
                    if (incidente!.tecnico!.usuario!.username != null)
                      _buildInfoRow(Icons.alternate_email, 'Usuario', incidente!.tecnico!.usuario!.username!),
                    if (incidente!.tecnico!.usuario!.email != null)
                      _buildInfoRow(Icons.email, 'Email', incidente!.tecnico!.usuario!.email!),
                    if (incidente!.tecnico!.usuario!.telefono != null)
                      _buildInfoRow(Icons.phone, 'Teléfono', incidente!.tecnico!.usuario!.telefono!),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Técnico',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.build, color: primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        'Información del Taller',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.business, 'Taller', taller),
                  if (incidente?.tecnico?.tallerId != null)
                    _buildInfoRow(Icons.tag, 'ID', '#${incidente?.tecnico?.tallerId}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.toggle_on, color: primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        'Estado',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onToggleDisponibilidad,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: disponible ? Colors.green.withAlpha(26) : Colors.grey.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: disponible ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                disponible ? Icons.check_circle : Icons.circle_outlined,
                                color: disponible ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                disponible ? 'Disponible' : 'No disponible',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: disponible ? Colors.green : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: disponible,
                            onChanged: (_) => onToggleDisponibilidad(),
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[500]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}