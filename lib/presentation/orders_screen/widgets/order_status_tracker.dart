import 'package:flutter/material.dart';

class OrderStatusTracker extends StatelessWidget {
  final String currentStatus;
  final DateTime? orderDate;

  const OrderStatusTracker({
    super.key,
    required this.currentStatus,
    this.orderDate,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = _getOrderStatuses();
    final currentIndex = _getCurrentStatusIndex();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статус заказа',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Прогресс-бар
            _buildProgressBar(statuses, currentIndex),
            
            const SizedBox(height: 16),
            
            // Список статусов
            ...statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isActive = index <= currentIndex;
              final isCurrent = index == currentIndex;
              
              return _buildStatusItem(status, isActive, isCurrent);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(List<OrderStatus> statuses, int currentIndex) {
    return Row(
      children: List.generate(statuses.length - 1, (index) {
        final isCompleted = index < currentIndex;
        final isCurrent = index == currentIndex - 1;
        
        return Expanded(
          child: Row(
            children: [
              // Точка статуса
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isCurrent
                      ? statuses[index].color
                      : Colors.grey[300],
                  border: Border.all(
                    color: isCompleted || isCurrent
                        ? statuses[index].color
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      )
                    : isCurrent
                        ? Container(
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          )
                        : null,
              ),
              
              // Линия между статусами
              if (index < statuses.length - 2)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? statuses[index].color
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusItem(OrderStatus status, bool isActive, bool isCurrent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Иконка статуса
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? status.color : Colors.grey[300],
            ),
            child: Icon(
              status.icon,
              size: 14,
              color: isActive ? Colors.white : Colors.grey[600],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Текст статуса
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.title,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? Colors.black87 : Colors.grey[600],
                    fontSize: isCurrent ? 16 : 14,
                  ),
                ),
                if (status.description != null)
                  Text(
                    status.description!,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          
          // Время (если это текущий статус)
          if (isCurrent && orderDate != null)
            Text(
              _getTimeForStatus(status.title),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  String _getTimeForStatus(String status) {
    if (orderDate == null) return '';
    
    switch (status) {
      case 'Принят':
        return '${orderDate!.hour.toString().padLeft(2, '0')}:${orderDate!.minute.toString().padLeft(2, '0')}';
      case 'Готовится':
        final prepTime = orderDate!.add(const Duration(minutes: 10));
        return '~${prepTime.hour.toString().padLeft(2, '0')}:${prepTime.minute.toString().padLeft(2, '0')}';
      case 'Готов':
        final readyTime = orderDate!.add(const Duration(minutes: 25));
        return '~${readyTime.hour.toString().padLeft(2, '0')}:${readyTime.minute.toString().padLeft(2, '0')}';
      case 'В пути':
        final deliveryTime = orderDate!.add(const Duration(minutes: 35));
        return '~${deliveryTime.hour.toString().padLeft(2, '0')}:${deliveryTime.minute.toString().padLeft(2, '0')}';
      default:
        return '';
    }
  }

  List<OrderStatus> _getOrderStatuses() {
    return [
      OrderStatus(
        title: 'Принят',
        description: 'Заказ принят в обработку',
        icon: Icons.check_circle_outline,
        color: Colors.green,
      ),
      OrderStatus(
        title: 'Готовится',
        description: 'Ваш заказ готовится',
        icon: Icons.restaurant,
        color: Colors.orange,
      ),
      OrderStatus(
        title: 'Готов',
        description: 'Заказ готов к доставке',
        icon: Icons.check_circle,
        color: Colors.blue,
      ),
      OrderStatus(
        title: 'В пути',
        description: 'Курьер в пути к вам',
        icon: Icons.delivery_dining,
        color: Colors.purple,
      ),
      OrderStatus(
        title: 'Доставлен',
        description: 'Заказ успешно доставлен',
        icon: Icons.home,
        color: Colors.teal,
      ),
    ];
  }

  int _getCurrentStatusIndex() {
    switch (currentStatus.toLowerCase()) {
      case 'принят':
        return 0;
      case 'готовится':
        return 1;
      case 'готов':
        return 2;
      case 'в пути':
        return 3;
      case 'доставлен':
        return 4;
      default:
        return 0;
    }
  }
}

class OrderStatus {
  final String title;
  final String? description;
  final IconData icon;
  final Color color;

  OrderStatus({
    required this.title,
    this.description,
    required this.icon,
    required this.color,
  });
}

