import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import 'package:intl/intl.dart' hide TextDirection;

class UniversityReceiptDialog extends StatelessWidget {
  final String universityName;
  final String invoiceNumber;
  final String studentName;
  final String department;
  final double amountPaid;

  const UniversityReceiptDialog({
    super.key,
    required this.universityName,
    required this.invoiceNumber,
    required this.studentName,
    required this.department,
    required this.amountPaid,
  });

  static void show({
    required BuildContext context,
    required String universityName,
    required String invoiceNumber,
    required String studentName,
    required String department,
    required double amountPaid,
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
            child: UniversityReceiptDialog(
              universityName: universityName,
              invoiceNumber: invoiceNumber,
              studentName: studentName,
              department: department,
              amountPaid: amountPaid,
            ),
          ),
        );
      },
    );
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
            color: AppColors.primaryPurple.withValues(alpha: 0.3),
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
                  color: AppColors.primaryPurple.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.primaryPurple,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'تم دفع الرسوم بنجاح',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                universityName,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              _buildDetailRow('اسم الطالب:', studentName, isDark),
              const Divider(height: 24),
              _buildDetailRow('الكلية/القسم:', department, isDark),
              const Divider(height: 24),
              _buildDetailRow('رقم الفاتورة:', invoiceNumber, isDark),
              const Divider(height: 24),
              _buildDetailRow('المبلغ المدفوع:', '${formatter.format(amountPaid)} SDG', isDark, highlight: true),
              const SizedBox(height: 32),
              
              SizedBox(
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
                  onPressed: () {
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
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: highlight 
                  ? AppColors.primaryPurple
                  : (isDark ? Colors.white : Colors.black),
              fontSize: highlight ? 18 : 15,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
