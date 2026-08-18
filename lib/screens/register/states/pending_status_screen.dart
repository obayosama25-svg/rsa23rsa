import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:sudacards/theme/app_colors.dart';
import 'package:sudacards/widgets/cyber_background.dart';
import 'package:sudacards/screens/login_screen.dart';

class PendingStatusScreen extends StatefulWidget {
  const PendingStatusScreen({super.key});

  @override
  State<PendingStatusScreen> createState() => _PendingStatusScreenState();
}

class _PendingStatusScreenState extends State<PendingStatusScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(); // تكرار تدوير مؤشر الانتظار
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    setState(() => _isLoading = true);
    // محاكاة التحقق من السيرفر
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حالة الطلب: لا يزال حسابك قيد المراجعة والتدقيق.',
            style: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // 1. الخلفية التقنية الشبكية
          const Positioned.fill(child: TechGridBackground()),

          // 2. الهالات الضوئية المتوهجة في الخلفية
          Positioned(
            top: -100,
            right: -100,
            child: _buildGlowingOrb(AppColors.primaryBlue.withValues(alpha: 0.15), 300),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: _buildGlowingOrb(AppColors.primaryGreen.withValues(alpha: 0.1), 250),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 3. أيقونة الساعة الرملية المتوهجة والمتحركة ثلاثية الأبعاد
                    ZoomIn(
                      duration: const Duration(milliseconds: 800),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildPulseCircle(160, AppColors.primaryBlue.withValues(alpha: 0.05)),
                          _buildPulseCircle(120, AppColors.primaryBlue.withValues(alpha: 0.1)),
                          
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.5), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: RotationTransition(
                                turns: _rotationController,
                                child: const Icon(
                                  Icons.hourglass_empty_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 4. حاوية البيانات الزجاجية للخطوات (Glassmorphism Card)
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.glassBorder, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'حسابك قيد المراجعة والتدقيق',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'لقد استلمنا مستنداتك بنجاح. يقوم فريق الامتثال ومكافحة الاحتيال بمراجعة طلبك حالياً لضمان أعلى مستويات الأمان لحسابك.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 28),

                                // 5. متتبع خطوات العملية (Interactive Step Progress)
                                const Divider(color: Colors.white10),
                                const SizedBox(height: 16),
                                _buildTimelineStep(
                                  title: 'إرسال طلب التسجيل',
                                  description: 'تم استلام البيانات والمستندات بنجاح',
                                  status: StepStatus.completed,
                                ),
                                _buildTimelineConnector(true),
                                _buildTimelineStep(
                                  title: 'مراجعة الهوية والامتثال',
                                  description: 'جاري مطابقة المستندات والتحقق رقمياً',
                                  status: StepStatus.active,
                                ),
                                _buildTimelineConnector(false),
                                _buildTimelineStep(
                                  title: 'تفعيل الحساب البنكي',
                                  description: 'إصدار الحساب الافتراضي وتفعيل محفظة سوداكارد',
                                  status: StepStatus.pending,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 6. زر التحديث المتوهج
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            if (!_isLoading)
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(alpha: 0.25),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.darkBackground,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _refreshStatus,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: AppColors.darkBackground,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(SolarIconsOutline.restart, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'تحديث حالة الطلب',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 7. خيار الخروج أو تبديل الحساب
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'تسجيل الخروج أو تبديل الحساب',
                          style: TextStyle(
                            color: Colors.white54,
                            decoration: TextDecoration.underline,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String description,
    required StepStatus status,
  }) {
    IconData icon;
    Color iconColor;
    Color titleColor;
    Color descColor;

    switch (status) {
      case StepStatus.completed:
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.primaryGreen;
        titleColor = Colors.white;
        descColor = Colors.white54;
        break;
      case StepStatus.active:
        icon = Icons.circle_outlined;
        iconColor = AppColors.primaryBlue;
        titleColor = AppColors.primaryBlue;
        descColor = Colors.white70;
        break;
      case StepStatus.pending:
        icon = Icons.circle_outlined;
        iconColor = Colors.white24;
        titleColor = Colors.white38;
        descColor = Colors.white24;
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        status == StepStatus.active
            ? Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  border: Border.all(color: AppColors.primaryBlue, width: 2),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              )
            : Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: descColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector(bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(right: 11.0),
      child: Container(
        width: 2,
        height: 24,
        color: isActive ? AppColors.primaryGreen : Colors.white12,
      ),
    );
  }
}

enum StepStatus {
  completed,
  active,
  pending,
}
