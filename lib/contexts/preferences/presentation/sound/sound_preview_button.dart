import 'package:flutter/material.dart';

import '../../../../shared/ui/public.dart' show StableContentSlot;
import 'sound_action_content.dart';

final class SoundPreviewButton extends StatelessWidget {
  const SoundPreviewButton({
    required this.isPreviewing,
    required this.previewLabel,
    required this.stopLabel,
    required this.onPreview,
    required this.onStop,
    required this.enabled,
    this.stacked = false,
    super.key,
  });

  final bool isPreviewing;
  final String previewLabel;
  final String stopLabel;
  final VoidCallback onPreview;
  final VoidCallback onStop;
  final bool enabled;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        toggled: isPreviewing,
        child: OutlinedButton(
          key: const ValueKey<String>('sound-preview-control'),
          onPressed: enabled ? (isPreviewing ? onStop : onPreview) : null,
          child: SoundActionContent(
            stacked: stacked,
            icon: isPreviewing ? Icons.stop_rounded : Icons.play_arrow_rounded,
            label: StableContentSlot(
              labels: <String>[previewLabel, stopLabel],
              alignment: Alignment.center,
              child: Text(
                isPreviewing ? stopLabel : previewLabel,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
