import 'package:flutter/material.dart';
import 'package:sudacards/theme/app_colors.dart';

class TermsDialog extends StatelessWidget {
  const TermsDialog({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, a1, a2) {
        return ScaleTransition(
          scale: a1,
          child: const TermsDialog(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
      title: const Text(
        'المواثيق والشروط',
        style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
      ),
      content: const SingleChildScrollView(
        child: Text(
          '1. أنت توافق على شروط الخدمة الخاصة بـ SudaCards.\n\n'
          '2. سيتم مراجعة البيانات المدخلة والمستندات قبل تفعيل الحساب للكيانات التجارية/الطبية.\n\n'
          '3. حافظ على الحماية القصوى لبيانات الدخول.\n',
          style: TextStyle(height: 1.5, fontSize: 14, color: Colors.white70),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('تأكيد وفهم', style: TextStyle(color: AppColors.primaryGreen)),
        ),
      ],
    );
  }
}
