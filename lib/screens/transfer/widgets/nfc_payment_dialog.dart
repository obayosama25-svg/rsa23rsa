import 'package:flutter/material.dart';

class NfcPaymentDialog extends StatefulWidget {
  final Map<String, dynamic> invoiceData;

  const NfcPaymentDialog({Key? key, required this.invoiceData}) : super(key: key);

  @override
  State<NfcPaymentDialog> createState() => _NfcPaymentDialogState();
}

class _NfcPaymentDialogState extends State<NfcPaymentDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  void _confirmPayment() async {
    if (_pinController.text.isEmpty || _pinController.text.length < 4) {
      setState(() {
        _errorMessage = 'الرجاء إدخال الرمز السري بشكل صحيح (4 أرقام على الأقل)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // محاكاة عملية الدفع (يجب استبدالها بخدمة الدفع الحقيقية PaymentService)
    await Future.delayed(const Duration(seconds: 2));

    // افتراض أن الدفع تم بنجاح
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      // نرسل true للدلالة على نجاح الدفع
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // استخراج بيانات الفاتورة
    final invoiceId = widget.invoiceData['invoiceId'] ?? 'غير محدد';
    final amount = widget.invoiceData['amount']?.toString() ?? '0.0';
    final merchantName = widget.invoiceData['merchantName'] ?? 'تاجر غير معروف';

    return AlertDialog(
      title: const Text('تأكيد الدفع', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.receipt_long, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text('التاجر: $merchantName', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('رقم الفاتورة: $invoiceId'),
            const SizedBox(height: 8),
            Text(
              'المبلغ: $amount جنيه',
              style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),
            const Text('أدخل الرمز السري (PIN) لتأكيد الدفع:'),
            const SizedBox(height: 8),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'الرمز السري',
                errorText: _errorMessage,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _confirmPayment,
          child: const Text('تأكيد الدفع'),
        ),
      ],
    );
  }
}
