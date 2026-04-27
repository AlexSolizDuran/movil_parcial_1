import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/incidente_tecnico.dart';
import '../../services/tecnico_service.dart';

class DetalleIncidenteTecnicoScreen extends StatefulWidget {
  final IncidenteTecnico incidente;
  final int tecnicoId;

  const DetalleIncidenteTecnicoScreen({
    super.key,
    required this.incidente,
    required this.tecnicoId,
  });

  @override
  State<DetalleIncidenteTecnicoScreen> createState() => _DetalleIncidenteTecnicoScreenState();
}

class _DetalleIncidenteTecnicoScreenState extends State<DetalleIncidenteTecnicoScreen> {
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : const Color(0xFF2563EB);

    return Scaffold(
      appBar: AppBar(
        title: Text('Incidente #${widget.incidente.id}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() => _error = null),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_success != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_success!, style: const TextStyle(color: Colors.green))),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.green),
                            onPressed: () => setState(() => _success = null),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildEstadoCard(primaryColor, isDark),
                  const SizedBox(height: 16),
                  if (widget.incidente.cliente != null) ...[
                    _buildClienteCard(primaryColor, isDark),
                    const SizedBox(height: 16),
                  ],
                  if (widget.incidente.vehiculo != null) ...[
                    _buildVehiculoCard(primaryColor, isDark),
                    const SizedBox(height: 16),
                  ],
                  _buildDescripcionCard(primaryColor, isDark),
                  const SizedBox(height: 16),
                  if (widget.incidente.evidencias != null && widget.incidente.evidencias!.isNotEmpty) ...[
                    _buildEvidenciasCard(primaryColor, isDark),
                    const SizedBox(height: 16),
                  ],
                  _buildAccionButtons(context, primaryColor, isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildAccionButtons(BuildContext context, Color primaryColor, bool isDark) {
    final estado = widget.incidente.estado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Acciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (estado == 'asignado')
          ElevatedButton.icon(
            onPressed: () => _cambiarEstado(context, 'en_camino'),
            icon: const Icon(Icons.directions_car),
            label: const Text('Voy en Camino'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        if (estado == 'en_camino')
          ElevatedButton.icon(
            onPressed: () => _cambiarEstado(context, 'en_sitio'),
            icon: const Icon(Icons.location_on),
            label: const Text('Llegué al Sitio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        if (estado == 'en_sitio')
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoFinalizar(context),
            icon: const Icon(Icons.check_circle),
            label: const Text('Finalizar Incidente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _mostrarDialogoCancelar(context),
          icon: const Icon(Icons.cancel),
          label: const Text('Cancelar Incidente'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _cambiarEstado(BuildContext context, String nuevoEstado) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    final tecnicoId = widget.tecnicoId;
    final resultado = await TecnicoService.actualizarEstado(tecnicoId, nuevoEstado);

    setState(() {
      _isLoading = false;
      if (resultado['success']) {
        _success = 'Estado actualizado a ${_getEstadoTexto(nuevoEstado)}';
        Navigator.pop(context, true);
      } else {
        _error = resultado['error'] ?? 'Error al actualizar estado';
      }
    });
  }

  Future<void> _mostrarDialogoFinalizar(BuildContext context) async {
    final montoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final monto = await showDialog<double>(
      context: context,
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
              const Text('Ingrese el monto del servicio:'),
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

    if (monto != null && monto > 0) {
      setState(() {
        _isLoading = true;
        _error = null;
        _success = null;
      });

      final resultado = await TecnicoService.crearPagoYFinalizar(
        widget.incidente.id,
        monto,
      );

      setState(() {
        _isLoading = false;
        if (resultado['success']) {
          _success = 'Incidente finalizado. Monto: Bs ${monto.toStringAsFixed(2)}';
          Navigator.pop(context, true);
        } else {
          _error = resultado['error'] ?? 'Error al finalizar';
        }
      });
    }
  }

  Future<void> _mostrarDialogoCancelar(BuildContext context) async {
    final motivoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Cancelar Incidente'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Está seguro de cancelar el incidente?'),
              const SizedBox(height: 16),
              const Text('Ingrese el motivo:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: motivoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ej: El cliente no estaba en casa',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el motivo';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No, mantener'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmado == true && motivoController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
        _success = null;
      });

      final tecnicoId = widget.tecnicoId;
      final resultado = await TecnicoService.cancelarIncidente(
        tecnicoId,
        motivoController.text,
      );

      setState(() {
        _isLoading = false;
        if (resultado['success']) {
          _success = 'Incidente cancelado';
          Navigator.pop(context, true);
        } else {
          _error = resultado['error'] ?? 'Error al cancelar';
        }
      });
    }
  }

  Widget _buildEstadoCard(Color primaryColor, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estado del Incidente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(widget.incidente.estado),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getEstadoTexto(widget.incidente.estado),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            if (widget.incidente.prioridad != null)
              Row(
                children: [
                  Icon(Icons.flag, size: 20, color: _getPrioridadColor(widget.incidente.prioridad!)),
                  const SizedBox(width: 8),
                  Text(
                    'Prioridad: ${widget.incidente.prioridad}',
                    style: TextStyle(
                      color: _getPrioridadColor(widget.incidente.prioridad!),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (widget.incidente.fechaCreacion != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 20, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    'Creado: ${_formatDate(widget.incidente.fechaCreacion!)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClienteCard(Color primaryColor, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Datos del Cliente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildInfoRow(Icons.person, 'Nombre', widget.incidente.cliente!.nombre),
            if (widget.incidente.cliente!.telefono != null)
              _buildInfoRow(Icons.phone, 'Teléfono', widget.incidente.cliente!.telefono!),
            if (widget.incidente.cliente!.email != null)
              _buildInfoRow(Icons.email, 'Email', widget.incidente.cliente!.email!),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiculoCard(Color primaryColor, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Vehículo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildInfoRow(Icons.directions_car, 'Vehículo',
                '${widget.incidente.vehiculo!.marca ?? ''} ${widget.incidente.vehiculo!.modelo ?? ''}'),
            _buildInfoRow(Icons.badge, 'Placa', widget.incidente.vehiculo!.patente ?? 'No registrada'),
            if (widget.incidente.vehiculo!.color != null)
              _buildInfoRow(Icons.palette, 'Color', widget.incidente.vehiculo!.color!),
          ],
        ),
      ),
    );
  }

  Widget _buildDescripcionCard(Color primaryColor, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Descripción',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            if (widget.incidente.descripcionOriginal != null) ...[
              Text(
                'Problema Reportado:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              Text(widget.incidente.descripcionOriginal!),
              const SizedBox(height: 12),
            ],
            if (widget.incidente.descripcion != null && widget.incidente.descripcion != widget.incidente.descripcionOriginal) ...[
              Text(
                'Detalles Adicionales:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              Text(widget.incidente.descripcion!),
              const SizedBox(height: 12),
            ],
            if (widget.incidente.mensajeSolicitud != null) ...[
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
                        const Icon(Icons.message, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Mensaje del Cliente:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(widget.incidente.mensajeSolicitud!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenciasCard(Color primaryColor, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Evidencias (${widget.incidente.evidencias!.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...widget.incidente.evidencias!.map((ev) => _buildEvidenciaItem(ev, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenciaItem(EvidenciaInfo evidencia, bool isDark) {
    if (evidencia.tipo == 'foto' && evidencia.urlArchivo != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Fotografía', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                evidencia.urlArchivo!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 48),
                      SizedBox(height: 8),
                      Text('Error al cargar imagen'),
                    ],
                  ),
                ),
              ),
            ),
            if (evidencia.descripcion != null) ...[
              const SizedBox(height: 4),
              Text(evidencia.descripcion!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ],
        ),
      );
    } else if (evidencia.tipo == 'texto' && evidencia.contenido != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_snippet, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Texto', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(evidencia.contenido!),
          ],
        ),
      );
    } else if (evidencia.tipo == 'audio') {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mic, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Audio', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (evidencia.descripcion != null) ...[
              const SizedBox(height: 4),
              Text(evidencia.descripcion!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
            if (evidencia.contenido != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transcripción:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(evidencia.contenido!, style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente': return Colors.orange;
      case 'asignado': return Colors.blue;
      case 'en_camino': return Colors.amber;
      case 'en_sitio': return Colors.green;
      case 'finalizado': return Colors.grey;
      case 'cancelado': return Colors.red;
      case 'sin_talleres': return Colors.purple;
      default: return Colors.blue;
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente': return 'Pendiente';
      case 'asignado': return 'Asignado';
      case 'en_camino': return 'En Camino';
      case 'en_sitio': return 'En Sitio';
      case 'finalizado': return 'Finalizado';
      case 'cancelado': return 'Cancelado';
      case 'sin_talleres': return 'Sin Talleres';
      default: return estado;
    }
  }

  Color _getPrioridadColor(String prioridad) {
    switch (prioridad.toLowerCase()) {
      case 'alta': case 'urgente': return Colors.red;
      case 'media': return Colors.orange;
      case 'baja': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}