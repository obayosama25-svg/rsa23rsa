import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../models/user_account.dart';

class HomeHeader extends StatelessWidget {
  final UserAccount? account;
  final VoidCallback onThemeToggle;
  final VoidCallback onNotificationsTap;

  const HomeHeader({
    super.key,
    required this.account,
    required this.onThemeToggle,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    String name = account?.firstName ?? 'عميلنا العزيز';

    return FadeInDown(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(
                'مرحباً $name!',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              _buildCircleButton(
                icon: Icons.notifications_none_rounded,
                onPressed: onNotificationsTap,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 1,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                  backgroundImage: const AssetImage(
                    'assets/images/user_profile.jpeg',
                  ),
                  onBackgroundImageError: (e, s) => Icon(
                    Icons.person_outline_rounded,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black87,
          size: 22,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
