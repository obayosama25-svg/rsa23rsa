import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';

/// شاشة إعدادات الإشعارات
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading    = true;
  bool _allNotif     = true;
  bool _transfers    = true;
  bool _deposits     = true;
  bool _withdrawals  = true;
  bool _nfcPayments  = true;
  bool _loginAlerts  = true;
  bool _promotions   = false;
  bool _statements   = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // ── تحميل الإعدادات من التخزين المحلي ──
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _allNotif    = prefs.getBool('notif_allNotif') ?? true;
      _transfers   = prefs.getBool('notif_transfers') ?? true;
      _deposits    = prefs.getBool('notif_deposits') ?? true;
      _withdrawals = prefs.getBool('notif_withdrawals') ?? true;
      _nfcPayments = prefs.getBool('notif_nfcPayments') ?? true;
      _loginAlerts = prefs.getBool('notif_loginAlerts') ?? true;
      _promotions  = prefs.getBool('notif_promotions') ?? false;
      _statements  = prefs.getBool('notif_statements') ?? false;
      _isLoading   = false;
    });
  }

  // ── تحديث الإعدادات (محلياً وفي السيرفر) ──
  Future<void> _updatePreference(String key, bool value, {bool isMaster = false}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // حفظ محلي
    if (isMaster) {
      await prefs.setBool('notif_allNotif', value);
      await prefs.setBool('notif_transfers', value);
      await prefs.setBool('notif_deposits', value);
      await prefs.setBool('notif_withdrawals', value);
      await prefs.setBool('notif_nfcPayments', value);
      await prefs.setBool('notif_loginAlerts', value);
    } else {
      await prefs.setBool(key, value);
    }

    // إرسال للسيرفر في الخلفية
    _syncWithServer(prefs);
  }

  Future<void> _syncWithServer(SharedPreferences prefs) async {
    try {
      final payload = {
        'notificationPreferences': {
          'transfers': prefs.getBool('notif_transfers') ?? true,
          'deposits': prefs.getBool('notif_deposits') ?? true,
          'withdrawals': prefs.getBool('notif_withdrawals') ?? true,
          'nfcPayments': prefs.getBool('notif_nfcPayments') ?? true,
          'loginAlerts': prefs.getBool('notif_loginAlerts') ?? true,
          'promotions': prefs.getBool('notif_promotions') ?? false,
          'statements': prefs.getBool('notif_statements') ?? false,
        }
      };
      
      // إرسال الطلب (لا ننتظر النتيجة لمنع تجميد الواجهة)
      ApiService.put('/users/me/notifications', payload).then((response) {
        if (response.statusCode != 200) {
          debugPrint('فشل في مزامنة الإشعارات مع السيرفر: ${response.body}');
        }
      }).catchError((error) {
        debugPrint('خطأ شبكة أثناء المزامنة: $error');
      });
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF4F6FA),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
              title: const Text('الإشعارات',
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
                    // مفتاح رئيسي للكل
                    FadeInDown(duration: const Duration(milliseconds: 380),
                      child: _MasterToggle(
                        isDark: isDark, 
                        value: _allNotif,
                        onChanged: (v) {
                          setState(() {
                            _allNotif = v;
                            _transfers = v; _deposits = v; _withdrawals = v;
                            _nfcPayments = v; _loginAlerts = v;
                          });
                          _updatePreference('notif_allNotif', v, isMaster: true);
                        })),
                    const SizedBox(height: 24),

                    // العمليات
                    FadeInUp(delay: const Duration(milliseconds: 80), duration: const Duration(milliseconds: 380),
                      child: _buildLabel('إشعارات العمليات', isDark)),
                    const SizedBox(height: 10),
                    FadeInUp(delay: const Duration(milliseconds: 100), duration: const Duration(milliseconds: 380),
                      child: _Card(isDark: isDark, children: [
                        _NotifTile(icon: Icons.swap_horiz_rounded, label: 'التحويلات الصادرة والواردة', accent: const Color(0xFF0052FF), isDark: isDark, value: _transfers, onChanged: (v) { setState(() => _transfers = v); _updatePreference('notif_transfers', v); }),
                        _div(isDark),
                        _NotifTile(icon: Icons.add_circle_outline_rounded, label: 'الإيداعات', accent: const Color(0xFF10B981), isDark: isDark, value: _deposits, onChanged: (v) { setState(() => _deposits = v); _updatePreference('notif_deposits', v); }),
                        _div(isDark),
                        _NotifTile(icon: Icons.remove_circle_outline_rounded, label: 'السحوبات', accent: const Color(0xFFEC4899), isDark: isDark, value: _withdrawals, onChanged: (v) { setState(() => _withdrawals = v); _updatePreference('notif_withdrawals', v); }),
                        _div(isDark),
                        _NotifTile(icon: Icons.nfc_rounded, label: 'مدفوعات NFC', accent: const Color(0xFF8B5CF6), isDark: isDark, value: _nfcPayments, onChanged: (v) { setState(() => _nfcPayments = v); _updatePreference('notif_nfcPayments', v); }),
                      ])),
                    const SizedBox(height: 24),

                    // الأمان
                    FadeInUp(delay: const Duration(milliseconds: 160), duration: const Duration(milliseconds: 380),
                      child: _buildLabel('إشعارات الأمان', isDark)),
                    const SizedBox(height: 10),
                    FadeInUp(delay: const Duration(milliseconds: 180), duration: const Duration(milliseconds: 380),
                      child: _Card(isDark: isDark, children: [
                        _NotifTile(icon: Icons.login_rounded, label: 'تسجيل الدخول', accent: const Color(0xFFF59E0B), isDark: isDark, value: _loginAlerts, onChanged: (v) { setState(() => _loginAlerts = v); _updatePreference('notif_loginAlerts', v); }),
                      ])),
                    const SizedBox(height: 24),

                    // أخرى
                    FadeInUp(delay: const Duration(milliseconds: 240), duration: const Duration(milliseconds: 380),
                      child: _buildLabel('إشعارات أخرى', isDark)),
                    const SizedBox(height: 10),
                    FadeInUp(delay: const Duration(milliseconds: 260), duration: const Duration(milliseconds: 380),
                      child: _Card(isDark: isDark, children: [
                        _NotifTile(icon: Icons.local_offer_outlined, label: 'العروض والترقيات', accent: const Color(0xFF0088FF), isDark: isDark, value: _promotions, onChanged: (v) { setState(() => _promotions = v); _updatePreference('notif_promotions', v); }),
                        _div(isDark),
                        _NotifTile(icon: Icons.receipt_long_outlined, label: 'كشف الحساب الشهري', accent: const Color(0xFF64748B), isDark: isDark, value: _statements, onChanged: (v) { setState(() => _statements = v); _updatePreference('notif_statements', v); }),
                      ])),
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
class _MasterToggle extends StatelessWidget {
  final bool isDark, value;
  final ValueChanged<bool> onChanged;
  const _MasterToggle({required this.isDark, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF0B2545), Color(0xFF1A3A6B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24)),
      const SizedBox(width: 14),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('جميع الإشعارات', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        Text('تشغيل / إيقاف كل الإشعارات', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12)),
      ])),
      Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: const Color(0xFF38BDF8)),
    ]),
  );
}

Widget _buildLabel(String t, bool isDark) => Padding(padding: const EdgeInsets.only(right: 4),
  child: Text(t, style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600)));

Widget _div(bool isDark) => Divider(height: 1, thickness: 1, indent: 64, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9));

class _Card extends StatelessWidget {
  final bool isDark; final List<Widget> children;
  const _Card({required this.isDark, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0D1826) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFE2E8F0)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Column(children: children)),
  );
}

class _NotifTile extends StatelessWidget {
  final IconData icon; final String label; final Color accent;
  final bool isDark, value; final ValueChanged<bool> onChanged;
  const _NotifTile({required this.icon, required this.label, required this.accent, required this.isDark, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: accent, size: 18)),
      const SizedBox(width: 14),
      Expanded(child: Text(label, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14.5, fontWeight: FontWeight.w600))),
      Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: accent),
    ]),
  );
}
