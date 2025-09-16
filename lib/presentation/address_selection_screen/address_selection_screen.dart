import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../../services/maps_service.dart';
import '../../models/address_info.dart';

class AddressSelectionScreen extends StatefulWidget {
  final String? initialAddress;
  final LatLng? initialCoordinates;

  const AddressSelectionScreen({
    super.key,
    this.initialAddress,
    this.initialCoordinates,
  });

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  final MapsService _mapsService = MapsService();
  YandexMapController? _mapController;
  
  AddressInfo? _selectedAddress;
  bool _isLoading = false;
  String _statusMessage = 'Выберите адрес на карте';
  
  // Координаты центра Бишкека
  static const LatLng _centerOfBishkek = LatLng(42.8746, 74.5698);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Если есть начальный адрес, получаем его координаты
      if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
        final coordinates = await _mapsService.getCoordinatesFromAddress(widget.initialAddress!);
        if (coordinates != null) {
          _selectedAddress = AddressInfo(
            coordinates: coordinates,
            address: widget.initialAddress!,
          );
          _updateMapCenter(coordinates);
        }
      } else if (widget.initialCoordinates != null) {
        final address = await _mapsService.getAddressFromCoordinates(
          widget.initialCoordinates!.latitude,
          widget.initialCoordinates!.longitude,
        );
        if (address != null) {
          _selectedAddress = AddressInfo(
            coordinates: widget.initialCoordinates!,
            address: address,
          );
        }
      } else {
        // Пытаемся получить текущее местоположение
        final currentLocation = await _mapsService.getCurrentLocation();
        if (currentLocation != null) {
          final coordinates = LatLng(currentLocation.latitude, currentLocation.longitude);
          final address = await _mapsService.getAddressFromCoordinates(
            currentLocation.latitude,
            currentLocation.longitude,
          );
          if (address != null) {
            _selectedAddress = AddressInfo(
              coordinates: coordinates,
              address: address,
            );
            _updateMapCenter(coordinates);
          }
        }
      }
    } catch (e) {
      print('❌ Ошибка инициализации карты: $e');
      _statusMessage = 'Ошибка загрузки карты';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateMapCenter(LatLng coordinates) {
    _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: coordinates, zoom: 16),
      ),
    );
  }

  void _onMapTap(Point point) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Определяем адрес...';
    });

    try {
      // Конвертируем экранные координаты в географические
      final coordinates = await _mapController?.getCameraPosition();
      final screenPoint = point;
      
      // Для простоты используем центр камеры
      // В реальном приложении нужно использовать более точный метод
      final latLng = coordinates?.target;
      
      if (latLng != null) {
        // Получаем адрес по координатам
        final address = await _mapsService.getAddressFromCoordinates(
          latLng.latitude,
          latLng.longitude,
        );

        if (address != null) {
          // Проверяем расстояние от ресторана
          final distance = _mapsService.getDistance(
            latLng,
            RestaurantLocation.coordinates,
          );

          if (distance <= RestaurantLocation.deliveryRadius) {
            setState(() {
              _selectedAddress = AddressInfo(
                coordinates: latLng,
                address: address,
                distance: distance,
              );
              _statusMessage = 'Адрес выбран';
            });
          } else {
            setState(() {
              _statusMessage = 'Доставка в этот район недоступна';
            });
          }
        } else {
          setState(() {
            _statusMessage = 'Не удалось определить адрес';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'Не удалось получить координаты';
        });
      }
    } catch (e) {
      print('❌ Ошибка выбора адреса: $e');
      setState(() {
        _statusMessage = 'Ошибка выбора адреса';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmAddress() {
    if (_selectedAddress != null) {
      Navigator.of(context).pop(_selectedAddress);
    }
  }

  void _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Определяем ваше местоположение...';
    });

    try {
      final currentLocation = await _mapsService.getCurrentLocation();
      if (currentLocation != null) {
        final coordinates = LatLng(currentLocation.latitude, currentLocation.longitude);
        final address = await _mapsService.getAddressFromCoordinates(
          currentLocation.latitude,
          currentLocation.longitude,
        );

        if (address != null) {
          final distance = _mapsService.getDistance(
            coordinates,
            RestaurantLocation.coordinates,
          );

          if (distance <= RestaurantLocation.deliveryRadius) {
            setState(() {
              _selectedAddress = AddressInfo(
                coordinates: coordinates,
                address: address,
                distance: distance,
              );
              _statusMessage = 'Адрес определен';
            });
            _updateMapCenter(coordinates);
          } else {
            setState(() {
              _statusMessage = 'Доставка в ваш район недоступна';
            });
          }
        }
      } else {
        setState(() {
          _statusMessage = 'Не удалось определить местоположение';
        });
      }
    } catch (e) {
      print('❌ Ошибка определения местоположения: $e');
      setState(() {
        _statusMessage = 'Ошибка определения местоположения';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите адрес доставки'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _useCurrentLocation,
            icon: const Icon(Icons.my_location),
            tooltip: 'Мое местоположение',
          ),
        ],
      ),
      body: Column(
        children: [
          // Статусная строка
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _selectedAddress != null ? Icons.check_circle : Icons.location_on,
                    color: _selectedAddress != null ? Colors.green : Colors.orange,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          
          // Карта
          Expanded(
            child: YandexMap(
              onMapCreated: (YandexMapController controller) {
                _mapController = controller;
              },
              onMapTap: _onMapTap,
              initialCameraPosition: CameraPosition(
                target: _selectedAddress?.coordinates ?? _centerOfBishkek,
                zoom: 16,
              ),
              mapObjects: _selectedAddress != null
                  ? [
                      _mapsService.createPlacemark(
                        point: _selectedAddress!.coordinates,
                        address: _selectedAddress!.address,
                      ),
                    ]
                  : [],
            ),
          ),
          
          // Информация об адресе
          if (_selectedAddress != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Выбранный адрес:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedAddress!.address,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_selectedAddress!.distance != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Расстояние от ресторана: ${_mapsService.formatDistance(_selectedAddress!.distance!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedAddress != null ? _confirmAddress : null,
                  child: const Text('Подтвердить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
