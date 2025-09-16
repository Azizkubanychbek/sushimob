import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/maps_service.dart';

class InteractiveMapScreen extends StatefulWidget {
  final Function(AddressInfo) onAddressSelected;

  const InteractiveMapScreen({
    super.key,
    required this.onAddressSelected,
  });

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  final MapsService _mapsService = MapsService();
  final MapController _mapController = MapController();
  
  LatLng _currentCenter = const LatLng(42.8746, 74.5698); // Центр Бишкека
  String _currentAddress = '';
  double? _distance;
  bool _isLoading = false;
  bool _isDeliveryAvailable = false;

  @override
  void initState() {
    super.initState();
    _updateAddressFromCenter();
  }

  Future<void> _updateAddressFromCenter() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Получаем адрес по текущему центру карты
      final address = await _mapsService.getAddressFromCoordinates(
        _currentCenter.latitude,
        _currentCenter.longitude,
      );

      if (address != null && address.isNotEmpty) {
        setState(() {
          _currentAddress = address;
        });
      } else {
        setState(() {
          _currentAddress = 'Адрес не определен';
        });
      }

      // Проверяем доступность доставки
      try {
        final distance = MapsService.getDistance(
          _currentCenter,
          RestaurantLocation.coordinates,
        );

        setState(() {
          _distance = distance;
          _isDeliveryAvailable = distance <= RestaurantLocation.deliveryRadius;
        });
      } catch (e) {
        print('❌ Ошибка расчета расстояния: $e');
        setState(() {
          _distance = null;
          _isDeliveryAvailable = false;
        });
      }

    } catch (e) {
      print('❌ Ошибка получения адреса: $e');
      setState(() {
        _currentAddress = 'Адрес не найден';
        _isDeliveryAvailable = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapMoved() {
    // Обновляем центр карты при перемещении
    final newCenter = _mapController.camera?.center;
    if (newCenter != null) {
      setState(() {
        _currentCenter = LatLng(newCenter.latitude, newCenter.longitude);
      });
      
      // Добавляем задержку, чтобы не делать слишком много запросов
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _currentCenter == LatLng(newCenter.latitude, newCenter.longitude)) {
          _updateAddressFromCenter();
        }
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final location = await _mapsService.getCurrentLocation();
      if (location != null) {
        final newCenter = LatLng(location.latitude, location.longitude);
        _mapController.move(newCenter, 15.0);
        
        setState(() {
          _currentCenter = newCenter;
        });
        _updateAddressFromCenter();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка получения местоположения: $e')),
      );
    }
  }

  void _selectAddress() {
    if (_isDeliveryAvailable) {
      final addressInfo = AddressInfo(
        coordinates: _currentCenter,
        address: _currentAddress,
        distance: _distance,
      );
      widget.onAddressSelected(addressInfo);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Доставка в этот район недоступна'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите адрес доставки'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _goToCurrentLocation,
            icon: const Icon(Icons.my_location),
            tooltip: 'Мое местоположение',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Карта
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              onMapEvent: (MapEvent mapEvent) {
                if (mapEvent is MapEventMove) {
                  _onMapMoved();
                }
              },
            ),
            children: [
              // Слой тайлов карты
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sushiroll_express',
              ),
              
              // Маркер ресторана
              MarkerLayer(
                markers: [
                  Marker(
                    point: RestaurantLocation.coordinates,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Центральная точка выбора
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentCenter,
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Информационная панель внизу
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Индикатор загрузки
                  if (_isLoading)
                    const LinearProgressIndicator(),
                  
                  const SizedBox(height: 16),
                  
                  // Адрес
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentAddress,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Расстояние и статус доставки
                  Row(
                    children: [
                      Icon(
                        _isDeliveryAvailable ? Icons.check_circle : Icons.cancel,
                        color: _isDeliveryAvailable ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _distance != null 
                          ? 'Расстояние: ${(_distance! / 1000).toStringAsFixed(1)} км'
                          : 'Расстояние: неизвестно',
                        style: TextStyle(
                          color: _isDeliveryAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Кнопка выбора адреса
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isDeliveryAvailable && !_isLoading ? _selectAddress : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isDeliveryAvailable ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isDeliveryAvailable 
                          ? 'Выбрать этот адрес'
                          : 'Доставка недоступна',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Инструкция
                  Text(
                    'Перемещайте карту так, чтобы синяя точка была над нужным адресом',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
