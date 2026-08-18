import 'package:flutter/material.dart';
import 'package:sudacards/theme/app_colors.dart';

class AcceptedDocsDialog extends StatelessWidget {
  const AcceptedDocsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AcceptedDocsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      title: const Text(
        'المستندات المقبولة',
        style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'يجب أن تكون الصور واضحة ومقروءة.\n\n'
        '- إثبات الهوية: بطاقة قومية أو جواز سفر ساري المفعول.\n'
        '- صورة التوقيع: توقيع واضح على ورقة بيضاء.\n'
        '- المستندات التجارية: رخصة سارية أو سجل تجاري.',
        style: TextStyle(color: Colors.white70, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('حسناً', style: TextStyle(color: AppColors.primaryBlue)),
        ),
      ],
    );
  }
}
