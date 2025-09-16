import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../services/maps_service.dart';

class SimpleWebMapScreen extends StatefulWidget {
  final LatLng initialCenter;
  final Function(LatLng coordinates, String address) onLocationSelected;

  const SimpleWebMapScreen({
    Key? key,
    required this.initialCenter,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<SimpleWebMapScreen> createState() => _SimpleWebMapScreenState();
}

class _SimpleWebMapScreenState extends State<SimpleWebMapScreen> {
  late TextEditingController _addressController;
  LatLng _selectedLocation = const LatLng(42.8746, 74.5698);
  String _selectedAddress = '';
  double _distance = 0;
  bool _isDeliveryAvailable = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialCenter;
    _addressController = TextEditingController();
    _updateLocationInfo();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _updateLocationInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Получаем адрес через обычный geocoding
      String? address;
      try {
        address = await MapsService().getAddressFromCoordinates(
          _selectedLocation.latitude, 
          _selectedLocation.longitude
        );
      } catch (e) {
        print('❌ Ошибка geocoding: $e');
        address = null;
      }
      
      // Вычисляем расстояние
      final distance = MapsService.getDistance(
        RestaurantLocation.coordinates, 
        _selectedLocation
      );
      
      // Проверяем доступность доставки
      final isDeliveryAvailable = distance <= RestaurantLocation.deliveryRadius;

      // Генерируем приблизительный адрес если geocoding не сработал
      final finalAddress = address ?? _generateApproximateAddress(_selectedLocation);

      setState(() {
        _selectedAddress = finalAddress;
        _distance = distance;
        _isDeliveryAvailable = isDeliveryAvailable;
        _addressController.text = finalAddress;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Общая ошибка: $e');
      setState(() {
        _selectedAddress = 'Ошибка получения адреса';
        _addressController.text = 'Ошибка получения адреса';
        _isLoading = false;
      });
    }
  }

  void _updateLocation(double lat, double lng) {
    setState(() {
      _selectedLocation = LatLng(lat, lng);
    });
    _updateLocationInfo();
  }

  void _getCurrentLocation() async {
    try {
      final position = await MapsService().getCurrentLocation();
      if (position != null) {
        _updateLocation(position.latitude, position.longitude);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось получить текущее местоположение')),
      );
    }
  }

  String _generateApproximateAddress(LatLng coordinates) {
    // Простая генерация адреса на основе координат
    final lat = coordinates.latitude;
    final lng = coordinates.longitude;
    
    // Проверяем, находимся ли в Бишкеке
    if (lat >= 42.7 && lat <= 43.0 && lng >= 74.4 && lng <= 74.8) {
      final streetNumber = ((lat * 1000).round() % 100) + 1;
      final houseNumber = ((lng * 1000).round() % 100) + 1;
      return 'ул. Примерная, д. $houseNumber, Бишкек';
    } else {
      return 'Координаты: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
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
                  'Перемещайте карту и нажимайте на нужное место',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Карта (заглушка с координатами)
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.blue[50],
              child: Stack(
                children: [
                  // Заглушка карты
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 64,
                          color: Colors.blue[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '2ГИС Карта',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Координаты: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Кнопки для изменения координат
                        Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _updateLocation(42.8746, 74.5698),
                              icon: const Icon(Icons.restaurant),
                              label: const Text('Центр Бишкека'),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _updateLocation(42.8765, 74.5789),
                              icon: const Icon(Icons.location_on),
                              label: const Text('Другой адрес'),
                            ),
                          ],
                        ),
                      ],
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
                    _selectedAddress.isNotEmpty ? _selectedAddress : 'Определяем адрес...',
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
                        'Расстояние: ${(_distance / 1000).toStringAsFixed(1)} км',
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
              onPressed: _isDeliveryAvailable ? () {
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
                  : 'Доставка недоступна',
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
