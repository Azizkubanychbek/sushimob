import 'package:flutter/material.dart';

class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Сортировка',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('По популярности'),
            leading: Radio<int>(
              value: 0,
              groupValue: 0,
              onChanged: (value) {},
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            title: const Text('По цене (возрастание)'),
            leading: Radio<int>(
              value: 1,
              groupValue: 0,
              onChanged: (value) {},
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            title: const Text('По цене (убывание)'),
            leading: Radio<int>(
              value: 2,
              groupValue: 0,
              onChanged: (value) {},
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            title: const Text('По рейтингу'),
            leading: Radio<int>(
              value: 3,
              groupValue: 0,
              onChanged: (value) {},
            ),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}