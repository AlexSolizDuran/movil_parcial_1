import 'package:flutter/material.dart';
import '../models/vehiculo.dart';
import '../screens/vehiculos_list_screen.dart';

class VehicleSelector extends StatelessWidget {
  final List<Vehiculo> vehiculos;
  final Vehiculo? selected;
  final bool isLoading;
  final Function(Vehiculo?) onChanged;

  const VehicleSelector({
    super.key,
    required this.vehiculos,
    required this.selected,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : Colors.blue[700]!;

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
                const Text(
                  'Seleccionar Vehículo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(' *', style: TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Row(
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Cargando vehículos...'),
                ],
              )
            else if (vehiculos.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No tienes vehículos registrados', style: TextStyle(color: Colors.orange)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VehiculosListScreen()),
                    ),
                    child: const Text('Agregar Vehículo'),
                  ),
                ],
              )
            else
              DropdownButtonFormField<Vehiculo>(
                value: selected,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Selecciona un vehículo'),
                items: vehiculos.map((v) {
                  return DropdownMenuItem(
                    value: v,
                    child: Text('${v.marca} ${v.modelo} (${v.placa})'),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
          ],
        ),
      ),
    );
  }
}