import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cyber_background.dart';
import '../../models/user_account.dart';
import '../../services/database_service.dart';
import 'widgets/university_receipt_dialog.dart';

class UniversityPaymentScreen extends StatefulWidget {
  final String universityName;

  const UniversityPaymentScreen({
    super.key,
    required this.universityName,
  });

  @override
  State<UniversityPaymentScreen> createState() => _UniversityPaymentScreenState();
}

class _UniversityPaymentScreenState extends State<UniversityPaymentScreen> {
  final TextEditingController _invoiceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isVerifying = false;
  bool _isInvoiceVerified = false;
  bool _isPaying = false;
  UserAccount? _account;

  // Mock Invoice Details
  String _studentName = '';
  String _department = '';
  double _amountDue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('user_account');
    if (jsonStr != null && mounted) {
      setState(() {
        _account = UserAccount.fromJson(jsonStr);
      });
    }
  }

  Future<void> _verifyInvoice() async {
    if (_invoiceController.text.length != 16) {
      _showError('الرجاء إدخال رقم الفاتورة المكون من 16 رقماً بشكل صحيح');
      return;
    }

    setState(() => _isVerifying = true);

    // محاكاة استعلام السيرفر
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (_invoiceController.text == '9999999999999999') {
      setState(() {
        _studentName = 'أحمد محمود صالح';
        _department = 'كلية الهندسة - قسم البرمجيات (المستوى الثالث)';
        _amountDue = 15000.0; // 15,000 SDG
        _isInvoiceVerified = true;
        _isVerifying = false;
      });
    } else {
      setState(() => _isVerifying = false);
      _showError('رقم الفاتورة غير مسجل. جرب الرقم التجريبي: 9999999999999999');
    }
  }

  Future<void> _processTuitionPayment() async {
    if (_account == null) {
      _showError('لم يتم تحميل بيانات الحساب');
      return;
    }

    if (_account!.balance < _amountDue) {
      _showError('عفواً، رصيدك الحالي غير كافٍ لإتمام العملية');
      return;
    }

    setState(() => _isPaying = true);

    // محاكاة عملية الدفع
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final newBalance = _account!.balance - _amountDue;
      final updatedAccount = _account!.copyWith(balance: newBalance);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_account', jsonEncode(updatedAccount.toMap()));
      await DatabaseService().updateBalance(updatedAccount.id, newBalance);

      setState(() {
        _account = updatedAccount;
        _isPaying = false;
      });

      if (!mounted) return;
      UniversityReceiptDialog.show(
        context: context,
        universityName: widget.universityName,
        invoiceNumber: _invoiceController.text,
        studentName: _studentName,
        department: _department,
        amountPaid: _amountDue,
      );

    } catch (e) {
      setState(() => _isPaying = false);
      _showError('حدث خطأ أثناء إتمام الدفع: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.errorRed,
      ),
    );
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
            // Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 1.2,
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.15 : 0.05), // Purple glow
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أدخل رقم فاتورة الرسوم الدراسية للاستعلام والدفع.',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildInvoiceField(isDark),
                            const SizedBox(height: 24),
                            
                            if (!_isInvoiceVerified) _buildVerifyButton(isDark),

                            if (_isInvoiceVerified) ...[
                              FadeInDown(
                                duration: const Duration(milliseconds: 500),
                                child: _buildStudentDetailsCard(isDark),
                              ),
                              const SizedBox(height: 32),
                              FadeInUp(
                                duration: const Duration(milliseconds: 500),
                                child: _buildPayButton(isDark),
                              ),
                            ],
                          ],
                        ),
                      ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.universityName,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'University Tuition Payment',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 11,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceField(bool isDark) {
    final fillColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'رقم الفاتورة (16 رقم)',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _invoiceController,
          enabled: !_isInvoiceVerified,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: '9999999999999999',
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 18,
              letterSpacing: 2,
            ),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.receipt_rounded,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _isVerifying ? null : _verifyInvoice,
        child: _isVerifying
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'استعلام عن الفاتورة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildStudentDetailsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryPurple.withValues(alpha: 0.1) : AppColors.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _buildCardRow(Icons.person_rounded, 'اسم الطالب', _studentName, isDark),
          const Divider(height: 24, color: Colors.white10),
          _buildCardRow(Icons.account_balance_rounded, 'الكلية / القسم', _department, isDark),
          const Divider(height: 24, color: Colors.white10),
          _buildCardRow(Icons.payments_rounded, 'المبلغ المطلوب', '${_amountDue.toStringAsFixed(2)} SDG', isDark, highlightValue: true),
        ],
      ),
    );
  }

  Widget _buildCardRow(IconData icon, String label, String value, bool isDark, {bool highlightValue = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryPurple, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: highlightValue
                      ? AppColors.primaryPurple
                      : (isDark ? Colors.white : Colors.black87),
                  fontSize: highlightValue ? 18 : 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton(bool isDark) {
    return GestureDetector(
      onTap: _isPaying ? null : _processTuitionPayment,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryPurple, Color(0xFF6D28D9)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isPaying
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'تأكيد ودفع الرسوم',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
