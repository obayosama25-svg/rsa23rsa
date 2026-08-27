import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../models/invoice.dart';
import '../models/user_account.dart';
import '../theme/app_colors.dart';
import '../widgets/cyber_background.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'payment_confirm_screen.dart';

/// شاشة إنشاء فاتورة وطلب الأموال
class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _payLinkController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  final _formKey = GlobalKey<FormState>();

  UserAccount? _account;
  Invoice? _generatedInvoice;
  bool _isGenerating = false;
  bool _showQr = false;
  int _selectedTab = 0; // 0: إنشاء مطالبة, 1: سداد مطالبة

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _payLinkController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        _payLinkController.text = data.text!.trim();
      });
    }
  }

  void _processPayLink() {
    final raw = _payLinkController.text.trim();
    if (raw.isEmpty) {
      _showError('يرجى إدخال أو لصق رابط المطالبة');
      return;
    }
    final invoiceId = Invoice.extractIdFromDeepLink(raw);
    if (invoiceId == null || invoiceId.isEmpty) {
      _showError('الرابط غير صالح، يجب أن يحتوي على كود مطالبة INV-');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmScreen(invoiceId: invoiceId),
      ),
    );
  }

  Future<void> _loadAccount() async {
    _account = SessionManager().currentUser;
    if (_account == null) {
      _account = await SessionManager().restoreSession();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _generateInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_account == null) {
      _account = SessionManager().currentUser ?? await SessionManager().restoreSession();
    }
    if (_account == null) {
      _showError('يرجى تسجيل الدخول أولاً لإنشاء طلب الأموال');
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showError('الرجاء إدخال مبلغ صحيح');
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final res = await ApiService.post('/invoices', {
        'amount': amount,
        'description': _descController.text.trim(),
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['invoice'] != null) {
          if (!mounted) return;
          setState(() {
            _generatedInvoice = Invoice.fromMap(data['invoice']);
            _isGenerating = false;
            _showQr = true;
          });
        } else {
          _showError(data['message'] ?? 'فشل إنشاء الفاتورة');
          setState(() => _isGenerating = false);
        }
      } else {
        _showError('خطأ في الاتصال بالخادم: ${res.statusCode}');
        setState(() => _isGenerating = false);
      }
    } catch (e) {
      _showError('تعذر الاتصال بالخادم: $e');
      setState(() => _isGenerating = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _shareLink() async {
    if (_generatedInvoice == null) return;
    final link = _generatedInvoice!.toDeepLink();
    await SharePlus.instance.share(
      ShareParams(
        text: '🏦 طلب دفع من ${_generatedInvoice!.creatorName}\n'
            '💰 المبلغ: ${_generatedInvoice!.amount.toStringAsFixed(2)} SDG\n'
            '📝 ${_generatedInvoice!.description.isEmpty ? 'بدون وصف' : _generatedInvoice!.description}\n\n'
            '🔗 رابط الفاتورة:\n$link',
        subject: 'طلب دفع - سوداكارد',
      ),
    );
  }

  Future<void> _shareQrImage() async {
    if (_generatedInvoice == null) return;
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final xFile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: 'invoice_qr_${_generatedInvoice!.invoiceId}.png',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: '📱 امسح الرمز لدفع الفاتورة - سوداكارد\n'
              '💰 المبلغ: ${_generatedInvoice!.amount.toStringAsFixed(2)} SDG',
          subject: 'فاتورة QR - سوداكارد',
        ),
      );
    } catch (e) {
      _showError('تعذّر مشاركة صورة QR');
    }
  }

  void _reset() {
    setState(() {
      _showQr = false;
      _generatedInvoice = null;
      _amountController.clear();
      _descController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        body: Stack(
          children: [
            // خلفية تقنية
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.3, -0.7),
                    radius: 1.3,
                    colors: [
                      isDark
                          ? AppColors.primaryGreen.withValues(alpha: 0.10)
                          : AppColors.primaryGreen.withValues(alpha: 0.05),
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
                  _buildHeader(isDark),
                  if (!_showQr) _buildTabSelector(isDark),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _showQr
                          ? _buildQrView(isDark)
                          : (_selectedTab == 0
                              ? _buildFormView(isDark)
                              : _buildPayClaimView(isDark)),
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

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _showQr ? 'مشاركة الفاتورة' : 'المطالبات المالية',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (_showQr)
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.primaryGreen.withValues(alpha: 0.1) : AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.8) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? (isDark ? AppColors.primaryGreen : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedTab == 0
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'إنشاء مطالبة',
                  style: TextStyle(
                    color: _selectedTab == 0
                        ? (isDark ? Colors.black : AppColors.primaryBlue)
                        : (isDark ? Colors.white60 : Colors.black54),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? (isDark ? AppColors.primaryGreen : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedTab == 1
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'سداد مطالبة بالرابط',
                  style: TextStyle(
                    color: _selectedTab == 1
                        ? (isDark ? Colors.black : AppColors.primaryBlue)
                        : (isDark ? Colors.white60 : Colors.black54),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── نموذج سداد مطالبة عبر الرابط ────────────────────────────────
  Widget _buildPayClaimView(bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('pay_claim'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // إرشادات السداد
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFF3B82F6).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.link_rounded, color: Color(0xFF3B82F6), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'قم بلصق رابط المطالبة أو كود الفاتورة المسلّم إليك لدفعها فوراً. (صلاحية الروابط 5 ساعات فقط من تاريخ إنشائها)',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF1E3A8A),
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: Text(
              'رابط أو كود المطالبة',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _payLinkController,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'https://sudacards.app/pay/INV-... أو INV-12345',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black26, fontSize: 13),
                hintTextDirection: TextDirection.ltr,
                prefixIcon: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryGreen),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded, color: AppColors.primaryGreen),
                  tooltip: 'لصق من الحافظة',
                  onPressed: _pasteFromClipboard,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // زر لصق سريع
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.content_paste_go_rounded, size: 18),
              label: const Text('لصق من الحافظة'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // زر السداد
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF00C853), Color(0xFF009624)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C853).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _processPayLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment_rounded, color: Colors.black, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'متابعة وسداد المطالبة',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── نموذج الإنشاء ───────────────────────────────────────────────
  Widget _buildFormView(bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // إرشادات
            _buildInfoBanner(isDark),
            const SizedBox(height: 28),

            // حقل المبلغ
            _buildAmountField(isDark),
            const SizedBox(height: 20),

            // حقل الوصف
            _buildDescriptionField(isDark),
            const SizedBox(height: 32),

            // زر الإنشاء
            _buildGenerateButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryGreen.withValues(alpha: 0.1) : AppColors.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.primaryGreen.withValues(alpha: 0.3) : AppColors.primaryBlue.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.access_time_filled_rounded,
            color: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'أدخل المبلغ المطلوب ووصف الغرض لإنشاء رابط دفع أو رمز QR. تنتهي صلاحية الرابط تلقائياً بعد 5 ساعات.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 13,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Text(
            'المبلغ المطلوب',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SDG',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'الرجاء إدخال المبلغ';
              final val = double.tryParse(v.replaceAll(',', ''));
              if (val == null || val <= 0) return 'مبلغ غير صحيح';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Text(
            'وصف الفاتورة (اختياري)',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _descController,
            maxLines: 3,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'مثال: إيجار شهر يناير، حساب العشاء...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.black38,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(bool isDark) {
    return GestureDetector(
      onTap: _isGenerating ? null : _generateInvoice,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.primaryGreen, const Color(0xFF2E7D32)]
                : [AppColors.primaryBlue, const Color(0xFF1565C0)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.primaryGreen.withValues(alpha: 0.3)
                  : AppColors.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isGenerating
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: isDark ? Colors.black : Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'إصدار الفاتورة',
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── عرض QR ──────────────────────────────────────────────────────
  Widget _buildQrView(bool isDark) {
    final inv = _generatedInvoice!;
    final qrData = inv.toDeepLink();

    return SingleChildScrollView(
      key: const ValueKey('qr'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        children: [
          // ملخص الفاتورة
          FadeInDown(
            duration: const Duration(milliseconds: 400),
            child: _buildInvoiceSummaryCard(isDark, inv),
          ),
          const SizedBox(height: 24),

          // QR Code
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: _buildQrCard(isDark, qrData),
          ),
          const SizedBox(height: 24),

          // أزرار المشاركة
          FadeInUp(
            delay: const Duration(milliseconds: 150),
            duration: const Duration(milliseconds: 400),
            child: _buildShareButtons(isDark),
          ),

          const SizedBox(height: 16),

          // تنبيه الصلاحية
          FadeInUp(
            delay: const Duration(milliseconds: 250),
            child: _buildExpiryNote(isDark, inv),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSummaryCard(bool isDark, Invoice inv) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.primaryGreen.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.primaryGreen.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryGreen.withValues(alpha: 0.15)
                  : AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${inv.amount.toStringAsFixed(2)} SDG',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (inv.description.isNotEmpty)
                  Text(
                    inv.description,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'نشطة',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(bool isDark, String qrData) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? AppColors.primaryGreen.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.primaryGreen.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.07),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'امسح الرمز للدفع',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220,
                gapless: false,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SudaCard — Invoice QR',
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 11,
              fontFamily: 'Courier',
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildShareButton(
            isDark: isDark,
            icon: Icons.qr_code_rounded,
            label: 'مشاركة QR',
            color: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
            onTap: _shareQrImage,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildShareButton(
            isDark: isDark,
            icon: Icons.link_rounded,
            label: 'مشاركة رابط',
            color: isDark
                ? const Color(0xFF818CF8)
                : const Color(0xFF6366F1),
            onTap: _shareLink,
          ),
        ),
      ],
    );
  }

  Widget _buildShareButton({
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryNote(bool isDark, Invoice inv) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 14,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        const SizedBox(width: 6),
        Text(
          'صالحة حتى: ${_formatDate(inv.expiresAt)}',
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}
