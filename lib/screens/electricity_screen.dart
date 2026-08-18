import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/cyber_background.dart';
import '../models/user_account.dart';
import '../services/database_service.dart';
import 'electricity/widgets/electricity_receipt_dialog.dart';

class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({super.key});

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  final TextEditingController _meterController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedMeterType = 'عداد سكني 1 خط';
  final List<String> _meterTypes = [
    'عداد سكني 1 خط',
    'عداد سكني 3 خط',
    'عداد تجاري'
  ];

  bool _isVerifying = false;
  bool _isMeterVerified = false;
  bool _isPaying = false;
  UserAccount? _account;

  // Mock Data
  String _ownerName = '';
  String _stateName = '';

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _meterController.dispose();
    _amountController.dispose();
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

  Future<void> _verifyMeter() async {
    if (_meterController.text.length != 16) {
      _showError('الرجاء إدخال رقم العداد المكون من 16 رقماً بشكل صحيح');
      return;
    }

    setState(() => _isVerifying = true);

    // محاكاة الاتصال بالسيرفر
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (_meterController.text == '9999999999999999') {
      setState(() {
        _ownerName = 'محمد أحمد علي';
        _stateName = 'الخرطوم';
        _isMeterVerified = true;
        _isVerifying = false;
      });
    } else {
      setState(() => _isVerifying = false);
      _showError('رقم العداد غير مسجل في النظام. جرب 9999999999999999');
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_account == null) {
      _showError('لم يتم تحميل بيانات الحساب');
      return;
    }

    final double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      _showError('الرجاء إدخال مبلغ صحيح');
      return;
    }

    if (_account!.balance < amount) {
      _showError('عفواً، رصيدك غير كافٍ لإتمام العملية');
      return;
    }

    setState(() => _isPaying = true);

    // محاكاة الدفع وإصدار الفاتورة
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // 1. خصم الرصيد
      final newBalance = _account!.balance - amount;
      final updatedAccount = _account!.copyWith(balance: newBalance);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_account', jsonEncode(updatedAccount.toMap()));
      await DatabaseService().updateBalance(updatedAccount.id, newBalance);

      setState(() {
        _account = updatedAccount;
        _isPaying = false;
      });

      // حساب الكيلوواط تقريبياً (مثلاً 100 جنيه = 1 كيلوواط كافتراض)
      final double kwh = amount / 100.0;
      final String mockToken = '9999999999999999';

      if (!mounted) return;
      ElectricityReceiptDialog.show(
        context: context,
        meterNumber: _meterController.text,
        ownerName: _ownerName,
        amountPaid: amount,
        token: mockToken,
        kwh: kwh,
      );

    } catch (e) {
      setState(() => _isPaying = false);
      _showError('حدث خطأ أثناء الدفع: $e');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 1.2,
                    colors: [
                      const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.05), // Amber glow
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
                            _buildMeterTypeDropdown(isDark),
                            const SizedBox(height: 24),
                            
                            _buildMeterNumberField(isDark),
                            const SizedBox(height: 24),
                            
                            if (!_isMeterVerified) _buildVerifyButton(isDark),
                            
                            if (_isMeterVerified) ...[
                              FadeInDown(
                                duration: const Duration(milliseconds: 500),
                                child: _buildMeterDetailsCard(isDark),
                              ),
                              const SizedBox(height: 32),
                              FadeInUp(
                                duration: const Duration(milliseconds: 500),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'المبلغ المطلوب (SDG)',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildAmountField(isDark),
                                    const SizedBox(height: 32),
                                    _buildPayButton(isDark),
                                  ],
                                ),
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
          Text(
            'شراء الكهرباء',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterTypeDropdown(bool isDark) {
    final fillColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع العداد',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedMeterType,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white54 : Colors.black54),
          dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
          ),
          items: _meterTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
          onChanged: _isMeterVerified ? null : (value) {
            setState(() => _selectedMeterType = value!);
          },
        ),
      ],
    );
  }

  Widget _buildMeterNumberField(bool isDark) {
    final fillColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'رقم العداد (16 رقم)',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _meterController,
          enabled: !_isMeterVerified,
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
                Icons.electrical_services_rounded,
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
          backgroundColor: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _isVerifying ? null : _verifyMeter,
        child: _isVerifying
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'تحقق من العداد',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildMeterDetailsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.1) : const Color(0xFFF59E0B).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اسم المالك',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _ownerName,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white12),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الولاية',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _stateName,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _isMeterVerified = false);
                },
                child: const Text('تغيير العداد', style: TextStyle(color: Color(0xFFF59E0B))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(bool isDark) {
    final fillColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08);

    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        suffixText: 'SDG',
        suffixStyle: const TextStyle(color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.bold),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(
            Icons.payments_rounded,
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
      validator: (value) {
        if (value == null || value.isEmpty) return 'أدخل المبلغ';
        final amount = double.tryParse(value) ?? 0;
        if (amount < 100) return 'أقل مبلغ للشراء هو 100 ج.س';
        return null;
      },
    );
  }

  Widget _buildPayButton(bool isDark) {
    return GestureDetector(
      onTap: _isPaying ? null : _processPayment,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
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
                    Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'تأكيد الشراء',
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
