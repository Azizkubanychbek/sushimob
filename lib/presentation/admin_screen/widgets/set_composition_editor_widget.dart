import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class SetCompositionItem {
  final int itemId;
  final String itemName;
  final double itemCostPrice;
  final double itemSalePrice;
  final String itemType; // 'roll' или 'other'
  final String? itemCategory; // для других товаров (соусы, напитки)
  int quantity;
  
  double get calculatedCost => itemCostPrice * quantity;
  double get calculatedSalePrice => itemSalePrice * quantity;

  SetCompositionItem({
    required this.itemId,
    required this.itemName,
    required this.itemCostPrice,
    required this.itemSalePrice,
    required this.itemType,
    this.itemCategory,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'item_type': itemType,
    'quantity': quantity,
  };
}

class SetCompositionEditorWidget extends StatefulWidget {
  final int setId;
  final String setName;
  final List<SetCompositionItem> currentComposition;

  const SetCompositionEditorWidget({
    super.key,
    required this.setId,
    required this.setName,
    required this.currentComposition,
  });

  @override
  State<SetCompositionEditorWidget> createState() => _SetCompositionEditorWidgetState();
}

class _SetCompositionEditorWidgetState extends State<SetCompositionEditorWidget> {
  List<SetCompositionItem> _composition = [];
  List<Map<String, dynamic>> _availableRolls = [];
  bool _isLoading = true;
  bool _isSaving = false;
  double _totalCost = 0;
  double _totalSalePrice = 0;

  @override
  void initState() {
    super.initState();
    _composition = List.from(widget.currentComposition);
    _calculateTotalCost();
    _loadAvailableRolls();
  }

  Future<void> _loadAvailableRolls() async {
    try {
      setState(() => _isLoading = true);
      
      // Загружаем роллы
      final rolls = await ApiService.getRolls();
      final rollsData = rolls.map((roll) => {
        'id': roll.id,
        'name': roll.name,
        'cost_price': roll.costPrice,
        'sale_price': roll.salePrice,
        'type': 'roll',
        'category': null,
      }).toList();
      
      // Загружаем другие товары
      final otherItems = await ApiService.getOtherItems();
      final otherItemsData = otherItems.map((item) => {
        'id': item['id'],
        'name': item['name'],
        'cost_price': item['cost_price'],
        'sale_price': item['sale_price'],
        'type': 'other',
        'category': item['category'],
      }).toList();
      
      // Объединяем все доступные товары
      _availableRolls = [...rollsData, ...otherItemsData];
      
      print('🍣 DEBUG: Загружено роллов: ${rollsData.length}');
      print('🍣 DEBUG: Загружено других товаров: ${otherItemsData.length}');
      print('🍣 DEBUG: Всего доступно товаров: ${_availableRolls.length}');
      
      if (_availableRolls.isNotEmpty) {
        print('🍣 DEBUG: Первый товар: ${_availableRolls.first}');
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки товаров: $e')),
        );
      }
    }
  }

  void _calculateTotalCost() {
    _totalCost = _composition.fold(0, (sum, item) => sum + item.calculatedCost);
    _totalSalePrice = _composition.fold(0, (sum, item) => sum + item.calculatedSalePrice);
    
    print('🔍 DEBUG: Пересчет стоимости. Элементов: ${_composition.length}');
    print('🔍 DEBUG: Общая себестоимость: $_totalCost');
    print('🔍 DEBUG: Общая цена продажи: $_totalSalePrice');
    
    for (int i = 0; i < _composition.length; i++) {
      final item = _composition[i];
      print('🔍 DEBUG: Элемент $i: ${item.itemName} x${item.quantity} = ${item.calculatedCost}₽ (себест.) / ${item.calculatedSalePrice}₽ (продажа)');
    }
  }

  void _addRoll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить товар в сет'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Выберите товар:'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableRolls.length,
                  itemBuilder: (context, index) {
                    final roll = _availableRolls[index];
                    final isAlreadyAdded = _composition.any((item) => item.itemId == roll['id']);
                    
                    return ListTile(
                      title: Text(roll['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${roll['sale_price']}₽'),
                          if (roll['type'] == 'other' && roll['category'] != null)
                            Text('${roll['category']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      trailing: isAlreadyAdded 
                        ? const Icon(Icons.check, color: Colors.green)
                        : const Icon(Icons.add),
                      onTap: isAlreadyAdded ? null : () {
                        Navigator.of(context).pop();
                        _addRollToComposition(roll);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _addRollToComposition(Map<String, dynamic> item) {
    print('🔍 DEBUG: Добавляем товар в состав: $item');
    print('🔍 DEBUG: ID товара: ${item['id']}, Название: ${item['name']}, Тип: ${item['type']}');
    
    setState(() {
      final newItem = SetCompositionItem(
        itemId: item['id'],
        itemName: item['name'],
        itemCostPrice: item['cost_price'].toDouble(),
        itemSalePrice: item['sale_price'].toDouble(),
        itemType: item['type'],
        itemCategory: item['category'],
        quantity: 1, // По умолчанию 1 штука
      );
      
      print('🔍 DEBUG: Создан новый элемент: itemId=${newItem.itemId}, itemName=${newItem.itemName}, itemType=${newItem.itemType}');
      
      _composition.add(newItem);
      _calculateTotalCost();
      
      print('🔍 DEBUG: Товар добавлен. Всего в составе: ${_composition.length}');
    });
  }

  void _removeRoll(int index) {
    setState(() {
      _composition.removeAt(index);
      _calculateTotalCost();
    });
  }

  void _updateRollQuantity(int index, int quantity) {
    setState(() {
      _composition[index].quantity = quantity;
      _calculateTotalCost();
    });
  }

  Future<void> _saveComposition() async {
    if (_composition.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один товар')),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);
      
      final compositionData = {
        'items': _composition.map((item) => item.toJson()).toList(),
      };

      print('🔍 DEBUG: Отправляем данные для сохранения: $compositionData');
      print('🔍 DEBUG: Количество роллов в составе: ${_composition.length}');
      
      for (int i = 0; i < _composition.length; i++) {
        final item = _composition[i];
        print('🔍 DEBUG: Ролл $i: ID=${item.itemId}, Количество=${item.quantity}, JSON=${item.toJson()}');
      }

      final response = await ApiService.updateSetComposition(widget.setId, compositionData);
      print('🔍 DEBUG: Ответ API на сохранение: $response');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Состав сета сохранен успешно!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Возвращаем true для обновления
      }
    } catch (e) {
      print('❌ Ошибка сохранения состава сета: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final discountPercent = _totalSalePrice > 0 
      ? ((_totalSalePrice - _totalSalePrice * 0.9) / _totalSalePrice) * 100 
      : 0.0;
    final finalSalePrice = _totalSalePrice * 0.9;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.set_meal, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Состав сета: ${widget.setName}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Информация о ценах
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Себестоимость: ${_totalCost.toStringAsFixed(2)}₽',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Общая цена роллов: ${_totalSalePrice.toStringAsFixed(2)}₽',
                              style: TextStyle(color: Colors.blue[600]),
                            ),
                            Text(
                              'Цена сета (скидка ${discountPercent.toStringAsFixed(1)}%): ${finalSalePrice.toStringAsFixed(2)}₽',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Роллов в сете: ${_composition.length}',
                              style: TextStyle(color: Colors.blue[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Кнопки управления
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _addRoll,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить товар'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const Spacer(),
                if (_composition.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _saveComposition,
                    icon: _isSaving 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Сохранение...' : 'Сохранить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Список роллов в сете
            Expanded(
              child: _composition.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.set_meal, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Сет пуст',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нажмите "Добавить товар" для начала',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _composition.length,
                    itemBuilder: (context, index) {
                      final item = _composition[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Иконка ролла
                              CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  item.itemName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Информация о ролле
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.itemName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${item.itemSalePrice}₽ за штуку',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Поле количества
                              SizedBox(
                                width: 80,
                                child: TextFormField(
                                  initialValue: item.quantity.toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'шт',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final quantity = int.tryParse(value) ?? 1;
                                    if (quantity > 0) {
                                      _updateRollQuantity(index, quantity);
                                    }
                                  },
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Стоимость
                              Text(
                                '${item.calculatedSalePrice.toStringAsFixed(2)}₽',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Кнопка удаления
                              IconButton(
                                onPressed: () => _removeRoll(index),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Удалить',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}