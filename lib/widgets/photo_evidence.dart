import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoEvidence extends StatelessWidget {
  final List<XFile> photos;
  final VoidCallback onAddPhoto;
  final Function(int) onRemovePhoto;

  const PhotoEvidence({
    super.key,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final primaryColor = isDark ? Colors.amber : Colors.blue[700]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: onAddPhoto,
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
        if (photos.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) => _PhotoThumbnail(
                photo: photos[index],
                onRemove: () => onRemovePhoto(index),
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final XFile photo;
  final VoidCallback onRemove;

  const _PhotoThumbnail({required this.photo, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(File(photo.path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 12,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}