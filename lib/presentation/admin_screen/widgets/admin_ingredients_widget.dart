import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class AdminIngredientsWidget extends StatefulWidget {
  const AdminIngredientsWidget({super.key});

  @override
  State<AdminIngredientsWidget> createState() => _AdminIngredientsWidgetState();
}

class _AdminIngredientsWidgetState extends State<AdminIngredientsWidget> {
  List<Map<String, dynamic>> _ingredients = [];
  bool _isLoading = true;
  Map<String, dynamic>? _editingIngredient;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costPerUnitController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _unitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costPerUnitController.dispose();
    _stockQuantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _loadIngredients() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final ingredients = await ApiService.getAdminIngredients();
      setState(() {
        _ingredients = ingredients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки ингредиентов: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddIngredientDialog() {
    _resetForm();
    _showIngredientDialog(isEditing: false);
  }

  void _showEditIngredientDialog(Map<String, dynamic> ingredient) {
    _editingIngredient = ingredient;
    _nameController.text = ingredient['name'];
    _costPerUnitController.text = ingredient['cost_per_unit'].toString();
    _stockQuantityController.text = ingredient['stock_quantity'].toString();
    _unitController.text = ingredient['unit'] ?? '';
    _showIngredientDialog(isEditing: true);
  }

  void _resetForm() {
    _editingIngredient = null;
    _nameController.clear();
    _costPerUnitController.clear();
    _stockQuantityController.clear();
    _unitController.clear();
  }

  void _showIngredientDialog({required bool isEditing}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Редактировать ингредиент' : 'Добавить ингредиент'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Название'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите название';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _costPerUnitController,
                  decoration: const InputDecoration(
                    labelText: 'Стоимость за единицу (₽/г или ₽/шт)',
                    hintText: 'Например: 0.5 за грамм или 10 за штуку'
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите стоимость за единицу';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Введите корректное число';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _stockQuantityController,
                  decoration: const InputDecoration(labelText: 'Остаток на складе'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите остаток';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Введите корректное число';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(labelText: 'Единица измерения'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите единицу измерения';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _saveIngredient,
            child: Text(isEditing ? 'Сохранить' : 'Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final ingredientData = {
        'name': _nameController.text.trim(),
        'cost_per_unit': double.parse(_costPerUnitController.text),
        'stock_quantity': double.parse(_stockQuantityController.text),
        'unit': _unitController.text.trim(),
      };

      if (_editingIngredient != null) {
        // Обновление существующего ингредиента
        await ApiService.updateAdminIngredient(_editingIngredient!['id'], ingredientData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ингредиент успешно обновлен'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Создание нового ингредиента
        await ApiService.createAdminIngredient(ingredientData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ингредиент успешно создан'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.of(context).pop();
      _resetForm();
      _loadIngredients();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteIngredient(Map<String, dynamic> ingredient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Вы уверены, что хотите удалить ингредиент "${ingredient['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteAdminIngredient(ingredient['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ингредиент успешно удален'),
            backgroundColor: Colors.green,
          ),
        );
        _loadIngredients();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Управление ингредиентами (${_ingredients.length})',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _showAddIngredientDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить ингредиент'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadIngredients,
                    child: _ingredients.isEmpty
                        ? const Center(
                            child: Text(
                              'Ингредиенты не найдены',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _ingredients.length,
                            itemBuilder: (context, index) {
                        final ingredient = _ingredients[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple,
                              child: Text(
                                ingredient['name'][0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              ingredient['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Chip(
                                      label: Text('Стоимость: ${ingredient['cost_per_unit']}₽/${ingredient['unit']}'),
                                      backgroundColor: Colors.orange[100],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text('Остаток: ${ingredient['stock_quantity']}'),
                                      backgroundColor: Colors.blue[100],
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text('Ед: ${ingredient['unit']}'),
                                      backgroundColor: Colors.grey[100],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _showEditIngredientDialog(ingredient),
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Редактировать',
                                ),
                                IconButton(
                                  onPressed: () => _deleteIngredient(ingredient),
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
                ),
              ],
            );
  }
}
