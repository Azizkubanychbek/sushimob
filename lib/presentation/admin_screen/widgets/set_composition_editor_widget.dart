import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class SetCompositionItem {
  final int rollId;
  final String rollName;
  final double rollCostPrice;
  final double rollSalePrice;
  int quantity;
  double get calculatedCost => rollCostPrice * quantity;
  double get calculatedSalePrice => rollSalePrice * quantity;

  SetCompositionItem({
    required this.rollId,
    required this.rollName,
    required this.rollCostPrice,
    required this.rollSalePrice,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'roll_id': rollId,
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
      
      final rolls = await ApiService.getRolls();
      _availableRolls = rolls.map((roll) => {
        'id': roll.id,
        'name': roll.name,
        'cost_price': roll.costPrice,
        'sale_price': roll.salePrice,
      }).toList();
      
      print('🍣 DEBUG: Загружено роллов: ${_availableRolls.length}');
      if (_availableRolls.isNotEmpty) {
        print('🍣 DEBUG: Первый ролл: ${_availableRolls.first}');
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки роллов: $e')),
        );
      }
    }
  }

  void _calculateTotalCost() {
    _totalCost = _composition.fold(0, (sum, item) => sum + item.calculatedCost);
    _totalSalePrice = _composition.fold(0, (sum, item) => sum + item.calculatedSalePrice);
  }

  void _addRoll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить ролл в сет'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Выберите ролл:'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableRolls.length,
                  itemBuilder: (context, index) {
                    final roll = _availableRolls[index];
                    final isAlreadyAdded = _composition.any((item) => item.rollId == roll['id']);
                    
                    return ListTile(
                      title: Text(roll['name']),
                      subtitle: Text('${roll['sale_price']}₽'),
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

  void _addRollToComposition(Map<String, dynamic> roll) {
    setState(() {
      _composition.add(SetCompositionItem(
        rollId: roll['id'],
        rollName: roll['name'],
        rollCostPrice: roll['cost_price'].toDouble(),
        rollSalePrice: roll['sale_price'].toDouble(),
        quantity: 1, // По умолчанию 1 штука
      ));
      _calculateTotalCost();
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
        const SnackBar(content: Text('Добавьте хотя бы один ролл')),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);
      
      final compositionData = {
        'rolls': _composition.map((item) => item.toJson()).toList(),
      };

      await ApiService.updateSetComposition(widget.setId, compositionData);
      
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
                  label: const Text('Добавить ролл'),
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
                          'Нажмите "Добавить ролл" для начала',
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
                                  item.rollName[0].toUpperCase(),
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
                                      item.rollName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${item.rollSalePrice}₽ за штуку',
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