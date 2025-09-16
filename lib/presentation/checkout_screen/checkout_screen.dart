import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../services/cart_service.dart';
import '../../services/api_service.dart';
import '../../models/cart_item.dart';
import '../address_selection_screen/interactive_map_screen.dart';
import '../address_selection_screen/universal_2gis_map_screen.dart';
import '../../services/maps_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final MapsService _mapsService = MapsService();
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _commentController = TextEditingController();
  
  String _paymentMethod = 'cash';
  bool _isLoading = false;
  AddressInfo? _selectedAddressInfo;

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  void _loadCartData() {
    // Загружаем данные из корзины
    setState(() {});
  }

  Future<void> _selectAddressOnMap() async {
    final currentLocation = _selectedAddressInfo?.coordinates ?? 
        const LatLng(42.8746, 74.5698); // Центр Бишкека по умолчанию

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Universal2GisMapScreen(
          initialCenter: currentLocation,
          onLocationSelected: (coordinates, address) {
            setState(() {
              _selectedAddressInfo = AddressInfo(
                coordinates: coordinates,
                address: address,
                distance: MapsService.getDistance(
                  RestaurantLocation.coordinates, 
                  coordinates
                ),
              );
              _addressController.text = address;
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Подготавливаем данные заказа
      final orderItems = _cartService.cartItems.map((cartItem) {
        // Для бонусных баллов используем специальный ID
        dynamic itemId;
        if (cartItem.itemType == 'bonus_points') {
          itemId = 'bonus';
        } else if (cartItem.item is Map<String, dynamic>) {
          itemId = cartItem.item['id'];
        } else if (cartItem.item != null) {
          itemId = cartItem.item.id;
        } else {
          // Если item равен null, используем ID из cartItem
          itemId = cartItem.id;
        }
        
        return {
          'type': cartItem.itemType,
          'id': itemId,
          'quantity': cartItem.quantity,
          'unit_price': cartItem.price / cartItem.quantity,
          'total_price': cartItem.price,
        };
      }).toList();

      // Создаем заказ через API
      final result = await ApiService.createNewOrder(
        deliveryAddress: _addressController.text.trim(),
        deliveryPhone: _phoneController.text.trim(),
        paymentMethod: _paymentMethod,
        notes: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );

      // Заказ успешно создан
      // Очищаем корзину после успешного заказа
      await _cartService.clearCart();
      
      // Показываем успешное сообщение
      _showSuccessDialog(result.id);
    } catch (e) {
      _showErrorDialog('Ошибка сети: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(int orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Заказ оформлен!'),
          ],
        ),
        content: Text('Ваш заказ #$orderId успешно создан. Мы свяжемся с вами в ближайшее время.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Закрываем диалог
              Navigator.of(context).pop(); // Возвращаемся на главную
            },
            child: const Text('Отлично!'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Ошибка'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформление заказа'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Информация о заказе
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ваш заказ',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._cartService.cartItems.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text('${item.itemName} x${item.quantity}'),
                                  ),
                                  Text('${item.price.toStringAsFixed(2)} сом'),
                                ],
                              ),
                            )),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Стоимость товаров:'),
                                Text('${_cartService.totalPrice.toStringAsFixed(2)} сом'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Доставка:'),
                                Text('200 сом'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Итого:',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${(_cartService.totalPrice + 200).toStringAsFixed(2)} сом',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Контактная информация
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Контактная информация',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Телефон для связи *',
                                hintText: '+996 (555) 123-456',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите номер телефона';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Адрес доставки *',
                                hintText: 'ул. Чуй, д. 123, кв. 45, Бишкек',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  onPressed: _selectAddressOnMap,
                                  icon: const Icon(Icons.map),
                                  tooltip: 'Выбрать на карте',
                                ),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите адрес доставки';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Нажмите на иконку карты для выбора адреса на карте',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                labelText: 'Комментарий к заказу',
                                hintText: 'Дополнительные пожелания...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Способ оплаты
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Способ оплаты',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            RadioListTile<String>(
                              title: const Text('Наличными при получении'),
                              subtitle: const Text('Оплата курьеру'),
                              value: 'cash',
                              groupValue: _paymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  _paymentMethod = value!;
                                });
                              },
                            ),
                            RadioListTile<String>(
                              title: const Text('Картой при получении'),
                              subtitle: const Text('Оплата картой курьеру'),
                              value: 'card',
                              groupValue: _paymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  _paymentMethod = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Кнопка оформления заказа
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitOrder,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Оформить заказ',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
