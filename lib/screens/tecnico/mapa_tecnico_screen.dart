import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/incidente_tecnico.dart';
import '../../services/tecnico_service.dart';

class MapaTecnicoScreen extends StatefulWidget {
  final IncidenteTecnico incidente;

  const MapaTecnicoScreen({
    super.key,
    required this.incidente,
  });

  @override
  State<MapaTecnicoScreen> createState() => _MapaTecnicoScreenState();
}

class _MapaTecnicoScreenState extends State<MapaTecnicoScreen> {
  final MapController _mapController = MapController();
  Position? _posicionActual;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Servicios de ubicación desactivados';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Permiso de ubicación denegado';
          });
          return;
        }
      }

      _posicionActual = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_posicionActual != null && mounted) {
        await TecnicoService.actualizarUbicacion(
          widget.incidente.id,
          _posicionActual!.latitude,
          _posicionActual!.longitude,
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al obtener ubicación';
      });
    }
  }

  LatLng _getClienteUbicacion() {
    return LatLng(
      widget.incidente.ubicacionLat ?? 0.0,
      widget.incidente.ubicacionLng ?? 0.0,
    );
  }

  LatLng? _getTecnicoUbicacion() {
    if (_posicionActual == null) return null;
    return LatLng(
      _posicionActual!.latitude,
      _posicionActual!.longitude,
    );
  }

  LatLng _getCentro() {
    final cliente = _getClienteUbicacion();
    final tecnico = _getTecnicoUbicacion();

    if (tecnico == null) return cliente;

    return LatLng(
      (cliente.latitude + tecnico.latitude) / 2,
      (cliente.longitude + tecnico.longitude) / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : const Color(0xFF2563EB);

    final clienteUbicacion = _getClienteUbicacion();
    final tecnicoUbicacion = _getTecnicoUbicacion();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map, color: primaryColor),
            const SizedBox(width: 8),
            const Text('Ubicación del Cliente'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Obteniendo ubicación...',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _getCentro(),
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.auxia.movil',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: clienteUbicacion,
                          width: 50,
                          height: 50,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withAlpha(102),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (tecnicoUbicacion != null)
                          Marker(
                            point: tecnicoUbicacion,
                            width: 50,
                            height: 50,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withAlpha(102),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.directions_car,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (tecnicoUbicacion != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [tecnicoUbicacion, clienteUbicacion],
                            color: Colors.grey,
                            strokeWidth: 3,
                            isDotted: true,
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.location_on, color: Colors.red),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Ubicación del cliente',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                widget.incidente.direccion ?? 'Ubicación del incidente',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.directions_car, color: primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'location',
        onPressed: _obtenerUbicacion,
        backgroundColor: primaryColor,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}