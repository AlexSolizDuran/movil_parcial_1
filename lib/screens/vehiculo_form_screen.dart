import 'package:flutter/material.dart';
import '../models/vehiculo.dart';
import '../services/vehiculo_service.dart';

class VehiculoFormScreen extends StatefulWidget {
  final Vehiculo? vehiculo;
  final VoidCallback onSave;

  const VehiculoFormScreen({
    super.key,
    this.vehiculo,
    required this.onSave,
  });

  @override
  State<VehiculoFormScreen> createState() => _VehiculoFormScreenState();
}

class _VehiculoFormScreenState extends State<VehiculoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _placaController;
  late TextEditingController _modeloController;
  late TextEditingController _marcaController;
  late TextEditingController _colorController;
  bool _isLoading = false;

  bool get _isEditing => widget.vehiculo != null;

  @override
  void initState() {
    super.initState();
    _placaController = TextEditingController(text: widget.vehiculo?.placa ?? '');
    _modeloController = TextEditingController(text: widget.vehiculo?.modelo ?? '');
    _marcaController = TextEditingController(text: widget.vehiculo?.marca ?? '');
    _colorController = TextEditingController(text: widget.vehiculo?.color ?? '');
  }

  @override
  void dispose() {
    _placaController.dispose();
    _modeloController.dispose();
    _marcaController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, dynamic> result;

    if (_isEditing) {
      final update = VehiculoUpdate(
        placa: _placaController.text.trim(),
        modelo: _modeloController.text.trim(),
        marca: _marcaController.text.trim(),
        color: _colorController.text.trim().isNotEmpty
            ? _colorController.text.trim()
            : null,
      );
      result = await VehiculoService.actualizarVehiculo(widget.vehiculo!.id, update);
    } else {
      final create = VehiculoCreate(
        placa: _placaController.text.trim(),
        modelo: _modeloController.text.trim(),
        marca: _marcaController.text.trim(),
        color: _colorController.text.trim().isNotEmpty
            ? _colorController.text.trim()
            : null,
      );
      result = await VehiculoService.crearVehiculo(create);
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Vehículo actualizado' : 'Vehículo agregado'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onSave();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : Colors.blue[700]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Vehículo' : 'Agregar Vehículo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.directions_car,
                  size: 60,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _placaController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Placa *',
                  hintText: 'Ej: ABC-123',
                  prefixIcon: const Icon(Icons.confirmation_number),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa la placa del vehículo';
                  }
                  if (value.length < 4) {
                    return 'La placa debe tener al menos 4 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _marcaController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Marca *',
                  hintText: 'Ej: Toyota, Honda, Ford',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa la marca del vehículo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modeloController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Modelo *',
                  hintText: 'Ej: Corolla, Civic, Mustang',
                  prefixIcon: const Icon(Icons.car_repair),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el modelo del vehículo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _colorController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Color (opcional)',
                  hintText: 'Ej: Rojo, Azul, Negro',
                  prefixIcon: const Icon(Icons.palette),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isEditing ? 'Actualizar' : 'Agregar Vehículo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
