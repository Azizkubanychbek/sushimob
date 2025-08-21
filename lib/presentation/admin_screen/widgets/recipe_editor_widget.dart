import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class RecipeIngredient {
  final int ingredientId;
  final String name;
  final double costPerUnit;
  final String unit;
  double amount;
  double get calculatedCost => costPerUnit * amount;

  RecipeIngredient({
    required this.ingredientId,
    required this.name,
    required this.costPerUnit,
    required this.unit,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'ingredient_id': ingredientId,
    'amount': amount,
  };
}

class RecipeEditorWidget extends StatefulWidget {
  final int rollId;
  final String rollName;
  final List<RecipeIngredient> currentIngredients;

  const RecipeEditorWidget({
    super.key,
    required this.rollId,
    required this.rollName,
    required this.currentIngredients,
  });

  @override
  State<RecipeEditorWidget> createState() => _RecipeEditorWidgetState();
}

class _RecipeEditorWidgetState extends State<RecipeEditorWidget> {
  List<RecipeIngredient> _ingredients = [];
  List<RecipeIngredient> _availableIngredients = [];
  bool _isLoading = true;
  bool _isSaving = false;
  double _totalCost = 0;

  @override
  void initState() {
    super.initState();
    _ingredients = List.from(widget.currentIngredients);
    _calculateTotalCost();
    _loadAvailableIngredients();
  }

  Future<void> _loadAvailableIngredients() async {
    try {
      setState(() => _isLoading = true);
      
      final ingredients = await ApiService.getAdminIngredients();
      print('🧄 DEBUG: Загружено ингредиентов: ${ingredients.length}');
      if (ingredients.isNotEmpty) {
        print('🧄 DEBUG: Первый ингредиент: ${ingredients.first}');
      }
      
      _availableIngredients = ingredients.map((dynamic ing) {
        final map = ing as Map<String, dynamic>;
        final dynamic rawId = map['id'] ?? map['ingredient_id'];
        final dynamic rawCost = map['cost_per_unit'];
        return RecipeIngredient(
          ingredientId: (rawId as num).toInt(),
          name: (map['name'] ?? '').toString(),
          costPerUnit: (rawCost as num).toDouble(),
          unit: (map['unit'] ?? '').toString(),
          amount: 0,
        );
      }).toList();
      
      print('🧄 DEBUG: Обработано ингредиентов: ${_availableIngredients.length}');
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки ингредиентов: $e')),
        );
      }
    }
  }

  void _calculateTotalCost() {
    _totalCost = _ingredients.fold(0, (sum, ing) => sum + ing.calculatedCost);
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить ингредиент'),
        content: SizedBox(
          width: double.maxFinite,
          height: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Выберите ингредиент:'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableIngredients.length,
                  itemBuilder: (context, index) {
                    final ing = _availableIngredients[index];
                    final isAlreadyAdded = _ingredients.any((i) => i.ingredientId == ing.ingredientId);
                    
                    return ListTile(
                      title: Text(ing.name),
                      subtitle: Text('${ing.costPerUnit}₽/${ing.unit}'),
                      trailing: isAlreadyAdded 
                        ? const Icon(Icons.check, color: Colors.green)
                        : const Icon(Icons.add),
                      onTap: isAlreadyAdded ? null : () {
                        Navigator.of(context).pop();
                        _addIngredientToList(ing);
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

  void _addIngredientToList(RecipeIngredient ingredient) {
    setState(() {
      _ingredients.add(RecipeIngredient(
        ingredientId: ingredient.ingredientId,
        name: ingredient.name,
        costPerUnit: ingredient.costPerUnit,
        unit: ingredient.unit,
        amount: 1, // По умолчанию 1 единица
      ));
      _calculateTotalCost();
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
      _calculateTotalCost();
    });
  }

  void _updateIngredientAmount(int index, double amount) {
    setState(() {
      _ingredients[index].amount = amount;
      _calculateTotalCost();
    });
  }

  Future<void> _saveRecipe() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один ингредиент')),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);
      
      final recipeData = {
        'ingredients': _ingredients.map((ing) => ing.toJson()).toList(),
      };

      await ApiService.updateRollRecipe(widget.rollId, recipeData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Рецептура сохранена успешно!'),
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
                Icon(Icons.restaurant_menu, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Рецептура: ${widget.rollName}',
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
            
            // Информация о себестоимости
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
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
                          'Ингредиентов: ${_ingredients.length}',
                          style: TextStyle(color: Colors.blue[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Кнопка добавления ингредиента
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить ингредиент'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const Spacer(),
                if (_ingredients.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _saveRecipe,
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
            
            // Список ингредиентов
            Expanded(
              child: _ingredients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Нет ингредиентов',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нажмите "Добавить ингредиент" для начала',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _ingredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = _ingredients[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Иконка ингредиента
                              CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  ingredient.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Информация об ингредиенте
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ingredient.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${ingredient.costPerUnit}₽/${ingredient.unit}',
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
                                  initialValue: ingredient.amount.toString(),
                                  decoration: InputDecoration(
                                    labelText: ingredient.unit,
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final amount = double.tryParse(value) ?? 0;
                                    if (amount > 0) {
                                      _updateIngredientAmount(index, amount);
                                    }
                                  },
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Стоимость
                              Text(
                                '${ingredient.calculatedCost.toStringAsFixed(2)}₽',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Кнопка удаления
                              IconButton(
                                onPressed: () => _removeIngredient(index),
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
