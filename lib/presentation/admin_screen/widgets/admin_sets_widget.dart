import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../models/set.dart';
import 'set_composition_editor_widget.dart';

class AdminSetsWidget extends StatefulWidget {
  const AdminSetsWidget({super.key});

  @override
  State<AdminSetsWidget> createState() => _AdminSetsWidgetState();
}

class _AdminSetsWidgetState extends State<AdminSetsWidget> {
  List<Set> _sets = [];
  bool _isLoading = true;
  Set? _editingSet;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _setPriceController = TextEditingController();
  // Убираем поле скидки - она будет считаться автоматически
  final _imageUrlController = TextEditingController();
  bool _isPopular = false;
  bool _isNew = false;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _setPriceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSets() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final sets = await ApiService.getSets();
      setState(() {
        _sets = sets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки сетов: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddSetDialog() {
    _resetForm();
    // Устанавливаем начальные значения для нового сета
    _costPriceController.text = '0.0'; // Начальная себестоимость
    _setPriceController.text = '0.0';  // Начальная цена продажи
    _showSetDialog(isEditing: false);
  }

  void _showEditSetDialog(Set set) {
    _editingSet = set;
    _nameController.text = set.name;
    _descriptionController.text = set.description ?? '';
    _costPriceController.text = set.costPrice.toString();
    _setPriceController.text = set.setPrice.toString();
    _imageUrlController.text = set.imageUrl ?? '';
    _isPopular = set.isPopular;
    _isNew = set.isNew;
    _showSetDialog(isEditing: true);
  }

  void _resetForm() {
    _editingSet = null;
    _nameController.clear();
    _descriptionController.clear();
    _costPriceController.clear();
    _setPriceController.clear();
    _imageUrlController.clear();
    _isPopular = false;
    _isNew = false;
  }

  void _showSetDialog({required bool isEditing}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Редактировать сет' : 'Добавить сет'),
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
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Описание'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _editingSet != null ? () => _showCompositionEditor() : null,
                  icon: const Icon(Icons.list_alt),
                  label: Text(_editingSet != null ? 'Редактировать состав сета' : 'Создайте сет для редактирования'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _editingSet != null ? Colors.purple : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                TextFormField(
                  controller: _costPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Себестоимость (автоматически)',
                    helperText: 'Будет рассчитываться из компонентов сета',
                    suffixIcon: Icon(Icons.calculate, color: Colors.blue),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: false, // Отключаем ручное редактирование
                  style: TextStyle(color: Colors.grey[600]),
                ),
                TextFormField(
                  controller: _setPriceController,
                  decoration: const InputDecoration(labelText: 'Цена сета'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите цену сета';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Введите корректное число';
                    }
                    return null;
                  },
                ),
                                            // Скидка рассчитывается автоматически на основе разницы между
                            // себестоимостью и ценой продажи
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info, color: Colors.blue[600]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Скидка рассчитывается автоматически на основе разницы между себестоимостью и ценой продажи',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
            onPressed: _saveSet,
            child: Text(isEditing ? 'Сохранить' : 'Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSet() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Проверяем, что поля не пустые
      if (_costPriceController.text.trim().isEmpty || _setPriceController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заполните все обязательные поля'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Безопасно преобразуем строки в числа
      final costPriceText = _costPriceController.text.trim();
      final setPriceText = _setPriceController.text.trim();
      
      final costPrice = double.tryParse(costPriceText);
      final setPrice = double.tryParse(setPriceText);
      
      if (costPrice == null || setPrice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Введите корректные числовые значения для цен'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Автоматически рассчитываем скидку
      final discountPercent = costPrice > 0 ? ((costPrice - setPrice) / costPrice * 100).clamp(0.0, 100.0) : 0.0;
      
      final setData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'cost_price': costPrice,
        'set_price': setPrice,
        'discount_percent': discountPercent,
        'image_url': _imageUrlController.text.trim(),
        'is_popular': _isPopular,
        'is_new': _isNew,
      };

      print('🔍 DEBUG: Отправляем данные сета: $setData');

      if (_editingSet != null) {
        // Обновление существующего сета
        await ApiService.updateAdminSet(_editingSet!.id!, setData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сет успешно обновлен'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Создание нового сета
        await ApiService.createAdminSet(setData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сет успешно создан'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.of(context).pop();
      _resetForm();
      _loadSets();
    } catch (e) {
      print('❌ Ошибка сохранения сета: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSet(Set set) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Вы уверены, что хотите удалить сет "${set.name}"?'),
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
        await ApiService.deleteAdminSet(set.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сет успешно удален'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSets();
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
                        'Управление сетами (${_sets.length})',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _showAddSetDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить сет'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadSets,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sets.length,
                      itemBuilder: (context, index) {
                        final set = _sets[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Text(
                                set.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              set.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (set.description?.isNotEmpty == true)
                                  Text(set.description!),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text('Себест: ${set.costPrice}₽'),
                                      backgroundColor: Colors.orange[100],
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text('Цена: ${set.setPrice}₽'),
                                      backgroundColor: Colors.green[100],
                                    ),
                                  ],
                                ),
                                // Показываем автоматически рассчитанную скидку
                                if (set.setPrice < set.costPrice)
                                  Chip(
                                    label: Text('Скидка: ${((set.costPrice - set.setPrice) / set.costPrice * 100).toStringAsFixed(1)}%'),
                                    backgroundColor: Colors.red[100],
                                  ),
                                                                 if (set.isPopular || set.isNew)
                                   Row(
                                     children: [
                                       if (set.isPopular)
                                         Chip(
                                           label: const Text('🔥 Популярный'),
                                           backgroundColor: Colors.red[100],
                                         ),
                                       if (set.isNew)
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
                                  onPressed: () => _showEditSetDialog(set),
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Редактировать',
                                ),
                                IconButton(
                                  onPressed: () => _deleteSet(set),
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

  void _showCompositionEditor() async {
    try {
      if (_editingSet != null) {
        // Редактирование существующего сета
        final compositionResponse = await ApiService.getSetComposition(_editingSet!.id!);
        print('🔍 DEBUG: Ответ API состава сета: $compositionResponse');
        
        // Проверяем структуру ответа
        final items = compositionResponse['composition'] as List? ?? [];
        print('🔍 DEBUG: Найдено элементов в составе: ${items.length}');
        
        if (items.isNotEmpty) {
          print('🔍 DEBUG: Первый элемент: ${items.first}');
        }
        
        final currentComposition = items.map((item) {
          print('🔍 DEBUG: Обрабатываем элемент: $item');
          return SetCompositionItem(
            itemId: item['roll_id'] as int? ?? 0,
            itemName: (item['roll_name'] ?? '').toString(),
            itemCostPrice: (item['roll_cost_price'] as num?)?.toDouble() ?? 0.0,
            itemSalePrice: (item['roll_sale_price'] as num?)?.toDouble() ?? 0.0,
            itemType: 'roll', // Пока только роллы из API
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          );
        }).toList();
        
        print('🔍 DEBUG: Создано элементов SetCompositionItem: ${currentComposition.length}');
        
        // Показываем редактор состава сета
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => SetCompositionEditorWidget(
            setId: _editingSet!.id!,
            setName: _editingSet!.name,
            currentComposition: currentComposition,
          ),
        );

        // Если состав был изменен, обновляем данные
        if (result == true) {
          await _loadSets(); // Перезагружаем сеты для обновления себестоимости
          // Обновляем поля формы на случай, если описание/цены изменились после сохранения состава
          final refreshed = _sets.firstWhere((s) => s.id == _editingSet!.id, orElse: () => _editingSet!);
          _descriptionController.text = refreshed.description ?? '';
          _costPriceController.text = refreshed.costPrice.toString();
          _setPriceController.text = refreshed.setPrice.toString();
        }
      } else {
        // Создание нового сета - сначала нужно создать сет
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сначала создайте сет, а затем отредактируйте его состав'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Ошибка в _showCompositionEditor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки состава сета: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
