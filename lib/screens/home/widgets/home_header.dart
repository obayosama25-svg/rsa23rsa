import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../models/user_account.dart';

class HomeHeader extends StatelessWidget {
  final UserAccount? account;
  final VoidCallback onThemeToggle;

  const HomeHeader({
    super.key,
    required this.account,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    String name = account?.firstName ?? 'عميلنا العزيز';

    return FadeInDown(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // اسم العميل
          Expanded(
            child: Text(
              'مرحباً $name',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          // زر التبديل بين الوضع الليلي والنهاري العصري
          GestureDetector(
            onTap: onThemeToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                      : const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  width: 1.2,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          blurRadius: 12,
                          spreadRadius: 1,
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      key: ValueKey<bool>(isDark),
                      color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF475569),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isDark ? 'نهاري' : 'ليلي',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF334155),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
