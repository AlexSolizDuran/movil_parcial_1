import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/incidente_service.dart';
import '../../services/auth_service.dart';
import '../../services/vehiculo_service.dart';
import '../../models/vehiculo.dart';
import '../../widgets/location_card.dart';
import '../../widgets/vehicle_selector.dart';
import '../../widgets/photo_evidence.dart';

class ReportarEmergenciaScreen extends StatefulWidget {
  const ReportarEmergenciaScreen({super.key});

  @override
  State<ReportarEmergenciaScreen> createState() => _ReportarEmergenciaScreenState();
}

class _ReportarEmergenciaScreenState extends State<ReportarEmergenciaScreen> {
  final IncidenteService _incidenteService = IncidenteService();
  final ImagePicker _imagePicker = ImagePicker();

  Position? _position;
  bool _isLoadingLocation = false;
  String? _locationError;

  final TextEditingController _descripcionController = TextEditingController();
  List<XFile> _photos = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechEnabled = false;

  List<Vehiculo> _vehiculos = [];
  Vehiculo? _vehiculoSeleccionado;
  bool _isLoadingVehiculos = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _cargarVehiculos();
    _initSpeech();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        if (kDebugMode) print('Speech status: $status');
      },
      onError: (error) {
        if (kDebugMode) print('Speech error: $error');
      },
    );
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechEnabled) {
      _showError('Reconocimiento de voz no disponible');
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _descripcionController.text = result.recognizedWords;
            _descripcionController.selection = TextSelection.fromPosition(
              TextPosition(offset: _descripcionController.text.length),
            );
          });
        },
        localeId: 'es_ES',
      );
    }
  }

  Future<void> _cargarVehiculos() async {
    setState(() => _isLoadingVehiculos = true);
    final vehiculos = await VehiculoService.getMisVehiculos();
    setState(() {
      _vehiculos = vehiculos;
      _isLoadingVehiculos = false;
      if (vehiculos.isNotEmpty) _vehiculoSeleccionado = vehiculos.first;
    });
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    final permission = await Permission.location.request();
    if (!permission.isGranted) {
      setState(() {
        _locationError = 'Permiso de ubicación denegado';
        _isLoadingLocation = false;
      });
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _position = pos;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Error al obtener ubicación: $e';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final photo = await _imagePicker.pickImage(source: source, imageQuality: 80);
    if (photo != null) setState(() => _photos.add(photo));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submitEmergency() async {
    if (_position == null) return _showError('Espera a obtener tu ubicación');
    if (_vehiculoSeleccionado == null) return _showError('Selecciona un vehículo');

    setState(() => _isSubmitting = true);

    final user = await AuthService.getCurrentUser();
    if (user == null) {
      setState(() => _isSubmitting = false);
      return _showError('No se pudo obtener información del usuario');
    }

    try {
      final incidente = await _incidenteService.crearIncidente(
        clienteId: user.id,
        vehiculoId: _vehiculoSeleccionado!.id,
        lat: _position!.latitude,
        lng: _position!.longitude,
        descripcion: _descripcionController.text.isNotEmpty ? _descripcionController.text : null,
      );

      for (final photo in _photos) {
        await _incidenteService.subirEvidencia(
          incidenteId: incidente.id,
          archivo: File(photo.path),
          tipo: 'foto',
        );
      }

      await _incidenteService.analizarIncidente(incidente.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergencia reportada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al reportar emergencia: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Emergencia'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocationCard(
              position: _position,
              isLoading: _isLoadingLocation,
              error: _locationError,
              onRefresh: _getLocation,
            ),
            const SizedBox(height: 16),
            VehicleSelector(
              vehiculos: _vehiculos,
              selected: _vehiculoSeleccionado,
              isLoading: _isLoadingVehiculos,
              onChanged: (v) => setState(() => _vehiculoSeleccionado = v),
            ),
            const SizedBox(height: 16),
            Text(
              'Descripción del incidente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _descripcionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: _isListening 
                          ? 'Escuchando...' 
                          : 'Describe brevemente qué pasó...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      onPressed: _speechEnabled ? _toggleListening : null,
                      icon: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: _isListening ? Colors.red : Colors.blue,
                      ),
                      tooltip: _isListening ? 'Detener' : 'Dictar texto',
                    ),
                    if (_isListening)
                      const Text(
                        'Escuchando...',
                        style: TextStyle(fontSize: 10, color: Colors.red),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            PhotoEvidence(
              photos: _photos,
              onAddPhoto: _addPhoto,
              onRemovePhoto: (i) => setState(() => _photos.removeAt(i)),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting || _position == null || _vehiculoSeleccionado == null
                    ? null
                    : _submitEmergency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'ENVIAR EMERGENCIA',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}