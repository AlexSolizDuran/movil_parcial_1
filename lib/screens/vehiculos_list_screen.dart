import 'package:flutter/material.dart';
import '../models/vehiculo.dart';
import '../services/vehiculo_service.dart';
import 'vehiculo_form_screen.dart';

class VehiculosListScreen extends StatefulWidget {
  const VehiculosListScreen({super.key});

  @override
  State<VehiculosListScreen> createState() => _VehiculosListScreenState();
}

class _VehiculosListScreenState extends State<VehiculosListScreen> {
  List<Vehiculo> _vehiculos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehiculos();
  }

  Future<void> _loadVehiculos() async {
    setState(() => _isLoading = true);
    final vehiculos = await VehiculoService.getMisVehiculos();
    if (mounted) {
      setState(() {
        _vehiculos = vehiculos;
        _isLoading = false;
      });
    }
  }

  Future<void> _eliminarVehiculo(Vehiculo vehiculo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: Text('¿Estás seguro de eliminar el vehículo con placa ${vehiculo.placa}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await VehiculoService.eliminarVehiculo(vehiculo.id);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehículo eliminado'),
              backgroundColor: Colors.green,
            ),
          );
          _loadVehiculos();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : Colors.blue[700]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Vehículos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVehiculos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehiculos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 80,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes vehículos registrados',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega tu primer vehículo',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadVehiculos,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vehiculos.length,
                    itemBuilder: (context, index) {
                      final vehiculo = _vehiculos[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: primaryColor,
                            ),
                          ),
                          title: Text(
                            vehiculo.placa,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${vehiculo.marca} ${vehiculo.modelo}${vehiculo.color != null ? ' - ${vehiculo.color}' : ''}',
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => VehiculoFormScreen(
                                      vehiculo: vehiculo,
                                      onSave: _loadVehiculos,
                                    ),
                                  ),
                                );
                              } else if (value == 'delete') {
                                _eliminarVehiculo(vehiculo);
                              }
                            },
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => VehiculoFormScreen(
                                  vehiculo: vehiculo,
                                  onSave: _loadVehiculos,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VehiculoFormScreen(
                onSave: _loadVehiculos,
              ),
            ),
          );
        },
        backgroundColor: primaryColor,
        foregroundColor: isDark ? Colors.black : Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
