import 'package:flutter/material.dart';

class CustomizationOptionsWidget extends StatelessWidget {
  const CustomizationOptionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Настройки',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Острота:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Без острого'),
                selected: true,
                onSelected: (selected) {},
              ),
              ChoiceChip(
                label: const Text('Слабо'),
                selected: false,
                onSelected: (selected) {},
              ),
              ChoiceChip(
                label: const Text('Средне'),
                selected: false,
                onSelected: (selected) {},
              ),
              ChoiceChip(
                label: const Text('Остро'),
                selected: false,
                onSelected: (selected) {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Дополнительно:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('Имбирь (+20₽)'),
            value: false,
            onChanged: (value) {},
          ),
          CheckboxListTile(
            title: const Text('Васаби (+15₽)'),
            value: false,
            onChanged: (value) {},
          ),
          CheckboxListTile(
            title: const Text('Соевый соус (+10₽)'),
            value: false,
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }
}