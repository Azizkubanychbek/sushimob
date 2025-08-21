import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class AdminOtherItemsWidget extends StatefulWidget {
  const AdminOtherItemsWidget({super.key});

  @override
  State<AdminOtherItemsWidget> createState() => _AdminOtherItemsWidgetState();
}

class _AdminOtherItemsWidgetState extends State<AdminOtherItemsWidget> {
  List<Map<String, dynamic>> _otherItems = [];
  bool _isLoading = true;
  Map<String, dynamic>? _editingItem;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOtherItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadOtherItems() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final items = await ApiService.getOtherItems();
      setState(() {
        _otherItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки товаров: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddItemDialog() {
    _resetForm();
    _showItemDialog(isEditing: false);
  }

  void _showEditItemDialog(Map<String, dynamic> item) {
    _editingItem = item;
    _nameController.text = item['name'];
    _descriptionController.text = item['description'] ?? '';
    _costPriceController.text = item['cost_price'].toString();
    _salePriceController.text = item['sale_price'].toString();
    _categoryController.text = item['category'] ?? '';
    _imageUrlController.text = item['image_url'] ?? '';
    _showItemDialog(isEditing: true);
  }

  void _resetForm() {
    _editingItem = null;
    _nameController.clear();
    _descriptionController.clear();
    _costPriceController.clear();
    _salePriceController.clear();
    _categoryController.clear();
    _imageUrlController.clear();
  }

  void _showItemDialog({required bool isEditing}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Редактировать товар' : 'Добавить товар'),
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
                TextFormField(
                  controller: _costPriceController,
                  decoration: const InputDecoration(labelText: 'Себестоимость'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите себестоимость';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Введите корректное число';
                    }
                    return null;
                  },
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
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    hintText: 'Например: соусы, напитки, десерты',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите категорию';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'URL изображения'),
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
            onPressed: _saveItem,
            child: Text(isEditing ? 'Сохранить' : 'Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final itemData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'cost_price': double.parse(_costPriceController.text),
        'sale_price': double.parse(_salePriceController.text),
        'category': _categoryController.text.trim(),
        'image_url': _imageUrlController.text.trim(),
      };

      if (_editingItem != null) {
        // Обновление существующего товара
        await ApiService.updateAdminOtherItem(_editingItem!['id'], itemData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Товар успешно обновлен'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Создание нового товара
        await ApiService.createAdminOtherItem(itemData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Товар успешно создан'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.of(context).pop();
      _resetForm();
      _loadOtherItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: Text('Вы уверены, что хотите удалить товар "${item['name']}"?'),
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
        await ApiService.deleteAdminOtherItem(item['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Товар успешно удален'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOtherItems();
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
                      'Управление товарами (${_otherItems.length})',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _showAddItemDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить товар'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadOtherItems,
                  child: _otherItems.isEmpty
                      ? const Center(
                          child: Text(
                            'Товары не найдены',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _otherItems.length,
                          itemBuilder: (context, index) {
                            final item = _otherItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal,
                                  child: Text(
                                    item['name'][0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  item['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (item['description']?.isNotEmpty == true)
                                      Text(item['description']),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text('Себест: ${item['cost_price']}₽'),
                                          backgroundColor: Colors.orange[100],
                                        ),
                                        const SizedBox(width: 8),
                                        Chip(
                                          label: Text('Продажа: ${item['sale_price']}₽'),
                                          backgroundColor: Colors.green[100],
                                        ),
                                      ],
                                    ),
                                    if (item['category']?.isNotEmpty == true)
                                      Chip(
                                        label: Text('Категория: ${item['category']}'),
                                        backgroundColor: Colors.blue[100],
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _showEditItemDialog(item),
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      tooltip: 'Редактировать',
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteItem(item),
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
