import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../payment_confirm_screen.dart';
import '../../../models/invoice.dart';
import '../../../models/user_account.dart';
import '../../../theme/app_colors.dart';
import '../../transfer_screen.dart';

class QrActionHelper {
  static void showQrChoiceDialog(BuildContext context, {
    required VoidCallback onShowScanner,
    required VoidCallback onShowMyQr,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(
              color: isDark
                  ? AppColors.primaryGreen.withValues(alpha: 0.3)
                  : Colors.black12,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'بوابة الرموز السريعة',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceItem(
                      context: context,
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'مسح رمز',
                      subtitle: 'تحويل سريع عبر الكاميرا',
                      onTap: () {
                        Navigator.pop(context);
                        onShowScanner();
                      },
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildChoiceItem(
                      context: context,
                      icon: Icons.qr_code_rounded,
                      title: 'رمزي الخاص',
                      subtitle: 'استلام الأموال عبر رمزك',
                      onTap: () {
                        Navigator.pop(context);
                        onShowMyQr();
                      },
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildChoiceItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static void showQrScanner(BuildContext context) {
    final TextEditingController manualInputController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: keyboardPadding),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'الماسح الضوئي الذكي',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'امسح رمز حساب العميل أو رمز الفاتورة',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 16),
                
                // منطقة الكاميرا والمسح الذكي
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Stack(
                        children: [
                          MobileScanner(
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                if (barcode.rawValue != null) {
                                  _processQrCode(context, barcode.rawValue!);
                                  return;
                                }
                              }
                            },
                          ),
                          // إطار الباركود الجمالي
                          Center(
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primaryGreen, width: 2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // حقل الإدخال اليدوي المساعد
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'أو أدخل رقم الحساب / الكود يدوياً:',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: manualInputController,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Courier'),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'رقم الحساب أو الكود',
                                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              final text = manualInputController.text.trim();
                              if (text.isNotEmpty) {
                                _processQrCode(context, text);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('متابعة', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _processQrCode(BuildContext context, String rawCode) {
    final String code = rawCode.trim();

    // ─── 1. فاتورة sudacard://invoice ───────────
    if (code.startsWith('sudacard://invoice')) {
      final invoiceId = Invoice.extractIdFromDeepLink(code);
      if (invoiceId != null && invoiceId.isNotEmpty) {
        Navigator.pop(context); // أغلق الـ scanner
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentConfirmScreen(invoiceId: invoiceId),
          ),
        );
        return;
      }
    }

    // ─── 2. رمز حساب (ACC:...) أو أرقام ──────────────────────
    String targetAcc = code;
    if (code.contains('ACC:')) {
      final parts = code.split('|');
      for (var p in parts) {
        if (p.startsWith('ACC:')) {
          targetAcc = p.substring(4);
        }
      }
    } else if (code.contains('accountNumber')) {
      try {
        final cleanDigits = code.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanDigits.length >= 4) targetAcc = cleanDigits;
      } catch (_) {}
    } else {
      targetAcc = code.replaceAll(RegExp(r'[^0-9]'), '');
    }

    if (targetAcc.isNotEmpty) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransferScreen(
            initialAccountNumber: targetAcc,
          ),
        ),
      );
    }
  }

  static void showMyQrDialog(BuildContext context, UserAccount account) {
    // Encode account data into a JSON string or formatted text
    final String qrData = "USER:${account.fullName}|ACC:${account.accountNumber}";

    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0A0A).withValues(alpha: 0.8) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark ? AppColors.primaryGreen.withValues(alpha: 0.3) : Colors.black12,
                ),
                boxShadow: [
                  if (isDark)
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      blurRadius: 40,
                      spreadRadius: -10,
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MY QR CODE //',
                        style: TextStyle(
                          color: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
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
                  const SizedBox(height: 24),
                  Text(
                    account.firstName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    account.cardNumber,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Courier',
                      letterSpacing: 2,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ تفاصيل الحساب للمشاركة')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: const Text('مشاركة بياناتي', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
