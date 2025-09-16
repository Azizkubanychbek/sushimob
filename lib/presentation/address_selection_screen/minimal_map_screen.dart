import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MinimalMapScreen extends StatefulWidget {
  final LatLng initialCenter;
  final Function(LatLng coordinates, String address) onLocationSelected;

  const MinimalMapScreen({
    Key? key,
    required this.initialCenter,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<MinimalMapScreen> createState() => _MinimalMapScreenState();
}

class _MinimalMapScreenState extends State<MinimalMapScreen> {
  LatLng _selectedLocation = const LatLng(42.8746, 74.5698);
  String _selectedAddress = 'Адрес не выбран';
  double _distance = 0;
  bool _isDeliveryAvailable = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialCenter;
    _calculateDistance();
  }

  void _calculateDistance() {
    // Вычисляем расстояние до ресторана (центр Бишкека)
    const restaurantLocation = LatLng(42.8746, 74.5698);
    final distance = _calculateDistanceBetween(restaurantLocation, _selectedLocation);
    
    // Проверяем доступность доставки (15 км радиус)
    final isDeliveryAvailable = distance <= 15.0;

    setState(() {
      _distance = distance;
      _isDeliveryAvailable = isDeliveryAvailable;
    });
  }

  double _calculateDistanceBetween(LatLng point1, LatLng point2) {
    // Простой расчет расстояния (примерный)
    final latDiff = (point1.latitude - point2.latitude).abs();
    final lonDiff = (point1.longitude - point2.longitude).abs();
    return (latDiff + lonDiff) * 111.0; // Примерно 111 км на градус
  }

  void _updateCoordinates() {
    final latitudeController = TextEditingController(text: _selectedLocation.latitude.toString());
    final longitudeController = TextEditingController(text: _selectedLocation.longitude.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Введите координаты'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latitudeController,
              decoration: const InputDecoration(
                labelText: 'Широта',
                hintText: '42.8746',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: longitudeController,
              decoration: const InputDecoration(
                labelText: 'Долгота',
                hintText: '74.5698',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final lat = double.parse(latitudeController.text);
                final lon = double.parse(longitudeController.text);
                setState(() {
                  _selectedLocation = LatLng(lat, lon);
                  _selectedAddress = 'Координаты: ${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
                });
                Navigator.of(context).pop();
                _calculateDistance();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Некорректные координаты')),
                );
              }
            },
            child: const Text('Обновить'),
          ),
        ],
      ),
    );
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
            icon: const Icon(Icons.edit_location),
            onPressed: _updateCoordinates,
            tooltip: 'Изменить координаты',
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
                  'Минимальная версия карты',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Нажмите кнопку для изменения координат',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Заглушка карты
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[100],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.map,
                        size: 64,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Минимальная карта',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Текущие координаты:\n${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _updateCoordinates,
                        icon: const Icon(Icons.edit_location),
                        label: const Text('Изменить координаты'),
                      ),
                    ],
                  ),
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
                  child: Text(
                    _selectedAddress,
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
                  : 'Выберите координаты в зоне доставки',
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

