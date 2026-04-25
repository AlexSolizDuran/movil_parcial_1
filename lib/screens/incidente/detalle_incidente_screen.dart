import 'package:flutter/material.dart';
import '../../services/incidente_service.dart';
import '../../models/incidente.dart';
import 'agregar_evidencia_screen.dart';

class DetalleIncidenteScreen extends StatefulWidget {
  final int incidenteId;

  const DetalleIncidenteScreen({super.key, required this.incidenteId});

  @override
  State<DetalleIncidenteScreen> createState() => _DetalleIncidenteScreenState();
}

class _DetalleIncidenteScreenState extends State<DetalleIncidenteScreen> {
  final IncidenteService _incidenteService = IncidenteService();
  IncidenteCompleto? _incidenteCompleto;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetalle();
  }

  Future<void> _loadDetalle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detalle = await _incidenteService.obtenerEstadisticas(
        widget.incidenteId,
      );
      setState(() {
        _incidenteCompleto = detalle;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar detalle: $e';
        _isLoading = false;
      });
    }
  }

  Color _getEstadoColor(String? estado) {
    final e = estado ?? 'reportado';
    switch (e.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'asignado':
        return Colors.blue;
      case 'en_proceso':
        return Colors.purple;
      case 'completado':
      case 'finalizado':
        return Colors.green;
      case 'cancelado':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getHistoriaEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'recibido':
        return Colors.blue;
      case 'en_revision':
        return Colors.orange;
      case 'asignado':
        return Colors.purple;
      case 'en_atencion':
        return Colors.amber;
      case 'completado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
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

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : Colors.blue[700]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Incidente #${widget.incidenteId}'),
        backgroundColor: primaryColor,
        foregroundColor: isDark ? Colors.black : Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDetalle,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDetalle,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber,
                                  color: _getPrioridadColor(
                                    _incidenteCompleto!.incidente?.prioridad,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _incidenteCompleto!.incidente?.especialidadIa ??
                                        'Sin clasificar',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getEstadoColor(
                                      _incidenteCompleto!.incidente?.estado ?? 'reportado',
                                    ).withAlpha(30),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _getEstadoColor(
                                        _incidenteCompleto!.incidente?.estado ?? 'reportado',
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _incidenteCompleto!.incidente?.estado ?? 'reportado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getEstadoColor(
                                        _incidenteCompleto!.incidente?.estado ?? 'reportado',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            if (_incidenteCompleto!.incidente?.prioridad !=
                                null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.flag,
                                    size: 20,
                                    color: _getPrioridadColor(
                                      _incidenteCompleto!.incidente?.prioridad,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Prioridad: ${_incidenteCompleto!.incidente?.prioridad}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _getPrioridadColor(
                                        _incidenteCompleto!.incidente?.prioridad,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (_incidenteCompleto!
                                    .incidente
                                    ?.descripcionOriginal !=
                                null) ...[
                              Text(
                                'Descripción original:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _incidenteCompleto!
                                    .incidente
                                    ?.descripcionOriginal ??
                                    '',
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (_incidenteCompleto!.incidente?.descripcionIa !=
                                null) ...[
                              Text(
                                'Análisis IA:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _incidenteCompleto!.incidente?.descripcionIa ??
                                    '',
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (_incidenteCompleto!
                                    .incidente
                                    ?.requiereMasEvidencia ==
                                1) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber,
                                          color: Colors.orange[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Se necesita más información',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
_incidenteCompleto!
                                                .incidente
                                                ?.mensajeSolicitud ??
                                          'Por favor, proporciona más detalles sobre el incidente.',
                                      style: TextStyle(color: Colors.grey[800]),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
AgregarEvidenciaScreen(
                                                  incidenteId:
                                                      _incidenteCompleto!
                                                          .incidente
                                                          ?.id ??
                                                          0,
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.add_photo_alternate,
                                      ),
                                      label: const Text('Agregar Evidencia'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Lat: ${_incidenteCompleto!.incidente?.ubicacionLat?.toStringAsFixed(6) ?? 'N/A'}, Lng: ${_incidenteCompleto!.incidente?.ubicacionLng?.toStringAsFixed(6) ?? 'N/A'}',
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
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(
                                    _incidenteCompleto!.incidente?.fechaCreacion,
                                  ),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.attach_file, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Evidencias (${_incidenteCompleto!.totalEvidencias})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        if (_incidenteCompleto!.tieneFoto == true)
                          const Icon(Icons.photo, color: Colors.blue, size: 20),
                        if (_incidenteCompleto!.tieneAudio == true)
                          const Icon(Icons.mic, color: Colors.orange, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_incidenteCompleto!.evidencias.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'No hay evidencias',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_incidenteCompleto!.evidencias.length, (
                        index,
                      ) {
                        final evidencia = _incidenteCompleto!.evidencias[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  evidencia.tipo == 'foto'
                                      ? Icons.photo
                                      : Icons.mic,
                                  color: evidencia.tipo == 'foto'
                                      ? Colors.blue
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        evidencia.tipo == 'foto'
                                            ? 'Fotografía'
                                            : 'Audio',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (evidencia.transcripcion != null)
                                        Text(
                                          evidencia.transcripcion!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      Text(
                                        _formatDate(evidencia.fechaSubida),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    Text(
                      'Historial de Estados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_incidenteCompleto!.historial.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Sin historial',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_incidenteCompleto!.historial.length, (
                        index,
                      ) {
                        final historia = _incidenteCompleto!.historial[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(historia.fechaHora),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  historia.titulo ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (historia.descripcion != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    historia.descripcion!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
                    if (_incidenteCompleto!.asignaciones.isNotEmpty) ...[
                      Text(
                        'Asignaciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(
                        _incidenteCompleto!.asignaciones.length,
                        (index) {
                          final asignacion =
                              _incidenteCompleto!.asignaciones[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(
                                Icons.build,
                                color: Colors.green,
                              ),
                              title: Text('Taller #${asignacion['taller_id']}'),
                              subtitle: Text(
                                asignacion['fecha_asignacion']?.toString() ??
                                    'Sin fecha',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
