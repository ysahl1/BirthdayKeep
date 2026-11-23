import 'package:BirthdayMarker/services/homeIntegration.dart';
import 'package:flutter/material.dart';

// Zeigt das App-Icon, das in Design gewählt ist
class AppIconImage extends StatelessWidget {
  final double size;
  const AppIconImage({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final integration = HomeIntegration.instance;
    return FutureBuilder<AppIcon>(
      future: integration.getAppIcon(),
      initialData: integration.currentAppIcon,
      builder:
          (_, icon) => Image.asset(
            (icon.data ?? AppIcon.cake).asset,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
    );
  }
}
