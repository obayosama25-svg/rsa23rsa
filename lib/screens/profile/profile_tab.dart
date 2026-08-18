import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../theme/app_colors.dart';
import '../../models/user_account.dart';
import 'personal_info_screen.dart';
import 'security_screen.dart';
import 'notifications_screen.dart';
import 'help_center_screen.dart';
import 'branches_screen.dart';
import 'terms_screen.dart';
import '../nfc/nfc_payment_screen.dart';
import '../../services/session_manager.dart';
import '../login_screen.dart';
class ProfileTab extends StatefulWidget {
  final UserAccount? account;

  const ProfileTab({super.key, this.account});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final collapsed = _scrollController.offset > 190;
      if (collapsed != _showTitle) {
        setState(() => _showTitle = collapsed);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────
  String get _userName => widget.account?.fullName ?? 'محمد عبد العزيز الحسن';
  String get _userEmail => widget.account?.email ?? 'user@sudacard.com';
  String get _accountNumber => widget.account?.accountNumber ?? '24912345';
  String get _formattedAccount {
    final n = _accountNumber;
    if (n.length >= 8) {
      return '${n.substring(0, 4)}  ${n.substring(4, 8)}';
    }
    return n;
  }

  String get _userType => widget.account?.userType ?? 'personal';
  String get _userTypeLabel {
    switch (_userType) {
      case 'merchant': return 'تاجر';
      case 'company': return 'شركة';
      case 'agent': return 'وكيل';
      default: return 'فردي';
    }
  }

  String get _initials {
    final parts = _userName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    if (parts.isNotEmpty) return parts[0][0];
    return 'م';
  }

  String get _memberSince {
    final d = widget.account?.creationDate ?? DateTime(2023, 1, 1);
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String get _formattedBalance {
    final balance = widget.account?.balance ?? 0.0;
    return NumberFormat('#,##0.00', 'en_US').format(balance);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        body: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── Header ─────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 300,
              collapsedHeight: 70,
              pinned: true,
              stretch: true,
              backgroundColor: isDark ? const Color(0xFF0D0D12) : const Color(0xFF0B2545),
              elevation: 0,
              title: AnimatedOpacity(
                opacity: _showTitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: _buildHeader(isDark),
              ),
            ),

            // ─── Content ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // إعدادات الحساب
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 500),
                      child: _buildSectionTitle('إعدادات الحساب', Icons.settings_outlined, isDark),
                    ),
                    const SizedBox(height: 12),
                    ..._buildSettingsGroup([
                      _TileData(
                        icon: Icons.person_outline_rounded,
                        label: 'البيانات الشخصية',
                        sub: 'الاسم، البريد الإلكتروني، تاريخ الميلاد',
                        accent: const Color(0xFF3B82F6),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PersonalInfoScreen(account: widget.account))),
                      ),
                      _TileData(
                        icon: Icons.shield_outlined,
                        label: 'الأمان والخصوصية',
                        sub: 'كلمة المرور، الرقم السري، البصمة',
                        accent: const Color(0xFF10B981),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen())),
                      ),
                      _TileData(
                        icon: Icons.contactless_rounded,
                        label: 'الدفع التلامسي NFC',
                        sub: 'إعداد وإدارة الدفع السريع',
                        accent: const Color(0xFF8B5CF6),
                        onTap: () {
                          if (widget.account?.hasSetPin == true) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const NfcPaymentScreen()));
                          } else {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                backgroundColor: isDark ? const Color(0xFF0D1826) : Colors.white,
                                title: Row(
                                  children: [
                                    const Icon(Icons.security_rounded, color: Color(0xFFF59E0B)),
                                    const SizedBox(width: 10),
                                    Text('عذراً', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                                  ],
                                ),
                                content: Text(
                                  'لا يمكنك استخدام الدفع التلامسي (NFC) أو البطاقة قبل إنشاء رقم PIN خاص بك من إعدادات الأمان.',
                                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.5),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('حسناً', style: TextStyle(color: Color(0xFF0052FF), fontWeight: FontWeight.bold)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen()));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0052FF),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('الذهاب للأمان', style: TextStyle(color: Colors.white)),
                                  )
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      _TileData(
                        icon: Icons.notifications_none_rounded,
                        label: 'الإشعارات',
                        sub: 'تخصيص تنبيهات العمليات والأمان',
                        accent: const Color(0xFFF59E0B),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                      ),
                    ], isDark, 250),

                    const SizedBox(height: 28),

                    // المساعدة والدعم
                    FadeInUp(
                      delay: const Duration(milliseconds: 350),
                      duration: const Duration(milliseconds: 500),
                      child: _buildSectionTitle('المساعدة والدعم', Icons.help_outline_rounded, isDark),
                    ),
                    const SizedBox(height: 12),
                    ..._buildSettingsGroup([
                      _TileData(
                        icon: Icons.headset_mic_outlined,
                        label: 'مركز المساعدة',
                        sub: 'تواصل معنا على مدار الساعة',
                        accent: const Color(0xFF06B6D4),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
                      ),
                      _TileData(
                        icon: Icons.pin_drop_outlined,
                        label: 'الفروع وأجهزة الصراف',
                        sub: 'ابحث عن أقرب فرع أو ATM',
                        accent: const Color(0xFFEC4899),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BranchesScreen())),
                      ),
                      _TileData(
                        icon: Icons.article_outlined,
                        label: 'الشروط والأحكام',
                        accent: const Color(0xFF64748B),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                      ),
                    ], isDark, 400),

                    const SizedBox(height: 32),

                    // زر تسجيل الخروج
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      duration: const Duration(milliseconds: 500),
                      child: _buildLogoutButton(isDark),
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'SudaCard  ·  الإصدار 1.0.0',
                        style: TextStyle(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Header
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0D0D12), const Color(0xFF111827)]
              : [const Color(0xFF0B2545), const Color(0xFF13315C)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // الأفاتار
              ZoomIn(
                duration: const Duration(milliseconds: 500),
                child: Stack(
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
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                            blurRadius: 24,
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
                              color: Colors.black.withValues(alpha: 0.3),
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
              ),
              const SizedBox(height: 14),
              // الاسم
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // البريد
              FadeInUp(
                delay: const Duration(milliseconds: 280),
                child: Text(
                  _userEmail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // شارة العضوية
              FadeInUp(
                delay: const Duration(milliseconds: 340),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, 
                      color: Colors.white.withValues(alpha: 0.4), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'عضو منذ $_memberSince',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
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

  // ═══════════════════════════════════════════════════════════════
  //  Account Card (رقم الحساب + الرصيد)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAccountCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF0B2545)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2545).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // رقم الحساب
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رقم الحساب',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formattedAccount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
              ),
              // زر النسخ
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _accountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('تم نسخ رقم الحساب'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.08),
              height: 1,
            ),
          ),
          // الرصيد المتاح
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الرصيد المتاح',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formattedBalance,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SDG',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Section Title
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Settings Group Builder
  // ═══════════════════════════════════════════════════════════════
  List<Widget> _buildSettingsGroup(List<_TileData> items, bool isDark, int baseDelay) {
    return items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final isFirst = i == 0;
      final isLast = i == items.length - 1;

      return FadeInUp(
        delay: Duration(milliseconds: baseDelay + (i * 40)),
        duration: const Duration(milliseconds: 450),
        child: Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(18) : const Radius.circular(4),
              bottom: isLast ? const Radius.circular(18) : const Radius.circular(4),
            ),
            boxShadow: [
              if (!isDark) BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item.onTap ?? () {},
              borderRadius: BorderRadius.vertical(
                top: isFirst ? const Radius.circular(18) : const Radius.circular(4),
                bottom: isLast ? const Radius.circular(18) : const Radius.circular(4),
              ),
              splashColor: item.accent.withValues(alpha: 0.06),
              highlightColor: item.accent.withValues(alpha: 0.03),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(
                  children: [
                    // أيقونة
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: item.accent.withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(item.icon, color: item.accent, size: 21),
                    ),
                    const SizedBox(width: 14),
                    // النصوص
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item.sub != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.sub!,
                              style: TextStyle(
                                color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // سهم
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 13,
                      color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  //  Logout Button
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLogoutButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await SessionManager().logout();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFFDC2626).withValues(alpha: 0.06),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFDC2626).withValues(alpha: 0.3)
                  : const Color(0xFFFECACA),
              width: 1.5,
            ),
            color: isDark
                ? const Color(0xFFDC2626).withValues(alpha: 0.06)
                : const Color(0xFFFEF2F2),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Tile Data Model
// ═══════════════════════════════════════════════════════════════
class _TileData {
  final IconData icon;
  final String label;
  final String? sub;
  final Color accent;
  final VoidCallback? onTap;

  const _TileData({
    required this.icon,
    required this.label,
    this.sub,
    required this.accent,
    this.onTap,
  });
}
