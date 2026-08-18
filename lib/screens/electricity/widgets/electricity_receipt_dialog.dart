import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import 'package:intl/intl.dart' hide TextDirection;

class ElectricityReceiptDialog extends StatelessWidget {
  final String meterNumber;
  final String ownerName;
  final double amountPaid;
  final String token;
  final double kwh;

  const ElectricityReceiptDialog({
    super.key,
    required this.meterNumber,
    required this.ownerName,
    required this.amountPaid,
    required this.token,
    required this.kwh,
  });

  static void show({
    required BuildContext context,
    required String meterNumber,
    required String ownerName,
    required double amountPaid,
    required String token,
    required double kwh,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(
            opacity: anim1,
            child: ElectricityReceiptDialog(
              meterNumber: meterNumber,
              ownerName: ownerName,
              amountPaid: amountPaid,
              token: token,
              kwh: kwh,
            ),
          ),
        );
      },
    );
  }

  String _formatToken(String token) {
    if (token.length == 16) {
      return '${token.substring(0, 4)} - ${token.substring(4, 8)} - ${token.substring(8, 12)} - ${token.substring(12, 16)}';
    }
    return token;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat('#,##0.00');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تم شراء الكهرباء بنجاح',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Token Highlight Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'رمز الشحن (أدخله في العداد)',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatToken(token),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 22,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Courier',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              _buildDetailRow('رقم العداد:', meterNumber, isDark),
              const Divider(height: 24),
              _buildDetailRow('المالك:', ownerName, isDark),
              const Divider(height: 24),
              _buildDetailRow('كمية الكهرباء:', '${formatter.format(kwh)} kWh', isDark),
              const Divider(height: 24),
              _buildDetailRow('المبلغ المدفوع:', '${formatter.format(amountPaid)} SDG', isDark, highlight: true),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    // Navigate back to the very first screen (Home)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    'العودة للرئيسية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight 
                ? (isDark ? AppColors.primaryGreen : AppColors.primaryBlue)
                : (isDark ? Colors.white : Colors.black),
            fontSize: highlight ? 18 : 15,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
