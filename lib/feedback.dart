import 'package:flutter/material.dart';

/* =========================
   Kurze Meldungen
========================= */
enum FeedbackType { success, info, error }

// Einheitliche, schwebende Meldung mit Symbol in den Farben des Designs
void showFeedback(
  BuildContext context,
  String message, {
  FeedbackType type = FeedbackType.success,
  IconData? icon,
  SnackBarAction? action,
}) {
  final colors = Theme.of(context).colorScheme;
  final accent = switch (type) {
    FeedbackType.success => colors.inversePrimary,
    FeedbackType.info => colors.onInverseSurface,
    FeedbackType.error => colors.errorContainer,
  };
  final symbol =
      icon ??
      switch (type) {
        FeedbackType.success => Icons.check_circle_rounded,
        FeedbackType.info => Icons.info_outline_rounded,
        FeedbackType.error => Icons.error_outline_rounded,
      };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colors.inverseSurface,
        elevation: 2,
        duration: Duration(seconds: action == null ? 3 : 5),
        // Mit Knopf bliebe die Meldung sonst stehen, bis man sie wegtippt
        persist: false,
        content: Row(
          children: [
            Icon(symbol, color: accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onInverseSurface),
              ),
            ),
          ],
        ),
        action: action,
      ),
    );
}
