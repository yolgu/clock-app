import 'package:flutter/material.dart';

final class SoundPreviewButton extends StatelessWidget {
  const SoundPreviewButton({
    required this.isPreviewing,
    required this.previewLabel,
    required this.stopLabel,
    required this.onPreview,
    required this.onStop,
    required this.enabled,
    super.key,
  });

  final bool isPreviewing;
  final String previewLabel;
  final String stopLabel;
  final VoidCallback onPreview;
  final VoidCallback onStop;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const ValueKey<String>('sound-preview-control'),
      onPressed: enabled ? (isPreviewing ? onStop : onPreview) : null,
      icon: Icon(isPreviewing ? Icons.stop_rounded : Icons.play_arrow_rounded),
      label: Text(isPreviewing ? stopLabel : previewLabel),
    );
  }
}
