import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../theme/app_colors.dart';

/// مركز المساعدة
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});
  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int? _expandedIndex;

  final List<_FaqItem> _faqs = const [
    _FaqItem('كيف أحوّل أموالاً لحساب آخر؟',
      'من الشاشة الرئيسية اضغط على "تحويل"، ثم أدخل رقم الحساب المستلم والمبلغ المطلوب. أكّد العملية بإدخال الرقم السري.'),
    _FaqItem('ما الحد الأقصى للتحويل اليومي؟',
      'الحد الأقصى للتحويل اليومي هو 50,000 جنيه سوداني. للرفع تواصل مع خدمة العملاء.'),
    _FaqItem('كيف أدفع عبر NFC؟',
      'افتح التطبيق → اضغط "دفع NFC" → اقترب من الجهاز بمسافة 4 سم وانتظر تأكيد العملية.'),
    _FaqItem('نسيت الرقم السري، ماذا أفعل؟',
      'اضغط على "نسيت الرقم السري" في شاشة الدخول، وسيتم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني.'),
    _FaqItem('كيف أطلب كشف حساب؟',
      'من القائمة الرئيسية اضغط "كشف الحساب"، اختر الفترة الزمنية وحمّل الكشف بصيغة PDF.'),
    _FaqItem('هل التطبيق متاح 24/7؟',
      'نعم، التطبيق متاح على مدار الساعة طوال أيام الأسبوع. خدمة العملاء الهاتفية متاحة 8 صباحاً حتى 10 مساءً.'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
              title: const Text('مركز المساعدة',
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
                    // ── بانر التواصل ──
                    FadeInDown(duration: const Duration(milliseconds: 380),
                      child: _ContactBanner(isDark: isDark)),
                    const SizedBox(height: 28),

                    // ── وسائل التواصل ──
                    FadeInUp(delay: const Duration(milliseconds: 80), duration: const Duration(milliseconds: 380),
                      child: _buildLabel('تواصل معنا', isDark)),
                    const SizedBox(height: 12),
                    FadeInUp(delay: const Duration(milliseconds: 100), duration: const Duration(milliseconds: 380),
                      child: Row(children: [
                        Expanded(child: _ContactCard(icon: Icons.phone_rounded, label: 'اتصل بنا', value: '249-000-123', accent: const Color(0xFF10B981), isDark: isDark)),
                        const SizedBox(width: 12),
                        Expanded(child: _ContactCard(icon: Icons.chat_bubble_outline_rounded, label: 'واتساب', value: 'دردشة مباشرة', accent: const Color(0xFF25D366), isDark: isDark)),
                        const SizedBox(width: 12),
                        Expanded(child: _ContactCard(icon: Icons.email_outlined, label: 'البريد', value: 'support@bank249.sd', accent: const Color(0xFF0052FF), isDark: isDark, small: true)),
                      ])),
                    const SizedBox(height: 28),

                    // ── الأسئلة الشائعة ──
                    FadeInUp(delay: const Duration(milliseconds: 160), duration: const Duration(milliseconds: 380),
                      child: _buildLabel('الأسئلة الشائعة', isDark)),
                    const SizedBox(height: 12),
                    ...List.generate(_faqs.length, (i) => FadeInUp(
                      delay: Duration(milliseconds: 180 + i * 40),
                      duration: const Duration(milliseconds: 380),
                      child: _FaqTile(
                        item: _faqs[i],
                        isDark: isDark,
                        isExpanded: _expandedIndex == i,
                        onTap: () => setState(() => _expandedIndex = _expandedIndex == i ? null : i),
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

// ══════════════════════════════════════════════════════════════
Widget _buildLabel(String t, bool isDark) => Padding(padding: const EdgeInsets.only(right: 4),
  child: Text(t, style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600)));

class _ContactBanner extends StatelessWidget {
  final bool isDark;
  const _ContactBanner({required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF0B2545), Color(0xFF1A3A6B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 28)),
      const SizedBox(width: 16),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('خدمة العملاء', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        SizedBox(height: 3),
        Text('متاحون 24/7 للإجابة على استفساراتك', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12)),
        SizedBox(height: 8),
        Row(children: [
          Icon(Icons.circle, color: Color(0xFF4ADE80), size: 8),
          SizedBox(width: 6),
          Text('متصل الآن', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ])),
    ]),
  );
}

class _ContactCard extends StatelessWidget {
  final IconData icon; final String label, value; final Color accent; final bool isDark; final bool small;
  const _ContactCard({required this.icon, required this.label, required this.value, required this.accent, required this.isDark, this.small = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {},
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1826) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: accent, size: 18)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF94A3B8), fontSize: small ? 9 : 11), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _FaqItem {
  final String q, a;
  const _FaqItem(this.q, this.a);
}

class _FaqTile extends StatelessWidget {
  final _FaqItem item; final bool isDark, isExpanded; final VoidCallback onTap;
  const _FaqTile({required this.item, required this.isDark, required this.isExpanded, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0D1826) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: isExpanded ? const Color(0xFF0052FF).withValues(alpha: 0.3) : (isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE2E8F0))),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFF0052FF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.help_outline_rounded, color: Color(0xFF0052FF), size: 16)),
                const SizedBox(width: 12),
                Expanded(child: Text(item.q, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w600))),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                ),
              ]),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                Text(item.a, style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 13, height: 1.6)),
              ],
            ]),
          ),
        ),
      ),
    ),
  );
}
