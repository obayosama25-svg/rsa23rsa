import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cyber_background.dart';

class PaymentConfirmScreen extends StatefulWidget {
  final String invoiceId;

  const PaymentConfirmScreen({super.key, required this.invoiceId});

  @override
  State<PaymentConfirmScreen> createState() => _PaymentConfirmScreenState();
}

class _PaymentConfirmScreenState extends State<PaymentConfirmScreen> {
  bool _isLoading = true;
  bool _isPaying = false;
  Invoice? _invoice;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInvoice();
  }

  Future<void> _fetchInvoice() async {
    try {
      final res = await ApiService.get('/invoices/${widget.invoiceId}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['invoice'] != null) {
          setState(() {
            _invoice = Invoice.fromMap(data['invoice']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'فشل العثور على الفاتورة';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'خطأ في الاتصال بالسيرفر';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر الاتصال بالخادم';
        _isLoading = false;
      });
    }
  }

  Future<void> _payInvoice() async {
    setState(() => _isPaying = true);
    try {
      final res = await ApiService.post('/invoices/${widget.invoiceId}/pay', {});
      final data = jsonDecode(res.body);
      
      if (res.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        _showSuccessDialog(data['transactionId']);
      } else {
        if (!mounted) return;
        _showError(data['message'] ?? 'فشل دفع الفاتورة');
        setState(() => _isPaying = false);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('حدث خطأ أثناء دفع الفاتورة');
      setState(() => _isPaying = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(String transactionId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
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
                      color: AppColors.primaryGreen.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 56),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تم الدفع بنجاح! 🎉',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تم تحويل المبلغ إلى ${_invoice?.creatorName}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
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
                            const Text('المبلغ:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text('${_invoice?.amount ?? 0} SDG', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('رقم المعاملة:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(transactionId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Courier')),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                      isDark ? AppColors.primaryBlue.withOpacity(0.15) : AppColors.primaryBlue.withOpacity(0.05),
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
                    child: _isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.errorRed, fontSize: 16)))
                            : _buildInvoiceDetails(isDark),
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'تأكيد الدفع',
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetails(bool isDark) {
    if (_invoice == null) return const SizedBox();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.black12,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.receipt_long_rounded, color: AppColors.primaryBlue, size: 64),
                const SizedBox(height: 16),
                Text(
                  'طلب دفع أموال',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_invoice!.amount} SDG',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                
                _buildRow('المرسل إليه:', _invoice!.creatorName, isDark),
                const Divider(height: 24),
                _buildRow('رقم الحساب:', _invoice!.creatorAccountNumber, isDark),
                if (_invoice!.description.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildRow('الوصف:', _invoice!.description, isDark),
                ],
                const Divider(height: 24),
                _buildRow('رقم الفاتورة:', _invoice!.invoiceId, isDark, isMono: true),
                const Divider(height: 24),
                _buildRow('حالة الفاتورة:', _invoice!.status == 'pending' ? 'قيد الانتظار' : 'غير صالحة', isDark, 
                  color: _invoice!.isValid ? AppColors.primaryBlue : AppColors.errorRed),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          if (_invoice!.isValid)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isPaying ? null : _payInvoice,
                child: _isPaying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('دفع الآن', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildRow(String title, String value, bool isDark, {bool isMono = false, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: color ?? (isDark ? Colors.white : Colors.black), 
              fontSize: 14, 
              fontWeight: FontWeight.bold,
              fontFamily: isMono ? 'Courier' : null,
            ),
          ),
        ),
      ],
    );
  }
}
