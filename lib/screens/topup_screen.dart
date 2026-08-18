import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../widgets/cyber_background.dart';
import '../models/user_account.dart';
import '../services/session_manager.dart';
import '../services/api_service.dart';

class PaymentGateway {
  final String id;
  final String code;
  final String name;
  final String merchantAccount;
  final int validityHours;
  final String instructions;
  final List<Color> gradientColors;
  final String imagePath;

  PaymentGateway({
    required this.id,
    required this.code,
    required this.name,
    required this.merchantAccount,
    required this.validityHours,
    required this.instructions,
    required this.gradientColors,
    required this.imagePath,
  });
}

class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _selectedGatewayCode;
  bool _isVerifying = false;
  bool _isLoadingGateways = true;
  UserAccount? _account;

  List<PaymentGateway> _gateways = [
    PaymentGateway(
      id: 'bankak',
      code: 'BANKAK',
      name: 'بنكك',
      merchantAccount: '3128941',
      validityHours: 6,
      instructions: 'قم بتحويل المبلغ المطلوبة إلى حساب البنك (3128941)، ثم ادخل رقم المعاملة الـ 16 رقماً هنا للمطابقة والتغذية الفورية.',
      gradientColors: [const Color(0xFFE53935), const Color(0xFFB71C1C)],
      imagePath: 'assets/images/bankak_logo.jpg',
    ),
    PaymentGateway(
      id: 'fib',
      code: 'FIB',
      name: 'فوري',
      merchantAccount: '100482931',
      validityHours: 6,
      instructions: 'قم بتحويل المبلغ إلى حساب سوداكارد ببنك فيصل (100482931)، ثم أدخل رقم المرجع البنكي للشحن.',
      gradientColors: [const Color(0xFF6A1B9A), const Color(0xFF4A148C)],
      imagePath: 'assets/images/fawry_logo.png',
    ),
    PaymentGateway(
      id: 'onb',
      code: 'ONB',
      name: 'أوكاش',
      merchantAccount: '550183920',
      validityHours: 6,
      instructions: 'قم بتغذية الحساب عبر تحويل أمدرمان الوطني لحساب (550183920).',
      gradientColors: [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
      imagePath: 'assets/images/ocash_logo.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedGatewayCode = _gateways.first.code;
    _account = SessionManager().currentUser;
    _fetchLiveGateways();
  }

  Future<void> _fetchLiveGateways() async {
    try {
      final res = await ApiService.get('/users/topup/gateways');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['gateways'] != null) {
          final List<dynamic> list = data['gateways'];
          if (list.isNotEmpty) {
            setState(() {
              _gateways = list.map((g) {
                final code = g['code'] ?? 'BANKAK';
                return PaymentGateway(
                  id: g['_id'] ?? code.toLowerCase(),
                  code: code,
                  name: code == 'BANKAK'
                    ? 'بنكك'
                    : (code == 'FIB' ? 'فوري' : 'أوكاش'),
                  merchantAccount: g['merchantAccount'] ?? '3128941',
                  validityHours: g['validityHours'] ?? 6,
                  instructions: g['instructions'] ?? '',
                  gradientColors: code == 'BANKAK' 
                    ? [const Color(0xFFE53935), const Color(0xFFB71C1C)]
                    : (code == 'FIB' ? [const Color(0xFF6A1B9A), const Color(0xFF4A148C)] : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]),
                  imagePath: code == 'BANKAK'
                    ? 'assets/images/bankak_logo.jpg'
                    : (code == 'FIB' ? 'assets/images/fawry_logo.png' : 'assets/images/ocash_logo.jpg'),
                );
              }).toList();
              _selectedGatewayCode = _gateways.first.code;
            });
          }
        }
      }
    } catch (_) {
      // Fallback to initial default gateways
    } finally {
      if (mounted) setState(() => _isLoadingGateways = false);
    }
  }

  @override
  void dispose() {
    _refController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  PaymentGateway get _activeGateway {
    return _gateways.firstWhere(
      (g) => g.code == _selectedGatewayCode,
      orElse: () => _gateways.first,
    );
  }

  Future<void> _verifyAndRecharge() async {
    if (!_formKey.currentState!.validate()) return;
    final amountVal = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amountVal <= 0) {
      _showError('يرجى إدخال مبلغ شحن صحيح');
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final response = await ApiService.post('/users/topup/verify', {
        'bankCode': _selectedGatewayCode,
        'referenceNumber': _refController.text.trim(),
        'amount': amountVal,
      });

      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() => _isVerifying = false);

      if (response.statusCode == 200 && data['success'] == true) {
        final double newBal = (data['newBalance'] as num).toDouble();
        SessionManager().updateBalanceLocally(newBal);
        
        _showSuccessDialog(
          amount: amountVal,
          refNumber: _refController.text.trim(),
          bankName: data['bankName'] ?? _activeGateway.name,
          systemTxId: data['transactionId'] ?? '1000200030004000',
        );
      } else if (data['isReplay'] == true) {
        _showSecurityAlertDialog(data['message']);
      } else if (data['isExpired'] == true) {
        _showExpiredRefundDialog(data['message']);
      } else {
        _showError(data['message'] ?? 'فشل التحقق من العملية البنكية');
      }
    } catch (e) {
      if (mounted) setState(() => _isVerifying = false);
      _showError('حدث خطأ في الاتصال بالخادم أثناء التحقق: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.errorRed),
    );
  }

  void _showSecurityAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Colors.orangeAccent, size: 28),
            SizedBox(width: 10),
            Text('تنبيه أمني - رقم مكرر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showExpiredRefundDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.history_toggle_off_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('انتهت المهلة - استرداد مالي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('فهمت ذلك'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog({
    required double amount,
    required String refNumber,
    required String bankName,
    required String systemTxId,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 56),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تم شحن الحساب بنجاح! 🚀',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تمت المطابقة مع $bankName وتأكيد المبلغ',
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('المبلغ المشحون:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text('${amount.toLocaleString()} SDG', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('مرجع البنك:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(refNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Courier')),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('رقم المعاملة:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(systemTxId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Courier')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text('العودة للرئيسية', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                      isDark ? AppColors.primaryBlue.withValues(alpha: 0.15) : AppColors.primaryBlue.withValues(alpha: 0.05),
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
                              'اختر بوابة الشحن البنكي',
                              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildGatewaysList(isDark),
                            const SizedBox(height: 24),

                            Text(
                              'المبلغ المراد شحنه (SDG)',
                              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildAmountField(isDark),

                            const SizedBox(height: 20),

                            Text(
                              'رقم العملية البنكي المرجعي',
                              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'أدخل رقم العملية (Transaction Reference) الصادر من إيصال البنك.',
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            _buildReferenceField(isDark),

                            const SizedBox(height: 36),
                            _buildSubmitButton(isDark),
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
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'تغذية الحساب الآلية',
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGatewaysList(bool isDark) {
    return Row(
      children: _gateways.map((g) {
        final isSelected = _selectedGatewayCode == g.code;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedGatewayCode = g.code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? null : (isDark ? AppColors.darkSurface : Colors.white),
                gradient: isSelected
                    ? LinearGradient(colors: g.gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : Colors.black12)),
                boxShadow: isSelected
                    ? [BoxShadow(color: g.gradientColors.first.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))]
                    : [],
              ),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))] : [],
                    ),
                    child: ClipOval(
                    child: Image.asset(
                        g.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.account_balance_rounded, color: g.gradientColors.first, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    g.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountField(bool isDark) {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: '50000',
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.primaryGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'الرجاء إدخال المبلغ';
        if ((double.tryParse(val) ?? 0) <= 0) return 'المبلغ غير صحيح';
        return null;
      },
    );
  }

  Widget _buildReferenceField(bool isDark) {
    return TextFormField(
      controller: _refController,
      keyboardType: TextInputType.number,
      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'رقم العملية البنكية',
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 14, letterSpacing: 0),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        prefixIcon: const Icon(Icons.pin_rounded, color: AppColors.primaryGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'الرجاء إدخال رقم العملية';
        return null;
      },
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return GestureDetector(
      onTap: _isVerifying ? null : _verifyAndRecharge,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark ? [AppColors.primaryGreen, const Color(0xFF3DD68C)] : [AppColors.primaryBlue, const Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppColors.primaryGreen.withOpacity(0.35) : AppColors.primaryBlue.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isVerifying
              ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_sync_rounded, color: isDark ? Colors.black : Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text('مطابقة وتحقق من الشحن', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
        ),
      ),
    );
  }
}

extension NumberFormatting on double {
  String toLocaleString() {
    return toStringAsFixed(0);
  }
}
