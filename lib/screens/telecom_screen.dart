import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_colors.dart';
import '../widgets/cyber_background.dart';
import 'telecom/zain_services_screen.dart';
import 'telecom/sudani_services_screen.dart';

class TelecomProvider {
  final String name;
  final String description;
  final List<Color> gradientColors;
  final String imagePath;

  TelecomProvider({
    required this.name,
    required this.description,
    required this.gradientColors,
    required this.imagePath,
  });
}

class TelecomScreen extends StatelessWidget {
  const TelecomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<TelecomProvider> providers = [
      TelecomProvider(
        name: 'زين',
        description: 'شراء رصيد مكالمات وباقات إنترنت زين',
        gradientColors: [const Color(0xFF1A1A2E), const Color(0xFF7B2FBE)],
        imagePath: 'assets/images/zain_logo.jpg',
      ),
      TelecomProvider(
        name: 'سوداني',
        description: 'شراء رصيد مكالمات وباقات إنترنت سوداني',
        gradientColors: [const Color(0xFF0D47A1), const Color(0xFF1565C0)],
        imagePath: 'assets/images/sudani_logo.png',
      ),
      TelecomProvider(
        name: 'إم تي إن',
        description: 'شراء رصيد مكالمات وباقات إنترنت MTN',
        gradientColors: [const Color(0xFFFFC107), const Color(0xFFFF8F00)],
        imagePath: 'assets/images/mtn_logo.png',
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
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      itemCount: providers.length,
                      itemBuilder: (context, index) {
                        final provider = providers[index];
                        return FadeInRight(
                          delay: Duration(milliseconds: 100 * index),
                          duration: const Duration(milliseconds: 500),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _buildProviderCard(context, provider, isDark),
                          ),
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
            'اتصالات وانترنت',
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

  Widget _buildProviderCard(BuildContext context, TelecomProvider provider, bool isDark) {
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
            if (provider.name == 'زين') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ZainServicesScreen(),
                ),
              );
            } else if (provider.name == 'سوداني') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SudaniServicesScreen(),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: provider.gradientColors.last.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      provider.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: provider.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cell_tower_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        provider.description,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark ? Colors.white24 : Colors.black26,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
