import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/session_manager.dart';
import 'setup_security_questions_screen.dart';

/// شاشة الأمان والخصوصية
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _isLoading         = true;
  bool _hasQuestions      = false;
  bool _biometricEnabled  = true;
  bool _loginNotif        = true;
  bool _twoFactor         = false;
  bool _hideBalance       = false;

  @override
  void initState() {
    super.initState();
    _checkSecurityStatus();
  }

  Future<void> _checkSecurityStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasQ = prefs.getBool('hasSecurityQuestions') ?? false;

    if (!hasQ && mounted) {
      // توجيه إجباري لإعداد الأسئلة
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SetupSecurityQuestionsScreen()),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _hasQuestions = true;
        _isLoading = false;
      });
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
              title: const Text('الأمان والخصوصية',
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
                    // ── أسئلة الأمان ──
                    FadeInDown(duration: const Duration(milliseconds: 380),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0D1826) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          boxShadow: isDark ? [] : [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 26),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('أسئلة الأمان مفعّلة', style: TextStyle(color: Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.w700)),
                              SizedBox(height: 2),
                              Text('حسابك محمي وتستطيع استرجاعه بسهولة', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          )),
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                        ]),
                      )
                    ),
                    const SizedBox(height: 24),

                    // ── بانر التحذير ──
                    FadeInUp(delay: const Duration(milliseconds: 80), duration: const Duration(milliseconds: 380),
                      child: _SecurityBanner(isDark: isDark)),
                    const SizedBox(height: 24),

                    // ── المصادقة ──
                    FadeInUp(delay: const Duration(milliseconds: 160), duration: const Duration(milliseconds: 380),
                      child: _SectionLabel(label: 'المصادقة والدخول', isDark: isDark)),
                    const SizedBox(height: 10),
                    FadeInUp(delay: const Duration(milliseconds: 180), duration: const Duration(milliseconds: 380),
                      child: _Card(isDark: isDark, children: [
                        _ActionTile(
                          icon: Icons.lock_reset_rounded,
                          label: 'تغيير كلمة المرور',
                          sub: 'تعديل كلمة مرور التطبيق',
                          accent: const Color(0xFF0052FF),
                          isDark: isDark,
                          onTap: () => _showChangePasswordSheet(context, isDark),
                        ),
                        _divider(isDark),
                        _ActionTile(
                          icon: Icons.pin_outlined,
                          label: SessionManager().currentUser?.hasSetPin == true ? 'تغيير رقم PIN' : 'إنشاء رقم PIN',
                          sub: 'رقم PIN الصراف الآلي (4 أرقام)',
                          accent: const Color(0xFF8B5CF6),
                          isDark: isDark,
                          onTap: () => _showChangePinSheet(context, isDark),
                        ),
                      ])),
                    const SizedBox(height: 24),

                    // ── التحقق الثنائي والبصمة ──
                    FadeInUp(delay: const Duration(milliseconds: 240), duration: const Duration(milliseconds: 380),
                      child: _SectionLabel(label: 'الحماية المتقدمة', isDark: isDark)),
                    const SizedBox(height: 10),
                    FadeInUp(delay: const Duration(milliseconds: 260), duration: const Duration(milliseconds: 380),
                      child: _Card(isDark: isDark, children: [
                        _ToggleTile(
                          icon: Icons.fingerprint_rounded,
                          label: 'بصمة الإصبع / Face ID',
                          sub: 'الدخول بالبيومترك',
                          accent: const Color(0xFF10B981),
                          isDark: isDark,
                          value: _biometricEnabled,
                          onChanged: (v) => setState(() => _biometricEnabled = v),
                        ),
                        _divider(isDark),
                        _ToggleTile(
                          icon: Icons.verified_user_outlined,
                          label: 'التحقق الثنائي (2FA)',
                          sub: 'طبقة حماية إضافية عند الدخول',
                          accent: const Color(0xFFF59E0B),
                          isDark: isDark,
                          value: _twoFactor,
                          onChanged: (v) => setState(() => _twoFactor = v),
                        ),
                        _divider(isDark),
                        _ToggleTile(
                          icon: Icons.visibility_off_outlined,
                          label: 'إخفاء الرصيد تلقائياً',
                          sub: 'إخفاء الرصيد عند فتح التطبيق',
                          accent: const Color(0xFF64748B),
                          isDark: isDark,
                          value: _hideBalance,
                          onChanged: (v) => setState(() => _hideBalance = v),
                        ),
                      ])),
                    const SizedBox(height: 24),

                    // ── الإشعارات الأمنية ──
                    FadeInUp(delay: const Duration(milliseconds: 320), duration: const Duration(milliseconds: 380),
                      child: _SectionLabel(label: 'الإشعارات الأمنية', isDark: isDark)),
                    const SizedBox(height: 10),
                    FadeInUp(delay: const Duration(milliseconds: 340), duration: const Duration(milliseconds: 380),
                      child: _Card(isDark: isDark, children: [
                        _ToggleTile(
                          icon: Icons.notifications_active_outlined,
                          label: 'إشعار تسجيل الدخول',
                          sub: 'تنبيه عند كل عملية دخول جديدة',
                          accent: const Color(0xFFEC4899),
                          isDark: isDark,
                          value: _loginNotif,
                          onChanged: (v) => setState(() => _loginNotif = v),
                        ),
                      ])),
                    const SizedBox(height: 24),

                    // ── الجلسات ──
                    FadeInUp(delay: const Duration(milliseconds: 400), duration: const Duration(milliseconds: 380),
                      child: _SectionLabel(label: 'الجهاز والجلسات', isDark: isDark)),
                    const SizedBox(height: 10),
                    FadeInUp(delay: const Duration(milliseconds: 420), duration: const Duration(milliseconds: 380),
                      child: _Card(isDark: isDark, children: [
                        _ActionTile(
                          icon: Icons.devices_outlined,
                          label: 'الجهاز المرتبط',
                          sub: 'هذا الجهاز مرتبط بحسابك',
                          accent: const Color(0xFF0088FF),
                          isDark: isDark,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('نشط', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          onTap: null,
                        ),
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

  void _showChangePasswordSheet(BuildContext ctx, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(isDark: isDark),
    );
  }

  void _showChangePinSheet(BuildContext ctx, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePinSheet(isDark: isDark),
    );
  }
}

// ══════════════════════════════════════════════════════════════
class _SecurityBanner extends StatelessWidget {
  final bool isDark;
  const _SecurityBanner({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF065F46)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shield_rounded, color: Color(0xFF34D399), size: 26),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('حسابك محمي', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('جميع البيانات مشفرة بمعيار AES-256', style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 12)),
          ],
        )),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
class _ChangePasswordSheet extends StatefulWidget {
  final bool isDark;
  const _ChangePasswordSheet({required this.isDark});
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _isLoading = false;

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  Future<void> _requestOTP() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور الجديدة غير متطابقة')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService.post('/users/me/request-password-change-otp', {});
      if (response.statusCode == 200) {
        if (!mounted) return;
        _showOTPDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل طلب رمز التحقق')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في الاتصال بالخادم')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOTPDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OTPDialog(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
        isDark: widget.isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final bg = widget.isDark ? const Color(0xFF0D1826) : Colors.white;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('تغيير كلمة المرور', style: TextStyle(color: widget.isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _sheetField('كلمة المرور الحالية', widget.isDark, _obscure, () => setState(() => _obscure = !_obscure), _currentController),
            const SizedBox(height: 12),
            _sheetField('كلمة المرور الجديدة', widget.isDark, _obscure, () => setState(() => _obscure = !_obscure), _newController),
            const SizedBox(height: 12),
            _sheetField('تأكيد كلمة المرور الجديدة', widget.isDark, _obscure, () => setState(() => _obscure = !_obscure), _confirmController),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _isLoading ? null : _requestOTP,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052FF), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('حفظ التغييرات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            )),
          ]),
        ),
      ),
    );
  }
  
  Widget _sheetField(String label, bool isDark, bool obscure, VoidCallback toggle, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: toggle),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
    );
  }
}

class _OTPDialog extends StatefulWidget {
  final String currentPassword;
  final String newPassword;
  final bool isDark;

  const _OTPDialog({required this.currentPassword, required this.newPassword, required this.isDark});

  @override
  State<_OTPDialog> createState() => _OTPDialogState();
}

class _OTPDialogState extends State<_OTPDialog> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyAndChange() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال 6 أرقام')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'currentPassword': widget.currentPassword,
        'newPassword': widget.newPassword,
        'otpCode': otp
      };

      final response = await ApiService.post('/users/me/change-password', payload);
      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context); // إغلاق الديلوج
        Navigator.pop(context); // إغلاق البوتوم شيت
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مبروك! تم تغيير كلمة المرور بنجاح'), backgroundColor: Color(0xFF10B981)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رمز التحقق غير صحيح أو منتهي الصلاحية')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في الاتصال بالخادم')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF0D1826) : Colors.white;
    final textC = widget.isDark ? Colors.white : const Color(0xFF0F172A);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_unread_rounded, size: 48, color: Color(0xFF0052FF)),
            const SizedBox(height: 16),
            Text('تحقق من بريدك', style: TextStyle(color: textC, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('تم إرسال رمز OTP مكون من 6 أرقام لبريدك الإلكتروني، يرجى إدخاله لتأكيد التغيير',
                textAlign: TextAlign.center,
                style: TextStyle(color: widget.isDark ? Colors.white70 : const Color(0xFF64748B), fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: widget.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text('إلغاء', style: TextStyle(color: widget.isDark ? Colors.white54 : const Color(0xFF64748B))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyAndChange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('تأكيد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _ChangePinSheet extends StatefulWidget {
  final bool isDark;
  const _ChangePinSheet({required this.isDark});
  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  Future<void> _requestOTP() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم PIN الجديد غير متطابق')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService.post('/users/me/request-pin-change-otp', {});
      if (response.statusCode == 200) {
        if (!mounted) return;
        _showOTPDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل طلب رمز التحقق')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في الاتصال بالخادم')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOTPDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PinOTPDialog(
        currentPin: _currentController.text,
        newPin: _newController.text,
        isDark: widget.isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final bg = widget.isDark ? const Color(0xFF0D1826) : Colors.white;
    final hasSetPin = SessionManager().currentUser?.hasSetPin == true;
    final title = hasSetPin ? 'تغيير رقم PIN' : 'إنشاء رقم PIN';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(title, style: TextStyle(color: widget.isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            
            if (hasSetPin) ...[
              _pinField('رقم PIN الحالي (4 أرقام)', widget.isDark, _currentController),
              const SizedBox(height: 12),
            ],
            
            _pinField('رقم PIN الجديد (4 أرقام)', widget.isDark, _newController),
            const SizedBox(height: 12),
            _pinField('تأكيد رقم PIN الجديد', widget.isDark, _confirmController),
            const SizedBox(height: 24),
            
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _isLoading ? null : _requestOTP,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('متابعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            )),
          ]),
        ),
      ),
    );
  }
  
  Widget _pinField(String label, bool isDark, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      maxLength: 4,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) => (v == null || v.length != 4) ? 'يجب إدخال 4 أرقام' : null,
    );
  }
}

class _PinOTPDialog extends StatefulWidget {
  final String currentPin;
  final String newPin;
  final bool isDark;

  const _PinOTPDialog({required this.currentPin, required this.newPin, required this.isDark});

  @override
  State<_PinOTPDialog> createState() => _PinOTPDialogState();
}

class _PinOTPDialogState extends State<_PinOTPDialog> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyAndChange() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال 6 أرقام')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'currentPin': widget.currentPin,
        'newPin': widget.newPin,
        'otpCode': otp
      };

      final response = await ApiService.post('/users/me/change-pin', payload);
      if (response.statusCode == 200) {
        // تحديث محلي للمستخدم
        if (SessionManager().currentUser != null) {
          final updatedUser = SessionManager().currentUser!.copyWith(hasSetPin: true);
          SessionManager().updateSessionUser(updatedUser);
        }

        if (!mounted) return;
        Navigator.pop(context); // إغلاق الديلوج
        Navigator.pop(context); // إغلاق البوتوم شيت
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مبروك! تم حفظ رمز PIN بنجاح'), backgroundColor: Color(0xFF10B981)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رمز التحقق غير صحيح أو منتهي الصلاحية، أو الـ PIN الحالي خطأ')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في الاتصال بالخادم')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF0D1826) : Colors.white;
    final textC = widget.isDark ? Colors.white : const Color(0xFF0F172A);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_unread_rounded, size: 48, color: Color(0xFF8B5CF6)),
            const SizedBox(height: 16),
            Text('تحقق من بريدك', style: TextStyle(color: textC, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('تم إرسال رمز OTP لتأكيد تغيير رقم الـ PIN',
                textAlign: TextAlign.center,
                style: TextStyle(color: widget.isDark ? Colors.white70 : const Color(0xFF64748B), fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: widget.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text('إلغاء', style: TextStyle(color: widget.isDark ? Colors.white54 : const Color(0xFF64748B))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyAndChange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('تأكيد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Reusable Widgets
// ══════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String label; final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Text(label, style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
  );
}

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

Widget _divider(bool isDark) => Divider(height: 1, thickness: 1, indent: 64, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9));

class _ActionTile extends StatelessWidget {
  final IconData icon; final String label; final String? sub;
  final Color accent; final bool isDark; final VoidCallback? onTap;
  final Widget? trailing;
  const _ActionTile({required this.icon, required this.label, this.sub, required this.accent, required this.isDark, this.onTap, this.trailing});
  @override
  Widget build(BuildContext context) => Material(color: Colors.transparent,
    child: InkWell(onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: accent, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14.5, fontWeight: FontWeight.w600)),
            if (sub != null) ...[const SizedBox(height: 2), Text(sub!, style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF94A3B8), fontSize: 12))],
          ])),
          trailing ?? (onTap != null ? Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)) : const SizedBox.shrink()),
        ]),
      ),
    ),
  );
}

class _ToggleTile extends StatelessWidget {
  final IconData icon; final String label; final String sub;
  final Color accent; final bool isDark; final bool value; final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.icon, required this.label, required this.sub, required this.accent, required this.isDark, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: accent, size: 18)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 14.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF94A3B8), fontSize: 12)),
      ])),
      Switch.adaptive(value: value, onChanged: onChanged, activeColor: accent),
    ]),
  );
}
