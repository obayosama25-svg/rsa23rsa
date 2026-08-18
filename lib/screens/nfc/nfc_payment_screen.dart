import 'package:flutter/material.dart';
import '../../services/nfc_service.dart';
import '../transfer/widgets/nfc_payment_dialog.dart';

class NfcPaymentScreen extends StatefulWidget {
  const NfcPaymentScreen({Key? key}) : super(key: key);

  @override
  State<NfcPaymentScreen> createState() => _NfcPaymentScreenState();
}

class _NfcPaymentScreenState extends State<NfcPaymentScreen> {
  bool _isScanning = false;
  String _statusMessage = 'قم بتقريب هاتفك من جهاز التاجر';

  @override
  void initState() {
    super.initState();
    _startNfcScan();
  }

  @override
  void dispose() {
    NfcService.stopNfcSession();
    super.dispose();
  }

  Future<void> _startNfcScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'جاري البحث عن أجهزة الدفع...';
    });

    await NfcService.startNfcSession(
      onInvoiceReceived: (invoiceData) {
        if (!mounted) return;
        setState(() {
          _isScanning = false;
          _statusMessage = 'تم التقاط الفاتورة بنجاح!';
        });
        
        // عرض نافذة تأكيد الدفع
        _showPaymentConfirmationDialog(invoiceData);
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isScanning = false;
          _statusMessage = error;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      },
    );
  }

  void _showPaymentConfirmationDialog(Map<String, dynamic> invoiceData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NfcPaymentDialog(invoiceData: invoiceData),
    ).then((value) {
      if (value == true) {
        // تم الدفع بنجاح
        if (mounted) {
          Navigator.pop(context, true); // العودة للشاشة السابقة مع إشارة النجاح
        }
      } else {
        // العميل ألغى الدفع، إعادة تشغيل البحث أو الخروج
        if (mounted) {
          Navigator.pop(context, false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدفع عبر NFC'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // يمكن استخدام Lottie إذا كان لديك ملف مناسب في assets
              // Lottie.asset('assets/animations/nfc_scan.json', width: 200),
              
              Icon(
                Icons.nfc_rounded,
                size: 150,
                color: _isScanning ? Theme.of(context).primaryColor : Colors.grey,
              ),
              const SizedBox(height: 32),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              if (!_isScanning)
                ElevatedButton.icon(
                  onPressed: _startNfcScan,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
