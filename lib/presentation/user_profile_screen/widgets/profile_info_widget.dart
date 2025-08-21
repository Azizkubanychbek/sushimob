import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class ProfileInfoWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;

  const ProfileInfoWidget({
    super.key,
    required this.icon,
    required this.title,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: value != null && value!.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  value!,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Не указано',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: Theme.of(context).cardColor.withOpacity(0.3),
      ),
    );
  }
}

class ProfileInfoSection extends StatelessWidget {
  const ProfileInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final user = authService.currentUser;
    final isLoggedIn = authService.isLoggedIn;

    if (!isLoggedIn || user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Войдите в систему, чтобы увидеть свою информацию',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileInfoWidget(
          icon: Icons.person,
          title: 'Имя',
          value: user.name,
        ),
        ProfileInfoWidget(
          icon: Icons.email,
          title: 'Email',
          value: user.email,
        ),
        ProfileInfoWidget(
          icon: Icons.phone,
          title: 'Телефон',
          value: user.phone,
        ),
        ProfileInfoWidget(
          icon: Icons.location_on,
          title: 'Адрес доставки',
          value: user.address,
        ),
        ProfileInfoWidget(
          icon: Icons.star,
          title: 'Бонусные баллы',
          value: user.loyaltyPoints != null ? '${user.loyaltyPoints} баллов' : null,
        ),
      ],
    );
  }
}
