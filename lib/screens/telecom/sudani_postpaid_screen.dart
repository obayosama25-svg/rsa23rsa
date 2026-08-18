import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cyber_background.dart';

class SudaniPostpaidOption {
  final String title;
  final IconData icon;

  SudaniPostpaidOption({
    required this.title,
    required this.icon,
  });
}

class SudaniPostpaidScreen extends StatelessWidget {
  const SudaniPostpaidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<SudaniPostpaidOption> options = [
      SudaniPostpaidOption(
        title: 'خدمة الإنترنت الأرضي ADSL',
        icon: Icons.router_rounded,
      ),
      SudaniPostpaidOption(
        title: 'موبايل الدفع الآجل',
        icon: Icons.phone_android_rounded,
      ),
      SudaniPostpaidOption(
        title: 'الفايبر',
        icon: Icons.cable_rounded,
      ),
      SudaniPostpaidOption(
        title: 'الهاتف الأرضي',
        icon: Icons.phone_in_talk_rounded,
      ),
      SudaniPostpaidOption(
        title: 'ملف مشترك',
        icon: Icons.folder_shared_rounded,
      ),
      SudaniPostpaidOption(
        title: 'إنترنت السعات العريضة',
        icon: Icons.cell_tower_rounded,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 1.2,
                    colors: [
                      const Color(0xFF0369A1).withValues(alpha: isDark ? 0.15 : 0.05), // Sudani Blue glow
                      AppColors.background(context),
                    ],
                  ),
                ),
              ),
            ),
            const TechGridBackground(),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, isDark),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        return FadeInUp(
                          delay: Duration(milliseconds: 50 * index),
                          duration: const Duration(milliseconds: 400),
                          child: _buildServiceCard(context, option, isDark),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'دفع فواتير سوداني',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Sudani Postpaid Bills',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, SudaniPostpaidOption option, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF0369A1).withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF0369A1).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            // Placeholder for actual payment execution
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xFFF97316).withValues(alpha: 0.15) // Sudani Orange accent
                        : const Color(0xFFF97316).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      option.icon,
                      color: const Color(0xFFF97316),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  option.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
