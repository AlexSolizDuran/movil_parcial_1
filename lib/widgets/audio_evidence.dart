import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AudioEvidence extends StatelessWidget {
  final List<XFile> audioFiles;
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final Function(int) onRemoveAudio;

  const AudioEvidence({
    super.key,
    required this.audioFiles,
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onRemoveAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Evidencia de Audio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isRecording)
              ElevatedButton.icon(
                onPressed: onStopRecording,
                icon: const Icon(Icons.stop),
                label: const Text('Detener'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: onStartRecording,
                icon: const Icon(Icons.mic),
                label: const Text('Grabar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (isRecording)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.red),
                SizedBox(width: 8),
                Text('Grabando...'),
              ],
            ),
          )
        else if (audioFiles.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: audioFiles.length,
              itemBuilder: (context, index) => _AudioThumbnail(
                audio: audioFiles[index],
                onRemove: () => onRemoveAudio(index),
              ),
            ),
          ),
      ],
    );
  }
}

class _AudioThumbnail extends StatelessWidget {
  final XFile audio;
  final VoidCallback onRemove;

  const _AudioThumbnail({required this.audio, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 150,
          height: 60,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(51),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.audiotrack, color: Colors.orange),
              SizedBox(width: 4),
              Text('Audio'),
            ],
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