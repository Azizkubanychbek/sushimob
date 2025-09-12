import 'package:flutter/material.dart';
import '../../services/loyalty_service.dart';
import '../../models/loyalty_card.dart';
import '../../models/loyalty_roll.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({Key? key}) : super(key: key);

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await LoyaltyService.refreshAll();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Накопительные карты',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.credit_card),
              text: 'Мои карты',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'История',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCardsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildCardsTab() {
    if (LoyaltyService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final cards = LoyaltyService.cards;
    final completedCards = LoyaltyService.completedCards;
    final inProgressCards = LoyaltyService.inProgressCards;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статистика
            _buildStatsCard(),
            const SizedBox(height: 20),

            // Заполненные карты
            if (completedCards.isNotEmpty) ...[
              _buildSectionTitle('Готовы к использованию'),
              const SizedBox(height: 12),
              ...completedCards.map((card) => _buildCompletedCard(card)),
              const SizedBox(height: 20),
            ],

            // Карты в процессе
            if (inProgressCards.isNotEmpty) ...[
              _buildSectionTitle('В процессе накопления'),
              const SizedBox(height: 12),
              ...inProgressCards.map((card) => _buildInProgressCard(card)),
            ],

            // Если карт нет
            if (cards.isEmpty) ...[
              const SizedBox(height: 40),
              _buildEmptyState(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (LoyaltyService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final history = LoyaltyService.history;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: history.isEmpty
          ? _buildEmptyHistoryState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final usage = history[index];
                return _buildHistoryItem(usage);
              },
            ),
    );
  }

  Widget _buildStatsCard() {
    final totalProgress = LoyaltyService.totalProgress;
    final usedCardsCount = LoyaltyService.usedCardsCount;
    final completedCardsCount = LoyaltyService.completedCards.length;
    final inProgressCardsCount = LoyaltyService.inProgressCards.length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ваша статистика',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Использовано карт',
                    usedCardsCount.toString(),
                    Icons.card_giftcard,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Готовых карт',
                    completedCardsCount.toString(),
                    Icons.check_circle,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'В процессе',
                    inProgressCardsCount.toString(),
                    Icons.hourglass_empty,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCompletedCard(LoyaltyCard card) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.cardNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Карта заполнена! 🎉',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '8/8',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showUseCardDialog(card),
                icon: const Icon(Icons.card_giftcard),
                label: const Text('Использовать карту'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInProgressCard(LoyaltyCard card) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.cardNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Заполнено ${card.filledRolls} из 8',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${card.filledRolls}/8',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: card.progressPercent / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(dynamic usage) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.card_giftcard, color: Colors.white),
        ),
        title: Text(
          usage.roll?.name ?? 'Неизвестный ролл',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Карта: ${usage.cardNumber}'),
            Text(
              'Использовано: ${_formatDate(usage.usedAt)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        trailing: Text(
          'БЕСПЛАТНО',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.credit_card_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'У вас пока нет накопительных карт',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Делайте заказы от 1000₽ и накапливайте роллы!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'История пуста',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Используйте заполненные карты, чтобы увидеть историю здесь',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showUseCardDialog(LoyaltyCard card) {
    showDialog(
      context: context,
      builder: (context) => _UseCardDialog(card: card),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class _UseCardDialog extends StatefulWidget {
  final LoyaltyCard card;

  const _UseCardDialog({required this.card});

  @override
  State<_UseCardDialog> createState() => _UseCardDialogState();
}

class _UseCardDialogState extends State<_UseCardDialog> {
  LoyaltyRoll? selectedRoll;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableRolls();
  }

  Future<void> _loadAvailableRolls() async {
    await LoyaltyService.loadAvailableRolls();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableRolls = LoyaltyService.availableRolls;

    return AlertDialog(
      title: const Text('Выберите ролл'),
      content: SizedBox(
        width: double.maxFinite,
        child: availableRolls.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                shrinkWrap: true,
                itemCount: availableRolls.length,
                itemBuilder: (context, index) {
                  final loyaltyRoll = availableRolls[index];
                  final roll = loyaltyRoll.roll;
                  if (roll == null) return const SizedBox.shrink();

                  return RadioListTile<LoyaltyRoll>(
                    title: Text(roll.name),
                    subtitle: Text('${roll.salePrice}₽'),
                    value: loyaltyRoll,
                    groupValue: selectedRoll,
                    onChanged: (value) {
                      setState(() {
                        selectedRoll = value;
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: selectedRoll != null && !isLoading
              ? _useCard
              : null,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Использовать'),
        ),
      ],
    );
  }

  Future<void> _useCard() async {
    if (selectedRoll == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final success = await LoyaltyService.useCard(
        widget.card.id,
        selectedRoll!.rollId,
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ролл "${selectedRoll!.roll?.name}" добавлен бесплатно!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка использования карты'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
