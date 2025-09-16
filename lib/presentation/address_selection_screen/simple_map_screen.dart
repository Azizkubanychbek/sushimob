import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';

class SimpleMapScreen extends StatefulWidget {
  final LatLng initialCenter;
  final Function(LatLng coordinates, String address) onLocationSelected;

  const SimpleMapScreen({
    Key? key,
    required this.initialCenter,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<SimpleMapScreen> createState() => _SimpleMapScreenState();
}

class _SimpleMapScreenState extends State<SimpleMapScreen> {
  LatLng _selectedLocation = const LatLng(42.8746, 74.5698);
  String _selectedAddress = '';
  double _distance = 0;
  bool _isDeliveryAvailable = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialCenter;
    _updateLocationInfo();
  }

  void _updateLocationInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String address = await _getAddressFrom2Gis(_selectedLocation);
      
      // Вычисляем расстояние до ресторана (центр Бишкека)
      const restaurantLocation = LatLng(42.8746, 74.5698);
      final distance = _calculateDistance(restaurantLocation, _selectedLocation);
      
      // Проверяем доступность доставки (15 км радиус)
      final isDeliveryAvailable = distance <= 15.0;

      setState(() {
        _selectedAddress = address;
        _distance = distance;
        _isDeliveryAvailable = isDeliveryAvailable;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Ошибка получения адреса: $e');
      setState(() {
        _selectedAddress = 'Ошибка получения адреса';
        _isLoading = false;
      });
    }
  }

  Future<String> _getAddressFrom2Gis(LatLng coordinates) async {
    try {
      final apiKey = '3f562b3d-78e5-48e4-accd-406754cb15fb';
      final url = 'https://catalog.api.2gis.com/3.0/items/geocode?'
          'lat=${coordinates.latitude}&'
          'lon=${coordinates.longitude}&'
          'key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['result'] != null && json['result'].isNotEmpty) {
          final item = json['result'][0];
          return item['address_name'] ?? 'Адрес не определен';
        }
      }
    } catch (e) {
      print('❌ Ошибка 2GIS API: $e');
    }
    
    return 'Адрес не определен';
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Радиус Земли в км
    
    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLonRad = (point2.longitude - point1.longitude) * (math.pi / 180);

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  void _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
      
      _updateLocationInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось получить текущее местоположение')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор адреса доставки'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Мое местоположение',
          ),
        ],
      ),
      body: Column(
        children: [
          // Информационная панель
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Выберите адрес на карте',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Нажмите на карту для выбора адреса',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Карта
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 13.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                      _updateLocationInfo();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.sushiroll_express',
                    ),
                    MarkerLayer(
                      markers: [
                        // Маркер ресторана
                        Marker(
                          point: const LatLng(42.8746, 74.5698),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        // Маркер выбранного места
                        Marker(
                          point: _selectedLocation,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Информация об адресе
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Выбранный адрес:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: _isLoading 
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Получение адреса...'),
                        ],
                      )
                    : Text(
                        _selectedAddress.isNotEmpty ? _selectedAddress : 'Нажмите на карту для выбора адреса',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                ),
                
                if (_distance > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        _isDeliveryAvailable ? Icons.check_circle : Icons.cancel,
                        color: _isDeliveryAvailable ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Расстояние: ${(_distance).toStringAsFixed(1)} км',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _isDeliveryAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isDeliveryAvailable 
                      ? '✅ Доставка возможна'
                      : '❌ Доставка невозможна (более 15 км)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _isDeliveryAvailable ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Кнопка выбора
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isDeliveryAvailable && _selectedAddress.isNotEmpty ? () {
                widget.onLocationSelected(_selectedLocation, _selectedAddress);
                Navigator.of(context).pop();
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDeliveryAvailable ? Colors.blue : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isDeliveryAvailable 
                  ? 'Выбрать этот адрес' 
                  : 'Выберите адрес на карте',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

