import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../theme/app_colors.dart';

/// شاشة الشروط والأحكام
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final List<_TermSection> sections = const [
      _TermSection(
        '1. مقدمة واستخدام الخدمة',
        'باستخدامك لتطبيق بنك 249، فإنك توافق على الالتزام بجميع الشروط والأحكام الموضحة هنا. يرجى قراءة هذه الاتفاقية بعناية قبل البدء في استخدام الخدمات المصرفية الرقمية.',
      ),
      _TermSection(
        '2. حماية الحساب والبيانات السرية',
        'يتحمل المستخدم المسؤولية الكاملة عن سرية بيانات تسجيل الدخول ورقم PIN الخاص بالمعاملات. يجب عدم مشاركة الرقم السري مع أي شخص، وفي حال الاشتباه باختراق الحساب يجب التواصل مع البنك فوراً لتجميد الحساب.',
      ),
      _TermSection(
        '3. الحوالات والمعاملات المالية',
        'جميع الحوالات المصرفية والدفع عبر NFC تخضع للتحقق والموافقة الأمنية. بمجرد تأكيد الحوالة وإدخال رقم PIN لا يمكن إلغاء المعاملة أو التراجع عنها.',
      ),
      _TermSection(
        '4. العمولات والرسوم المطبقة',
        'يحتفظ البنك بالحق في تعديل رسوم الخدمات والتحويلات المصرفية وسيتم إعلام المستخدم بأي تغييرات تطرأ على الرسوم قبل تنفيذ المعاملة بوقت كافٍ.',
      ),
      _TermSection(
        '5. تعديل الشروط وإيقاف الخدمة',
        'يحق للبنك تحديث هذه الشروط في أي وقت لتحسين جودة وأمان الخدمة. كما يحق للبنك تجميد أو إيقاف حساب أي مستخدم بشكل مؤقت أو دائم في حال انتهاك الشروط أو استخدام التطبيق بطرق غير مشروعة.',
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF4F6FA),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF0D0D12) : const Color(0xFF0B2545),
              leading: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('الشروط والأحكام',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
              centerTitle: true,
              elevation: 0,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header text
                    FadeInDown(
                      duration: const Duration(milliseconds: 380),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'اتفاقية الاستخدام',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'آخر تحديث: يوليو 2026',
                              style: TextStyle(
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sections
                    ...List.generate(sections.length, (i) => FadeInUp(
                      delay: Duration(milliseconds: i * 60),
                      duration: const Duration(milliseconds: 380),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0D1826) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sections[i].title,
                              style: TextStyle(
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0B2545),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              sections[i].body,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                                fontSize: 13.5,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermSection {
  final String title;
  final String body;
  const _TermSection(this.title, this.body);
}
