import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import '../../theme/app_colors.dart';
import '../../models/user_account.dart';

/// شاشة البيانات الشخصية — عرض فقط (للقراءة)
class PersonalInfoScreen extends StatelessWidget {
  final UserAccount? account;

  const PersonalInfoScreen({super.key, this.account});

  // ─── بيانات العرض ─────────────────────────────────────────────
  String get _fullName    => account?.fullName      ?? 'محمد عبد العزيز الحسن';
  String get _firstName   => account?.firstName     ?? 'محمد';
  String get _middleName  => account?.middleName    ?? 'عبد العزيز';
  String get _lastName    => account?.lastName      ?? 'الحسن';
  String get _email       => account?.email         ?? 'user@sudacard.com';
  String get _accountNum  => account?.accountNumber ?? '24912345';
  String get _userId      => account?.id            ?? '123456789012';
  String get _userType    => account?.userType      ?? 'personal';

  String get _userTypeLabel {
    switch (_userType) {
      case 'merchant': return 'تاجر';
      case 'company': return 'شركة';
      case 'agent': return 'وكيل';
      default: return 'فردي';
    }
  }

  String get _dateOfBirth {
    final d = account?.dateOfBirth ?? DateTime(1990, 1, 1);
    return '${d.day.toString().padLeft(2, '0')} / '
        '${d.month.toString().padLeft(2, '0')} / '
        '${d.year}';
  }

  String get _memberSince {
    final d = account?.creationDate ?? DateTime(2023, 1, 1);
    const months = [
      'يناير','فبراير','مارس','أبريل','مايو','يونيو',
      'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String get _initials {
    final p = _fullName.split(' ').where((s) => s.isNotEmpty).toList();
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}';
    if (p.isNotEmpty) return p[0][0];
    return 'م';
  }

  void _copyToClipboard(BuildContext ctx, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text('تم نسخ $label'),
        ]),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC);
    final Color cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final Color labelColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
    final Color valueColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color dividerColor = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'البيانات الشخصية',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Column(
            children: [
              // ── الأفاتار والاسم ────────────────────────────────
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // الأفاتار
                    Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        // شارة نوع الحساب
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _userType == 'personal'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              _userTypeLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _fullName,
                      style: TextStyle(
                        color: valueColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // حالة الحساب
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: (account?.isActive ?? true)
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFDC2626).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (account?.isActive ?? true)
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (account?.isActive ?? true) ? 'حساب نشط ومفعّل' : 'حساب موقوف',
                            style: TextStyle(
                              color: (account?.isActive ?? true)
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),

              // ── الاسم الثلاثي ────────────────────────────────────
              _buildSection(
                title: 'الاسم الثلاثي',
                delay: 100,
                isDark: isDark,
                cardBg: cardBg,
                child: Column(
                  children: [
                    _buildInfoRow('الاسم الأول', _firstName, labelColor, valueColor),
                    Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                    _buildInfoRow('الاسم الأوسط', _middleName.isEmpty ? '—' : _middleName, labelColor, valueColor),
                    Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                    _buildInfoRow('اسم العائلة', _lastName, labelColor, valueColor),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── معلومات التواصل ──────────────────────────────────
              _buildSection(
                title: 'معلومات التواصل',
                delay: 180,
                isDark: isDark,
                cardBg: cardBg,
                child: Builder(builder: (ctx) => _buildInfoRow(
                  'البريد الإلكتروني', _email, labelColor, valueColor,
                  trailing: GestureDetector(
                    onTap: () => _copyToClipboard(ctx, 'البريد', _email),
                    child: Icon(Icons.copy_rounded, size: 16, color: labelColor),
                  ),
                )),
              ),
              const SizedBox(height: 16),

              // ── بيانات الحساب ─────────────────────────────────────
              _buildSection(
                title: 'بيانات الحساب',
                delay: 260,
                isDark: isDark,
                cardBg: cardBg,
                child: Builder(builder: (ctx) => Column(
                  children: [
                    _buildInfoRow('رقم الحساب', _accountNum, labelColor, valueColor,
                      mono: true,
                      trailing: GestureDetector(
                        onTap: () => _copyToClipboard(ctx, 'رقم الحساب', _accountNum),
                        child: Icon(Icons.copy_rounded, size: 16, color: labelColor),
                      ),
                    ),
                    Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                    _buildInfoRow('رقم الهوية', _userId, labelColor, valueColor,
                      mono: true,
                      trailing: GestureDetector(
                        onTap: () => _copyToClipboard(ctx, 'رقم الهوية', _userId),
                        child: Icon(Icons.copy_rounded, size: 16, color: labelColor),
                      ),
                    ),
                    Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                    _buildInfoRow('نوع الحساب', _userTypeLabel, labelColor, valueColor),
                  ],
                )),
              ),
              const SizedBox(height: 16),

              // ── التواريخ ──────────────────────────────────────────
              _buildSection(
                title: 'التواريخ',
                delay: 340,
                isDark: isDark,
                cardBg: cardBg,
                child: Column(
                  children: [
                    _buildInfoRow('تاريخ الميلاد', _dateOfBirth, labelColor, valueColor, mono: true),
                    Divider(height: 1, color: dividerColor, indent: 16, endIndent: 16),
                    _buildInfoRow('عضو منذ', _memberSince, labelColor, valueColor),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── ملاحظة ────────────────────────────────────────────
              FadeInUp(
                delay: const Duration(milliseconds: 420),
                duration: const Duration(milliseconds: 400),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: labelColor),
                    const SizedBox(width: 6),
                    Text(
                      'لتعديل بياناتك تواصل مع خدمة العملاء',
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء قسم كامل (عنوان + بطاقة)
  Widget _buildSection({
    required String title,
    required int delay,
    required bool isDark,
    required Color cardBg,
    required Widget child,
  }) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 450),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 10),
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  /// بناء صف معلومة واحدة
  Widget _buildInfoRow(
    String label, String value, Color labelColor, Color valueColor, {
    bool mono = false,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: mono ? 'Courier' : null,
                    letterSpacing: mono ? 1.5 : 0,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
