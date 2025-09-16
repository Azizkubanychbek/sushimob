import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class HybridMapScreen extends StatefulWidget {
  final LatLng initialCenter;
  final Function(LatLng coordinates, String address) onLocationSelected;

  const HybridMapScreen({
    Key? key,
    required this.initialCenter,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<HybridMapScreen> createState() => _HybridMapScreenState();
}

class _HybridMapScreenState extends State<HybridMapScreen> {
  LatLng _selectedLocation = const LatLng(42.8746, 74.5698);
  String _selectedAddress = '';
  double _distance = 0;
  bool _isDeliveryAvailable = false;
  bool _isLoading = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialCenter;
    _initializeMap();
  }

  void _initializeMap() async {
    try {
      setState(() {
        _isMapReady = true;
      });
      
      _updateLocationInfo();
    } catch (e) {
      print('❌ Ошибка инициализации карты: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка инициализации карты: $e')),
      );
    }
  }

  void _updateLocationInfo() async {
    if (!_isMapReady) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      String address = 'Адрес не определен';
      
      // Для Web используем 2GIS API
      if (kIsWeb) {
        // Для Web используем 2GIS API
        address = await _getAddressFrom2Gis(_selectedLocation);
      } else {
        // Для мобильных устройств используем geocoding
        final placemarks = await placemarkFromCoordinates(
          _selectedLocation.latitude,
          _selectedLocation.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = _formatAddress(place);
        }
      }
      
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

  String _formatAddress(Placemark place) {
    final parts = <String>[];
    
    if (place.street?.isNotEmpty == true) {
      parts.add(place.street!);
    }
    if (place.subThoroughfare?.isNotEmpty == true) {
      parts.add(place.subThoroughfare!);
    }
    if (place.thoroughfare?.isNotEmpty == true) {
      parts.add(place.thoroughfare!);
    }
    if (place.locality?.isNotEmpty == true) {
      parts.add(place.locality!);
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'Адрес не определен';
  }

  Future<String> _getAddressFrom2Gis(LatLng coordinates) async {
    try {
      final apiKey = '3f562b3d-78e5-48e4-accd-406754cb15fb';
      final url = 'https://catalog.api.2gis.com/3.0/items/geocode?'
          'lat=${coordinates.latitude}&'
          'lon=${coordinates.longitude}&'
          'key=$apiKey';
      
      final response = await HttpClient().getUrl(Uri.parse(url));
      final request = await response.close();
      final responseBody = await request.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
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

  void _onMapClick(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    _updateLocationInfo();
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
            child: _isMapReady 
              ? _buildMapWidget()
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Инициализация карты...'),
                    ],
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
                  child: Text(
                    _selectedAddress.isNotEmpty ? _selectedAddress : 'Выберите адрес на карте',
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

  Widget _buildMapWidget() {
    // Для Web используем 2GIS Web API
    if (kIsWeb) {
      return _build2GisWebMap();
    }
    
    // Для мобильных устройств используем flutter_map
    return _buildFlutterMap();
  }

  Widget _build2GisWebMap() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // 2GIS Web Map
            Container(
              width: double.infinity,
              height: double.infinity,
              child: HtmlElementView(
                viewType: '2gis-map',
                onPlatformViewCreated: (int id) {
                  _create2GisWebMap(id);
                },
              ),
            ),
            
            // Маркер центра
            Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
            
            // Индикатор загрузки
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.8),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlutterMap() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Flutter Map
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[200],
              child: const Center(
                child: Text(
                  'Карта для мобильных устройств\n(Flutter Map)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            
            // Маркер центра
            Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
            
            // Индикатор загрузки
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.8),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _create2GisWebMap(int id) {
    // Создание 2GIS Web Map через JavaScript
    // Это будет реализовано через dart:html
  }
}
