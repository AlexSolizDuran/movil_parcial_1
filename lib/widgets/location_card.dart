import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationCard extends StatelessWidget {
  final Position? position;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;

  const LocationCard({
    super.key,
    this.position,
    required this.isLoading,
    this.error,
    required this.onRefresh,
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
                Icon(Icons.location_on, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Ubicación Actual',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Row(
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Obteniendo ubicación...'),
                ],
              )
            else if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red))
            else if (position != null)
              Text(
                'Lat: ${position!.latitude.toStringAsFixed(6)}\n'
                'Lng: ${position!.longitude.toStringAsFixed(6)}',
                style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: isLoading ? null : onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar ubicación'),
            ),
          ],
        ),
      ),
    );
  }
}