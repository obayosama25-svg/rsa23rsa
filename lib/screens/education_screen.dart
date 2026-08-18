import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_colors.dart';
import '../widgets/cyber_background.dart';
import 'education/university_payment_screen.dart';

class UniversityOption {
  final String name;
  final String description;
  final Color accentColor;

  UniversityOption({
    required this.name,
    required this.description,
    required this.accentColor,
  });
}

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<UniversityOption> universities = [
      UniversityOption(
        name: 'جامعة قاردن ستي',
        description: 'سداد الرسوم الدراسية والتسجيل بجامعة قاردن ستي',
        accentColor: const Color(0xFF6D28D9),
      ),
      UniversityOption(
        name: 'جامعة وادي النيل',
        description: 'سداد الخدمات الأكاديمية بجامعة وادي النيل',
        accentColor: const Color(0xFF0EA5E9),
      ),
      UniversityOption(
        name: 'جامعة النيلين',
        description: 'سداد الرسوم والخدمات بجامعة النيلين',
        accentColor: const Color(0xFF10B981),
      ),
      UniversityOption(
        name: 'الجامعة الوطنية',
        description:
            'سداد الرسوم والتسجيل الأكاديمي بالجامعة الوطنية السودانية',
        accentColor: const Color(0xFFF59E0B),
      ),
      UniversityOption(
        name: 'جامعة ابن سينا',
        description: 'سداد رسوم الكليات والخدمات بجامعة ابن سينا',
        accentColor: const Color(0xFFEF4444),
      ),
      UniversityOption(
        name: 'جامعة السودان للعلوم والتكنولوجيا',
        description: 'سداد الرسوم الدراسية والخدمات الأكاديمية بجامعة السودان',
        accentColor: const Color(0xFF8B5CF6),
      ),
      UniversityOption(
        name: 'جامعة العلوم والتقانة',
        description: 'سداد الرسوم الدراسية والتسجيل بجامعة العلوم والتقانة',
        accentColor: const Color(0xFF14B8A6),
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
                      const Color(
                        0xFF8B5CF6,
                      ).withValues(alpha: isDark ? 0.15 : 0.05), // Purple glow
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
                      itemCount: universities.length,
                      itemBuilder: (context, index) {
                        final uni = universities[index];
                        return FadeInUp(
                          delay: Duration(milliseconds: 60 * index),
                          duration: const Duration(milliseconds: 400),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _buildUniversityCard(context, uni, isDark),
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
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
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
                'خدمات التعليم والجامعات',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Education & Universities Pay',
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

  Widget _buildUniversityCard(
    BuildContext context,
    UniversityOption uni,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.08)
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UniversityPaymentScreen(universityName: uni.name),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                        : const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: uni.accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: uni.accentColor.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        uni.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        uni.description,
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
