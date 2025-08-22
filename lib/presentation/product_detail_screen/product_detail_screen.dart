import 'package:flutter/material.dart';
import '../../models/app_roll.dart';
import '../../models/app_set.dart';
import '../../services/api_sushi_service.dart'; // Заменяем на API сервис
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import 'widgets/add_to_cart_button_widget.dart';
import 'widgets/customer_reviews_widget.dart';
import 'widgets/customization_options_widget.dart';
import 'widgets/nutritional_facts_widget.dart';
import 'widgets/product_description_widget.dart';
import 'widgets/product_image_carousel_widget.dart';
import 'widgets/product_info_widget.dart';
import 'widgets/quantity_selector_widget.dart';
import 'widgets/related_items_widget.dart';

class ProductDetailScreen extends StatefulWidget {
  final int? productId;
  final String? productType; // 'roll' или 'set'
  
  const ProductDetailScreen({
    super.key,
    this.productId,
    this.productType,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  AppRoll? roll;
  AppSet? set;
  bool isLoading = true;
  int quantity = 1;
  int? _productId;
  String? _productType;
  List<Map<String, dynamic>> rollRecipe = [];

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Получаем аргументы из навигации
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _productId = args['productId'] as int?;
      _productType = args['productType'] as String?;
      _loadProductData();
    }
  }

  Future<void> _loadProductData() async {
    if (_productId == null) {
      // Показываем пример ролла если ID не передан
      final rolls = await ApiSushiService.getRolls();
      if (rolls.isNotEmpty) {
        setState(() {
          roll = rolls.first;
          isLoading = false;
        });
      }
      return;
    }

    try {
      if (_productType == 'set') {
        final loadedSet = await ApiSushiService.getSetById(_productId!);
        setState(() {
          set = loadedSet;
          isLoading = false;
        });
      } else {
        final loadedRoll = await ApiSushiService.getRollById(_productId!);
        // Загружаем рецептуру ролла
        List<Map<String, dynamic>> recipe = [];
        try {
          final recipeResponse = await ApiService.getRollRecipe(_productId!);
          recipe = List<Map<String, dynamic>>.from(recipeResponse['ingredients'] ?? []);
        } catch (e) {
          print('Ошибка загрузки рецептуры: $e');
        }
        
        setState(() {
          roll = loadedRoll;
          rollRecipe = recipe;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки продукта: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Загрузка...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (roll == null && set == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: const Center(child: Text('Продукт не найден')),
      );
    }

    final isRoll = roll != null;
    final productName = isRoll ? roll!.name : set!.name;
    final productPrice = isRoll ? roll!.formattedPrice : set!.formattedPrice;
    final productDescription = isRoll ? roll!.description : set!.description;
    final productImage = isRoll ? roll!.imageUrl : set!.imageUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(productName),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Добавлено в избранное')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ссылка скопирована')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение продукта
            Container(
              height: 300,
              width: double.infinity,
              child: Image.network(
                productImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.restaurant,
                      size: 100,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            
            // Информация о продукте
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название и цена
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        productPrice,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Описание
                  Text(
                    'Описание',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    productDescription,
                    style: const TextStyle(fontSize: 16),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Дополнительная информация для роллов
                  if (isRoll) ...[
                    if (roll!.category.isNotEmpty) ...[
                      Text(
                        'Категория',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          roll!.category,
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    Text(
                      'Рейтинг: ${roll!.formattedRating} ⭐',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Время приготовления: ${roll!.formattedPreparationTime}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Состав ролла:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (rollRecipe.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Состав ролла временно недоступен',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...rollRecipe.map((ingredient) => Container(
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
                                ingredient['ingredient_name'] ?? 'Неизвестный ингредиент',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              '${ingredient['quantity']} ${ingredient['unit'] ?? 'г'}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )).toList(),
                  ],
                  
                  // Дополнительная информация для сетов
                  if (!isRoll) ...[
                    Text(
                      'Количество роллов: ${set!.totalRolls}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    if (set!.hasDiscount) ...[
                      Row(
                        children: [
                          Text(
                            'Оригинальная цена: ${set!.formattedOriginalPrice}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Скидка ${set!.formattedDiscount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Экономия: ${set!.formattedSavings}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Состав сета:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...set!.rolls.map((roll) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• ${roll.name}'),
                          Text(roll.formattedPrice),
                        ],
                      ),
                    )).toList(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Селектор количества
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    quantity.toString(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => setState(() => quantity++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Кнопки добавления в избранное и корзину
            Expanded(
              child: AddToCartButtonWidget(
                itemType: isRoll ? 'roll' : 'set',
                itemId: isRoll ? roll!.id : set!.id,
                itemName: productName,
                onSuccess: () {
                  setState(() {
                    // Обновляем UI после успешного добавления
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
