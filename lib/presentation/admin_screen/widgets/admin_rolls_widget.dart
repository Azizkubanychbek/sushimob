import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../models/roll.dart';
import 'recipe_editor_widget.dart';

class AdminRollsWidget extends StatefulWidget {
  const AdminRollsWidget({super.key});

  @override
  State<AdminRollsWidget> createState() => _AdminRollsWidgetState();
}

class _AdminRollsWidgetState extends State<AdminRollsWidget> {
  List<Roll> _rolls = [];
  bool _isLoading = true;
  Roll? _editingRoll;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isPopular = false;
  bool _isNew = false;

  @override
  void initState() {
    super.initState();
    _loadRolls();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadRolls() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final rolls = await ApiService.getRolls();
      setState(() {
        _rolls = rolls;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки роллов: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddRollDialog() {
    _resetForm();
    _showRollDialog(isEditing: false);
  }

  void _showEditRollDialog(Roll roll) {
    _editingRoll = roll;
    _nameController.text = roll.name;
    _descriptionController.text = roll.description ?? '';
    _costPriceController.text = roll.costPrice.toString();
    _salePriceController.text = roll.salePrice.toString();
    _imageUrlController.text = roll.imageUrl ?? '';
    _isPopular = roll.isPopular;
    _isNew = roll.isNew;
    _showRollDialog(isEditing: true);
  }

  void _resetForm() {
    _editingRoll = null;
    _nameController.clear();
    _descriptionController.clear();
    _costPriceController.clear();
    _salePriceController.clear();
    _imageUrlController.clear();
    _isPopular = false;
    _isNew = false;
  }

  void _showRollDialog({required bool isEditing}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Редактировать ролл' : 'Добавить ролл'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Описание'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Если ролл ещё не создан, создаем черновик, чтобы открыть редактор рецептуры
                    if (_editingRoll == null) {
                      if (!_formKey.currentState!.validate()) return;
                      final draftData = {
                        'name': _nameController.text.trim(),
                        'description': _descriptionController.text.trim(),
                        'cost_price': 0.0,
                        'sale_price': double.tryParse(_salePriceController.text) ?? 0.0,
                        'image_url': _imageUrlController.text.trim(),
                        'is_popular': _isPopular,
                        'is_new': _isNew,
                      };
                      final created = await ApiService.createAdminRoll(draftData);
                      _editingRoll = Roll.fromJson(created['roll']);
                    }
                    await _showRecipeEditor();
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Редактировать рецептуру'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                TextFormField(
                  controller: _costPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Себестоимость (автоматически)',
                    helperText: 'Будет рассчитываться из ингредиентов',
                    suffixIcon: Icon(Icons.calculate, color: Colors.blue),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: false,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                TextFormField(
                  controller: _salePriceController,
                  decoration: const InputDecoration(labelText: 'Цена продажи'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите цену продажи';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Введите корректное число';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'URL изображения'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Популярный'),
                        value: _isPopular,
                        onChanged: (value) {
                          setState(() {
                            _isPopular = value ?? false;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Новый'),
                        value: _isNew,
                        onChanged: (value) {
                          setState(() {
                            _isNew = value ?? false;
                          });
                        },
                      ),
                    ),
                  ],
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
            onPressed: _saveRoll,
            child: Text(isEditing ? 'Сохранить' : 'Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRoll() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final rollData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'cost_price': double.parse(_costPriceController.text),
        'sale_price': double.parse(_salePriceController.text),
        'image_url': _imageUrlController.text.trim(),
        'is_popular': _isPopular,
        'is_new': _isNew,
      };

      if (_editingRoll != null) {
        // Обновление существующего ролла
        await ApiService.updateAdminRoll(_editingRoll!.id!, rollData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ролл успешно обновлен'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Создание нового ролла
        await ApiService.createAdminRoll(rollData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ролл успешно создан'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.of(context).pop();
      _resetForm();
      _loadRolls();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteRoll(Roll roll) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Вы уверены, что хотите удалить ролл "${roll.name}"?'),
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
        await ApiService.deleteAdminRoll(roll.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ролл успешно удален'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRolls();
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
                        'Управление роллами (${_rolls.length})',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _showAddRollDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить ролл'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadRolls,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rolls.length,
                      itemBuilder: (context, index) {
                        final roll = _rolls[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                roll.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              roll.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (roll.description?.isNotEmpty == true)
                                  Text(roll.description!),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text('Себест: ${roll.costPrice}₽'),
                                      backgroundColor: Colors.orange[100],
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text('Продажа: ${roll.salePrice}₽'),
                                      backgroundColor: Colors.green[100],
                                    ),
                                  ],
                                ),
                                                                 if (roll.isPopular || roll.isNew)
                                   Row(
                                     children: [
                                       if (roll.isPopular)
                                         Chip(
                                           label: const Text('🔥 Популярный'),
                                           backgroundColor: Colors.red[100],
                                         ),
                                       if (roll.isNew)
                                         Chip(
                                           label: const Text('🆕 Новый'),
                                           backgroundColor: Colors.blue[100],
                                         ),
                                     ],
                                   ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _showEditRollDialog(roll),
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Редактировать',
                                ),
                                IconButton(
                                  onPressed: () => _deleteRoll(roll),
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

  Future<void> _showRecipeEditor() async {
    try {
      // Получаем текущую рецептуру ролла
      final recipeData = await ApiService.getRollRecipe(_editingRoll!.id!);
      
      // Преобразуем данные в RecipeIngredient
      final currentIngredients = (recipeData['ingredients'] as List).map((ing) => RecipeIngredient(
        ingredientId: ing['ingredient_id'],
        name: ing['name'],
        costPerUnit: ing['cost_per_unit'].toDouble(),
        unit: ing['unit'],
        amount: ing['amount_per_roll'].toDouble(),
      )).toList();

      // Показываем редактор рецептуры
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => RecipeEditorWidget(
          rollId: _editingRoll!.id!,
          rollName: _editingRoll!.name,
          currentIngredients: currentIngredients,
        ),
      );

      // Если рецептура была изменена, обновляем данные
      if (result == true) {
        _loadRolls(); // Перезагружаем роллы для обновления себестоимости
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки рецептуры: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
