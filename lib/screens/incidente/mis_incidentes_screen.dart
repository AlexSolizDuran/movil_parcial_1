import 'package:flutter/material.dart';
import '../../services/incidente_service.dart';
import '../../models/incidente.dart';
import 'detalle_incidente_screen.dart';

class MisIncidentesScreen extends StatefulWidget {
  const MisIncidentesScreen({super.key});

  @override
  State<MisIncidentesScreen> createState() => _MisIncidentesScreenState();
}

class _MisIncidentesScreenState extends State<MisIncidentesScreen> {
  final IncidenteService _incidenteService = IncidenteService();
  List<Incidente> _incidentes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIncidentes();
  }

  Future<void> _loadIncidentes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final incidentes = await _incidenteService.obtenerMisIncidentes();
      setState(() {
        _incidentes = incidentes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar incidentes: $e';
        _isLoading = false;
      });
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'asignado':
        return Colors.blue;
      case 'en_proceso':
        return Colors.purple;
      case 'completado':
        return Colors.green;
      case 'cancelado':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getPrioridadColor(String? prioridad) {
    switch (prioridad?.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _verDetalle(Incidente incidente) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleIncidenteScreen(incidenteId: incidente.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : Colors.blue[700]!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Incidentes'),
          backgroundColor: primaryColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Incidentes'),
          backgroundColor: primaryColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadIncidentes,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_incidentes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Incidentes'),
          backgroundColor: primaryColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadIncidentes,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No tienes incidentes',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Incidentes'),
        backgroundColor: primaryColor,
        foregroundColor: isDark ? Colors.black : Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIncidentes,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadIncidentes,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _incidentes.length,
          itemBuilder: (context, index) {
            final incidente = _incidentes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _verDetalle(incidente),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: _getPrioridadColor(incidente.prioridad),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Incidente #${incidente.id}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getEstadoColor(
                                incidente.estado,
                              ).withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getEstadoColor(incidente.estado),
                              ),
                            ),
                            child: Text(
                              incidente.estado,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getEstadoColor(incidente.estado),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (incidente.especialidadIa != null)
                        Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Especialidad: ${incidente.especialidadIa}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      if (incidente.especialidadIa != null)
                        const SizedBox(height: 8),
                      if (incidente.prioridad != null)
                        Row(
                          children: [
                            Icon(
                              Icons.flag,
                              size: 16,
                              color: _getPrioridadColor(incidente.prioridad),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Prioridad: ${incidente.prioridad}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      if (incidente.prioridad != null)
                        const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lat: ${incidente.ubicacionLat.toStringAsFixed(4)}, Lng: ${incidente.ubicacionLng.toStringAsFixed(4)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(incidente.fechaCreacion),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
