import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/cart_service.dart';

class BonusPointsWidget extends StatefulWidget {
  final double totalPrice;
  final VoidCallback onBonusUsed;

  const BonusPointsWidget({
    super.key,
    required this.totalPrice,
    required this.onBonusUsed,
  });

  @override
  State<BonusPointsWidget> createState() => _BonusPointsWidgetState();
}

class _BonusPointsWidgetState extends State<BonusPointsWidget> {
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
  bool _isLoading = false;
  int _bonusPoints = 0;
  bool _canUseBonus = false;
  int _bonusToUse = 0;

  @override
  void initState() {
    super.initState();
    _loadBonusPoints();
  }

  void _loadBonusPoints() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _bonusPoints = user.bonusPoints;
        _canUseBonus = user.bonusPoints > 0 && widget.totalPrice > 0;
        // Устанавливаем максимальное количество бонусов для использования
        _bonusToUse = _bonusPoints > widget.totalPrice 
            ? widget.totalPrice.toInt() 
            : _bonusPoints;
      });
    }
  }

  void _useBonusPoints() async {
    if (!_canUseBonus) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _cartService.useBonusPoints(_bonusToUse);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Обновляем информацию о бонусных баллах
        _loadBonusPoints();
        
        // Call the callback to refresh the cart
        widget.onBonusUsed();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при использовании бонусных баллов: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bonusPoints <= 0) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: Colors.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Бонусные баллы',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'У вас есть $_bonusPoints бонусных баллов',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Будет использовано: $_bonusToUse баллов',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1 балл = 1 сом скидки',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (_canUseBonus)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _useBonusPoints,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Использовать'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Недоступно',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (!_canUseBonus && widget.totalPrice > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Бонусные баллы можно использовать только при наличии товаров в корзине',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
