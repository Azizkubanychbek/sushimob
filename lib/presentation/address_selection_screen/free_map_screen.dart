import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;

class FreeMapScreen extends StatefulWidget {
  final LatLng initialCenter;
  final Function(LatLng coordinates, String address) onLocationSelected;

  const FreeMapScreen({
    Key? key,
    required this.initialCenter,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<FreeMapScreen> createState() => _FreeMapScreenState();
}

class _FreeMapScreenState extends State<FreeMapScreen> {
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(42.8746, 74.5698);
  String _selectedAddress = '';
  double _straightDistance = 0;
  bool _isDeliveryAvailable = false;
  bool _isLoading = false;

  // Ресторан координаты (Бишкек)
  static const LatLng _restaurantLocation = LatLng(42.8746, 74.5698);
  
  // Маркеры
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialCenter;
    _initializeMarkers();
    _updateLocationInfo();
    _getAddressFromCoordinates(_selectedLocation);
    
    // Добавляем слушатель движения карты
    _mapController.mapEventStream.listen(_onMapMove);
  }

  void _initializeMarkers() {
    setState(() {
      _markers = [
        // Маркер ресторана
        Marker(
          point: _restaurantLocation,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.restaurant,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ];
    });
  }

  void _updateLocationInfo() {
    // Рассчитываем расстояние по прямой
    _straightDistance = _calculateStraightDistance(_restaurantLocation, _selectedLocation);
    
    // Проверяем доступность доставки (до 15 км)
    _isDeliveryAvailable = _straightDistance <= 15.0;
    
    setState(() {});
  }

  double _calculateStraightDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Радиус Земли в км
    
    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLngRad = (point2.longitude - point1.longitude) * (math.pi / 180);

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  Future<void> _getAddressFromCoordinates(LatLng coordinates) async {
    try {
      // Проверяем координаты на валидность
      if (coordinates.latitude == 0.0 && coordinates.longitude == 0.0) {
        setState(() {
          _selectedAddress = 'Координаты не определены';
        });
        return;
      }

      // Используем Nominatim API (OpenStreetMap) для получения адреса
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${coordinates.latitude}&lon=${coordinates.longitude}&addressdetails=1&accept-language=ru'
        ),
        headers: {
          'User-Agent': 'SushiRollExpress/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['display_name'] != null) {
          // Формируем красивый адрес из данных Nominatim
          final address = _formatNominatimAddress(data);
          setState(() {
            _selectedAddress = address;
          });
        } else {
          setState(() {
            _selectedAddress = 'Адрес не найден';
          });
        }
      } else {
        setState(() {
          _selectedAddress = 'Ошибка получения адреса';
        });
      }
    } catch (e) {
      print('❌ Ошибка получения адреса: $e');
      setState(() {
        _selectedAddress = 'Ошибка определения адреса';
      });
    }
  }

  String _formatNominatimAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) return 'Адрес не определен';

    final addressParts = <String>[];

    // Собираем адрес в правильном порядке
    if (address['house_number'] != null && address['road'] != null) {
      addressParts.add('${address['road']}, ${address['house_number']}');
    } else if (address['road'] != null) {
      addressParts.add(address['road']);
    }

    if (address['suburb'] != null) {
      addressParts.add(address['suburb']);
    } else if (address['quarter'] != null) {
      addressParts.add(address['quarter']);
    }

    if (address['city'] != null) {
      addressParts.add(address['city']);
    } else if (address['town'] != null) {
      addressParts.add(address['town']);
    } else if (address['village'] != null) {
      addressParts.add(address['village']);
    }

    if (addressParts.isEmpty) {
      // Если ничего не нашли, берем display_name
      return data['display_name'] ?? 'Адрес не определен';
    }

    return addressParts.join(', ');
  }

  void _onMapMove(MapEvent event) {
    // Обрабатываем только события окончания движения
    if (event is MapEventMoveEnd) {
      // Получаем центр карты при движении
      final center = event.camera.center;
      setState(() {
        _selectedLocation = center;
      });
      
      // Обновляем информацию
      _updateLocationInfo();
      
      // Получаем адрес для центра карты
      _getAddressFromCoordinates(center);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final newLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = newLocation;
      });
      
      // Обновляем маркеры
      _initializeMarkers();
      
      // Перемещаем карту
      _mapController.move(newLocation, 15.0);
      
      // Обновляем информацию
      _updateLocationInfo();
      
      // Получаем адрес для текущего местоположения
      _getAddressFromCoordinates(newLocation);
      
    } catch (e) {
      print('❌ Ошибка получения местоположения: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось получить текущее местоположение'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectAddress() {
    widget.onLocationSelected(_selectedLocation, _selectedAddress);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор адреса доставки'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _isLoading ? null : _getCurrentLocation,
            tooltip: 'Мое местоположение',
          ),
        ],
      ),
      body: Column(
        children: [
          // Информационная панель
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OpenStreetMap - Выбор адреса доставки',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Двигайте карту так, чтобы синий маркер по центру указывал на нужный адрес. Красный маркер - ресторан.',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Карта
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 13.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    // Плитки карты
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.sushiroll_express.app',
                      maxZoom: 18,
                    ),
                    
                    // Маркеры
                    MarkerLayer(markers: _markers),
                    
                    // Линия между рестораном и выбранным местом
                    if (_selectedLocation != _restaurantLocation)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_restaurantLocation, _selectedLocation],
                            color: Colors.orange,
                            strokeWidth: 3.0,
                          ),
                        ],
                      ),
                  ],
                ),
                
                // Центральный маркер для выбора адреса
                Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Информация о выбранном адресе
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Выбранный адрес:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedAddress,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                
                // Информация о расстоянии и доставке
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Расстояние: ${_straightDistance.toStringAsFixed(2)} км',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isDeliveryAvailable ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isDeliveryAvailable ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: _isDeliveryAvailable ? Colors.green[700] : Colors.red[700],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _isDeliveryAvailable ? 'Доставка доступна' : 'Доставка недоступна',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isDeliveryAvailable ? Colors.green[700] : Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Кнопка выбора адреса
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Выбрать этот адрес',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
