import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:dgis_mobile_sdk_map/dgis_mobile_sdk_map.dart';

class DgisMapScreen extends StatefulWidget {
  final LatLng initialCenter;
  final Function(LatLng coordinates, String address) onLocationSelected;

  const DgisMapScreen({
    Key? key,
    required this.initialCenter,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<DgisMapScreen> createState() => _DgisMapScreenState();
}

class _DgisMapScreenState extends State<DgisMapScreen> {
  DgisMapController? _mapController;
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
      // Инициализация 2GIS SDK
      await DgisMap.initialize(
        apiKey: '3f562b3d-78e5-48e4-accd-406754cb15fb',
      );
      
      setState(() {
        _isMapReady = true;
      });
      
      _updateLocationInfo();
    } catch (e) {
      print('❌ Ошибка инициализации 2GIS SDK: $e');
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
      // Получаем адрес через 2GIS Geocoder API
      final geocoder = Geocoder();
      final result = await geocoder.reverseGeocode(
        lat: _selectedLocation.latitude,
        lon: _selectedLocation.longitude,
      );
      
      String address = 'Адрес не определен';
      if (result.isNotEmpty && result.first.address != null) {
        address = result.first.address!;
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

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Радиус Земли в км
    
    final double lat1Rad = point1.latitude * (3.14159265359 / 180);
    final double lat2Rad = point2.latitude * (3.14159265359 / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    final double deltaLonRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    final double a = (deltaLatRad / 2).abs().sin() * (deltaLatRad / 2).abs().sin() +
        lat1Rad.cos() * lat2Rad.cos() *
        (deltaLonRad / 2).abs().sin() * (deltaLonRad / 2).abs().sin();
    final double c = 2 * a.sqrt().asin();

    return earthRadius * c;
  }

  void _onMapReady(DgisMapController controller) {
    _mapController = controller;
    
    // Добавляем маркер ресторана
    _mapController!.addMarker(
      MarkerOptions(
        position: const LatLng(42.8746, 74.5698),
        title: 'Sushi Express',
      ),
    );
    
    // Устанавливаем начальную позицию
    _mapController!.moveCamera(
      CameraUpdateOptions(
        position: _selectedLocation,
        zoom: 12.0,
      ),
    );
  }

  void _onMapClick(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    _updateLocationInfo();
  }

  void _getCurrentLocation() async {
    try {
      if (_mapController != null) {
        final position = await _mapController!.getMyLocation();
        if (position != null) {
          setState(() {
            _selectedLocation = LatLng(position.latitude, position.longitude);
          });
          _mapController!.moveCamera(
            CameraUpdateOptions(
              position: _selectedLocation,
              zoom: 15.0,
            ),
          );
          _updateLocationInfo();
        }
      }
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
          
          // Карта 2GIS
          Expanded(
            child: _isMapReady 
              ? DgisMap(
                  onMapReady: _onMapReady,
                  onMapClick: _onMapClick,
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 12.0,
                  ),
                  mapStyle: MapStyle.light,
                )
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
}