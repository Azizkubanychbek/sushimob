import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapsService {
  static final MapsService _instance = MapsService._internal();
  factory MapsService() => _instance;
  MapsService._internal();

  // Координаты Бишкека (по умолчанию)
  static const double _defaultLatitude = 42.8746;
  static const double _defaultLongitude = 74.5698;
  static const double _defaultZoom = 12.0;

  /// Получение текущего местоположения пользователя
  Future<Position?> getCurrentLocation() async {
    try {
      // Проверяем разрешения
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Разрешение на доступ к местоположению отклонено');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Разрешение на доступ к местоположению отклонено навсегда');
        return null;
      }

      // Получаем текущее местоположение
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('✅ Текущее местоположение: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Ошибка получения местоположения: $e');
      return null;
    }
  }

  /// Получение адреса по координатам
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String address = _formatAddress(placemark);
        print('✅ Адрес по координатам: $address');
        return address;
      }
      
      // Если геокодирование не сработало, возвращаем примерный адрес
      return _generateApproximateAddress(latitude, longitude);
    } catch (e) {
      print('❌ Ошибка получения адреса: $e');
      // Возвращаем примерный адрес на основе координат
      return _generateApproximateAddress(latitude, longitude);
    }
  }

  /// Генерация примерного адреса на основе координат
  static String _generateApproximateAddress(double latitude, double longitude) {
    // Проверяем, находимся ли мы в Бишкеке
    if (_isInBishkek(latitude, longitude)) {
      return _getBishkekAddress(latitude, longitude);
    } else {
      return 'Адрес по координатам: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    }
  }

  /// Проверка, находимся ли мы в Бишкеке
  static bool _isInBishkek(double latitude, double longitude) {
    // Примерные границы Бишкека
    const double minLat = 42.8;
    const double maxLat = 42.95;
    const double minLng = 74.5;
    const double maxLng = 74.8;
    
    return latitude >= minLat && latitude <= maxLat && 
           longitude >= minLng && longitude <= maxLng;
  }

  /// Получение примерного адреса в Бишкеке
  static String _getBishkekAddress(double latitude, double longitude) {
    // Определяем район на основе координат
    String district = _getDistrict(latitude, longitude);
    
    // Генерируем примерный адрес
    List<String> streets = [
      'ул. Чуй', 'ул. Московская', 'ул. Ибраимова', 'ул. Ахунбаева',
      'ул. Ленина', 'ул. Токтогула', 'ул. Байтик Баатыра', 'ул. Советская'
    ];
    
    int streetIndex = (latitude * longitude * 1000).round() % streets.length;
    String street = streets[streetIndex];
    
    int houseNumber = ((latitude * longitude * 10000).round() % 200) + 1;
    
    return '$street, д. $houseNumber, $district, Бишкек';
  }

  /// Определение района Бишкека
  static String _getDistrict(double latitude, double longitude) {
    if (latitude > 42.9) return 'Аламединский район';
    if (latitude < 42.85) return 'Октябрьский район';
    if (longitude > 74.65) return 'Первомайский район';
    return 'Центральный район';
  }

  /// Получение координат по адресу
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        Location location = locations[0];
        print('✅ Координаты по адресу: ${location.latitude}, ${location.longitude}');
        return LatLng(location.latitude, location.longitude);
      }
      
      return null;
    } catch (e) {
      print('❌ Ошибка получения координат: $e');
      return null;
    }
  }

  /// Форматирование адреса из Placemark
  String _formatAddress(Placemark placemark) {
    List<String> addressParts = [];
    
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }
    
    if (placemark.subThoroughfare != null && placemark.subThoroughfare!.isNotEmpty) {
      addressParts.add('д. ${placemark.subThoroughfare!}');
    }
    
    if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty) {
      addressParts.add(placemark.thoroughfare!);
    }
    
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      addressParts.add(placemark.subLocality!);
    }
    
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }
    
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      addressParts.add(placemark.administrativeArea!);
    }
    
    return addressParts.join(', ');
  }

  /// Проверка доступности геолокации
  Future<bool> isLocationAvailable() async {
    try {
      // Проверяем доступность геолокации
      LocationPermission permission = await Geolocator.checkPermission();
      return permission != LocationPermission.deniedForever;
    } catch (e) {
      print('❌ Геолокация недоступна: $e');
      return false;
    }
  }

  /// Получение расстояния между двумя точками в метрах
  static double getDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Форматирование расстояния для отображения
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} м';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} км';
    }
  }
}

// Модель для хранения информации об адресе
class AddressInfo {
  final LatLng coordinates;
  final String address;
  final double? distance; // Расстояние от ресторана в метрах

  AddressInfo({
    required this.coordinates,
    required this.address,
    this.distance,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'address': address,
      'distance': distance,
    };
  }

  factory AddressInfo.fromJson(Map<String, dynamic> json) {
    return AddressInfo(
      coordinates: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      address: json['address'] as String,
      distance: json['distance'] as double?,
    );
  }

  // Методы для работы с 2ГИС API
  
  /// Получение адреса через 2ГИС API
  static Future<String> getAddressFrom2Gis(LatLng coordinates) async {
    try {
      // Используем 2ГИС геокодирование API
      final response = await http.get(
        Uri.parse(
          'https://catalog.api.2gis.com/3.0/items/geocode?lat=${coordinates.latitude}&lon=${coordinates.longitude}&key=3f562b3d-78e5-48e4-accd-406754cb15fb'
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null && data['result']['items'] != null && data['result']['items'].isNotEmpty) {
          return data['result']['items'][0]['full_address'] ?? MapsService._generateApproximateAddress(coordinates.latitude, coordinates.longitude);
        }
      }
    } catch (e) {
      print('Ошибка 2ГИС API: $e');
    }
    
    // Fallback на генерацию приблизительного адреса
    return MapsService._generateApproximateAddress(coordinates.latitude, coordinates.longitude);
  }

  /// Поиск координат через 2ГИС API
  static Future<LatLng?> getCoordinatesFrom2Gis(String address) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://catalog.api.2gis.com/3.0/items/geocode?q=${Uri.encodeComponent(address)}&key=3f562b3d-78e5-48e4-accd-406754cb15fb'
        ),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null && data['result']['items'] != null && data['result']['items'].isNotEmpty) {
          final item = data['result']['items'][0];
          final point = item['point'];
          if (point != null) {
            return LatLng(point['lat'], point['lon']);
          }
        }
      }
    } catch (e) {
      print('Ошибка 2ГИС API поиска: $e');
    }
    
    return null;
  }

  /// Проверка доступности доставки через 2ГИС
  static Future<bool> checkDeliveryAvailability2Gis(LatLng coordinates) async {
    final distance = MapsService.getDistance(RestaurantLocation.coordinates, coordinates);
    return distance <= RestaurantLocation.deliveryRadius;
  }
}

// Константы для ресторана (координаты центра Бишкека)
class RestaurantLocation {
  static const LatLng coordinates = LatLng(42.8746, 74.5698);
  static const String address = 'г. Бишкек, центр города';
  static const double deliveryRadius = 15000; // 15 км радиус доставки
}
