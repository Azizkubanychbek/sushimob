import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/maps_service.dart';

class SimpleAddressSelectionScreen extends StatefulWidget {
  final String? initialAddress;

  const SimpleAddressSelectionScreen({
    super.key,
    this.initialAddress,
  });

  @override
  State<SimpleAddressSelectionScreen> createState() => _SimpleAddressSelectionScreenState();
}

class _SimpleAddressSelectionScreenState extends State<SimpleAddressSelectionScreen> {
  final MapsService _mapsService = MapsService();
  final TextEditingController _addressController = TextEditingController();
  
  AddressInfo? _selectedAddress;
  bool _isLoading = false;
  String _statusMessage = 'Введите адрес или используйте ваше местоположение';

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _addressController.text = widget.initialAddress!;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
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
              _addressController.text = address;
              _statusMessage = 'Адрес определен по местоположению';
            });
          } else {
            setState(() {
              _statusMessage = 'Доставка в ваш район недоступна (${_mapsService.formatDistance(distance)})';
            });
          }
        } else {
          setState(() {
            _statusMessage = 'Не удалось определить адрес по местоположению';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'Не удалось получить ваше местоположение';
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

  Future<void> _searchAddress() async {
    if (_addressController.text.trim().isEmpty) {
      setState(() {
        _statusMessage = 'Введите адрес для поиска';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Ищем адрес...';
    });

    try {
      final coordinates = await _mapsService.getCoordinatesFromAddress(_addressController.text.trim());
      if (coordinates != null) {
        final distance = _mapsService.getDistance(
          coordinates,
          RestaurantLocation.coordinates,
        );

        if (distance <= RestaurantLocation.deliveryRadius) {
          setState(() {
            _selectedAddress = AddressInfo(
              coordinates: coordinates,
              address: _addressController.text.trim(),
              distance: distance,
            );
            _statusMessage = 'Адрес найден и подтвержден';
          });
        } else {
          setState(() {
            _statusMessage = 'Доставка в этот район недоступна (${_mapsService.formatDistance(distance)})';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'Адрес не найден, попробуйте другой';
        });
      }
    } catch (e) {
      print('❌ Ошибка поиска адреса: $e');
      setState(() {
        _statusMessage = 'Ошибка поиска адреса';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите адрес доставки'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _getCurrentLocation,
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
          
          // Форма ввода адреса
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Адрес доставки',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: 'ул. Чуй, д. 123, кв. 45, Бишкек',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: _searchAddress,
                      icon: const Icon(Icons.search),
                      tooltip: 'Найти адрес',
                    ),
                  ),
                  maxLines: 2,
                  onChanged: (value) {
                    // Сбрасываем выбранный адрес при изменении текста
                    if (_selectedAddress != null) {
                      setState(() {
                        _selectedAddress = null;
                        _statusMessage = 'Введите адрес или используйте ваше местоположение';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Использовать мое местоположение'),
                  ),
                ),
              ],
            ),
          ),
          
          // Информация о ресторане
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Наш ресторан',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  RestaurantLocation.address,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Радиус доставки: ${_mapsService.formatDistance(RestaurantLocation.deliveryRadius)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Информация о выбранном адресе
          if (_selectedAddress != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Выбранный адрес',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
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
          
          const Spacer(),
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
