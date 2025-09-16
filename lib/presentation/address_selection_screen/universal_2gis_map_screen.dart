import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:latlong2/latlong.dart';

// Импорты для разных платформ
import 'free_map_screen.dart';

class Universal2GisMapScreen extends StatelessWidget {
  final LatLng initialCenter;
  final Function(LatLng coordinates, String address) onLocationSelected;

  const Universal2GisMapScreen({
    Key? key,
    required this.initialCenter,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Используем бесплатную карту OpenStreetMap для всех платформ
    return FreeMapScreen(
      initialCenter: initialCenter,
      onLocationSelected: onLocationSelected,
    );
  }
}
