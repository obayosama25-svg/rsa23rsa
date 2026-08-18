import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_colors.dart';
import '../widgets/cyber_background.dart';
import 'telecom_screen.dart';
import 'electricity_screen.dart';
import 'airlines_screen.dart';
import 'education_screen.dart';

class ServiceItem {
  final String title;
  final IconData icon;
  final List<Color> gradientColors;

  ServiceItem({
    required this.title,
    required this.icon,
    required this.gradientColors,
  });
}

class MoreServicesScreen extends StatelessWidget {
  const MoreServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<ServiceItem> services = [
      ServiceItem(
        title: 'اتصالات وانترنت',
        icon: Icons.wifi_tethering_rounded,
        gradientColors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)], // Blue
      ),
      ServiceItem(
        title: 'شراء الكهرباء',
        icon: Icons.bolt_rounded,
        gradientColors: [const Color(0xFFF59E0B), const Color(0xFFB45309)], // Amber
      ),
      ServiceItem(
        title: 'خطوط الطيران',
        icon: Icons.flight_takeoff_rounded,
        gradientColors: [const Color(0xFF06B6D4), const Color(0xFF0E7490)], // Cyan
      ),
      ServiceItem(
        title: 'التعليم',
        icon: Icons.school_rounded,
        gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF5B21B6)], // Purple
      ),
      ServiceItem(
        title: 'التسوق عبر الانترنت',
        icon: Icons.shopping_bag_rounded,
        gradientColors: [const Color(0xFFEC4899), const Color(0xFFBE185D)], // Pink
      ),
      ServiceItem(
        title: 'الخدمات الحكومية',
        icon: Icons.account_balance_rounded,
        gradientColors: [const Color(0xFF64748B), const Color(0xFF334155)], // Slate
      ),
      ServiceItem(
        title: 'الوقود',
        icon: Icons.local_gas_station_rounded,
        gradientColors: [const Color(0xFFEF4444), const Color(0xFFB91C1C)], // Red
      ),
      ServiceItem(
        title: 'وسائل النقل',
        icon: Icons.directions_bus_rounded,
        gradientColors: [const Color(0xFF10B981), const Color(0xFF047857)], // Emerald
      ),
      ServiceItem(
        title: 'خدمة المستشفيات',
        icon: Icons.local_hospital_rounded,
        gradientColors: [const Color(0xFFF43F5E), const Color(0xFFBE123C)], // Rose
      ),
      ServiceItem(
        title: 'شحن الرصيد الجوال',
        icon: Icons.phone_iphone_rounded,
        gradientColors: [const Color(0xFF14B8A6), const Color(0xFF0F766E)], // Teal
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
                      isDark
                          ? AppColors.primaryBlue.withValues(alpha: 0.15)
                          : AppColors.primaryBlue.withValues(alpha: 0.05),
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
                        childAspectRatio: 1.05,
                      ),
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return FadeInUp(
                          delay: Duration(milliseconds: 50 * index),
                          duration: const Duration(milliseconds: 400),
                          child: _buildServiceCard(context, service, isDark),
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
          Text(
            'المزيد من الخدمات',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceItem service, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
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
            if (service.title == 'اتصالات وانترنت') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TelecomScreen(),
                ),
              );
            } else if (service.title == 'شراء الكهرباء') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ElectricityScreen(),
                ),
              );
            } else if (service.title == 'خطوط الطيران') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AirlinesScreen(),
                ),
              );
            } else if (service.title == 'التعليم') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EducationScreen(),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: service.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: service.gradientColors.first.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    service.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  service.title,
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
