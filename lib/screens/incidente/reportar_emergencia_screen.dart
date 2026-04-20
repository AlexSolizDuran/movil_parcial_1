import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/incidente_service.dart';
import '../../services/auth_service.dart';

class ReportarEmergenciaScreen extends StatefulWidget {
  const ReportarEmergenciaScreen({super.key});

  @override
  State<ReportarEmergenciaScreen> createState() =>
      _ReportarEmergenciaScreenState();
}

class _ReportarEmergenciaScreenState extends State<ReportarEmergenciaScreen> {
  final IncidenteService _incidenteService = IncidenteService();
  final ImagePicker _imagePicker = ImagePicker();

  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String? _locationError;

  final TextEditingController _descripcionController = TextEditingController();
  List<XFile> _photos = [];
  List<XFile> _audioFiles = [];
  bool _isRecording = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final permission = await Permission.location.request();
      if (permission.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _locationError = 'Permiso de ubicación denegado';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Error al obtener ubicación: $e';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo != null) {
        setState(() {
          _photos.add(photo);
        });
      }
    } catch (e) {
      _showError('Error al tomar foto: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (photo != null) {
        setState(() {
          _photos.add(photo);
        });
      }
    } catch (e) {
      _showError('Error al seleccionar foto: $e');
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submitEmergency() async {
    if (_currentPosition == null) {
      _showError('Espera a obtener tu ubicación');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        _showError('No se pudo obtener información del usuario');
        setState(() => _isSubmitting = false);
        return;
      }

      final incidente = await _incidenteService.crearIncidente(
        clienteId: user.id,
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        descripcion: _descripcionController.text.isNotEmpty
            ? _descripcionController.text
            : null,
      );

      for (var photo in _photos) {
        await _incidenteService.subirEvidencia(
          incidenteId: incidente.id,
          archivo: File(photo.path),
          tipo: 'foto',
        );
      }

      if (_descripcionController.text.isNotEmpty) {
        await _incidenteService.subirEvidencia(
          incidenteId: incidente.id,
          tipo: 'texto',
          contenido: _descripcionController.text,
        );
      }

      await _incidenteService.analizarIncidente(incidente.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergencia reportada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al reportar emergencia: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : Colors.blue[700]!;

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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Ubicación Actual',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingLocation)
                      const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Obteniendo ubicación...'),
                        ],
                      )
                    else if (_locationError != null)
                      Text(
                        _locationError!,
                        style: const TextStyle(color: Colors.red),
                      )
                    else if (_currentPosition != null)
                      Text(
                        'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
                        'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _isLoadingLocation
                          ? null
                          : _getCurrentLocation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar ubicación'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Descripción del incidente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descripcionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe brevemente qué pasó...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Evidencia Fotográfica',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showPhotoOptions,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_photos.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(_photos[index].path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removePhoto(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
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
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isSubmitting ||
                        _isLoadingLocation ||
                        _currentPosition == null
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'ENVIAR EMERGENCIA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
