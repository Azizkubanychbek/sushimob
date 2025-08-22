import 'package:flutter/material.dart';
import '../../models/app_set.dart';
import '../../services/api_sushi_service.dart';
import '../../services/cart_service.dart';
import '../../services/favorites_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_error_widget.dart';
import '../../widgets/unified_product_card.dart';
import '../product_detail_screen/widgets/add_to_cart_button_widget.dart';

class SetDetailScreen extends StatefulWidget {
  final int setId;

  const SetDetailScreen({super.key, required this.setId});

  @override
  State<SetDetailScreen> createState() => _SetDetailScreenState();
}

class _SetDetailScreenState extends State<SetDetailScreen> {
  final ApiSushiService _apiService = ApiSushiService();
  final CartService _cartService = CartService();
  
  AppSet? _set;
  List<Map<String, dynamic>> _setComposition = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadSetDetails();
  }

  Future<void> _loadSetDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Загружаем детали сета
      final set = await ApiSushiService.getSetById(widget.setId);
      
      // Загружаем состав сета
      final composition = await ApiSushiService.getSetComposition(widget.setId);

      setState(() {
        _set = set;
        _setComposition = composition;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addToCart() {
    if (_set != null) {
      _cartService.addToCart(
        itemType: 'set',
        itemId: _set!.id,
        quantity: _quantity,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_set!.name} добавлен в корзину'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_set?.name ?? 'Загрузка...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? CustomErrorWidget(
                  errorMessage: _errorMessage!,
                )
              : _set == null
                  ? const CustomErrorWidget(errorMessage: 'Сет не найден')
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Изображение сета
                          Container(
                            width: double.infinity,
                            height: 250,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                            ),
                            child: _set!.imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _set!.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.set_meal,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.set_meal,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Название и описание
                          Text(
                            _set!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          if (_set!.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _set!.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          
                          // Цена и скидка
                          Row(
                            children: [
                              if (_set!.discount > 0) ...[
                                Text(
                                  _set!.originalPrice.toStringAsFixed(0) + '₽',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '-${_set!.discount.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                '${_set!.price.toStringAsFixed(0)}₽',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Состав сета
                          const Text(
                            'Состав сета:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          if (_setComposition.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'Состав сета временно недоступен',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ..._setComposition.map((item) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['roll_name'] ?? 'Неизвестный ролл',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Text(
                                    '${item['quantity']} шт',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )).toList(),
                          
                          const SizedBox(height: 32),
                          
                          // Селектор количества и кнопка добавления в корзину
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Количество:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: _decrementQuantity,
                                          icon: const Icon(Icons.remove),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.grey[200],
                                          ),
                                        ),
                                        Container(
                                          width: 50,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Text(
                                            '$_quantity',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: _incrementQuantity,
                                          icon: const Icon(Icons.add),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.grey[200],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                AddToCartButtonWidget(
                                  itemType: 'set',
                                  itemId: _set!.id,
                                  itemName: _set!.name,
                                  onSuccess: () {
                                    setState(() {
                                      // Обновляем UI после успешного добавления
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
