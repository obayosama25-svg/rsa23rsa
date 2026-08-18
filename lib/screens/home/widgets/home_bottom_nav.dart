import 'package:flutter/material.dart';

class HomeBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool showStatistics;

  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.showStatistics = true,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: 70,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withValues(alpha: 0.9) : Colors.black,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_filled,
              label: 'الرئيسية',
              isActive: currentIndex == 0,
            ),

            if (showStatistics)
              _buildNavItem(
                index: 2,
                icon: Icons.bar_chart_rounded,
                label: 'الإحصائيات',
                isActive: currentIndex == 2,
              ),
            _buildNavItem(
              index: 3,
              icon: Icons.person_rounded,
              label: 'الملف',
              isActive: currentIndex == 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    if (isActive && index == 0) {
      // Home pill style
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            const Icon(Icons.home_filled, color: Colors.black, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white54,
          size: 24,
        ),
      ),
    );
  }
}
