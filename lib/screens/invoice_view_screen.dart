import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../models/invoice.dart';
import '../theme/app_colors.dart';
import '../widgets/cyber_background.dart';
import 'transfer/widgets/transfer_receipt_dialog.dart';

/// شاشة معاينة الفاتورة — تُعرض عند مسح QR أو فتح رابط
class InvoiceViewScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceViewScreen({super.key, required this.invoice});

  @override
  State<InvoiceViewScreen> createState() => _InvoiceViewScreenState();
}

class _InvoiceViewScreenState extends State<InvoiceViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _executePayment() {
    if (!widget.invoice.isValid) return;

    TransferReceiptDialog.showConfirmation(
      context: context,
      accountName: widget.invoice.creatorName,
      accountId: null,
      accountNumber: widget.invoice.creatorAccountNumber,
      amount: widget.invoice.amount.toStringAsFixed(2),
      comment: widget.invoice.description,
      onConfirm: () {
        Navigator.pop(context); // أغلق نافذة التأكيد
        _runTransfer();
      },
    );
  }

  void _runTransfer() {
    setState(() => _isProcessing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context); // أغلق مؤشر التحميل
      setState(() => _isProcessing = false);

      TransferReceiptDialog.showSuccess(
        context: context,
        accountName: widget.invoice.creatorName,
        accountId: null,
        accountNumber: widget.invoice.creatorAccountNumber,
        amount: widget.invoice.amount.toStringAsFixed(2),
        comment: widget.invoice.description,
        onClose: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final inv = widget.invoice;
    final bool expired = !inv.isValid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        body: Stack(
          children: [
            // خلفية تقنية
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.5),
                    radius: 1.2,
                    colors: [
                      isDark
                          ? AppColors.primaryBlue.withValues(alpha: 0.12)
                          : AppColors.primaryBlue.withValues(alpha: 0.06),
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
                  _buildHeader(context, isDark),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      child: Column(
                        children: [
                          // حالة الفاتورة
                          FadeInDown(
                            duration: const Duration(milliseconds: 400),
                            child: _buildStatusBadge(isDark, expired),
                          ),
                          const SizedBox(height: 24),

                          // بطاقة تفاصيل الفاتورة
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            child: _buildInvoiceCard(isDark, inv, expired),
                          ),
                          const SizedBox(height: 32),

                          if (!expired) ...[
                            // زر الموافقة والتحويل
                            FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              duration: const Duration(milliseconds: 500),
                              child: _buildPayButton(isDark),
                            ),
                            const SizedBox(height: 16),

                            // زر الرفض
                            FadeInUp(
                              delay: const Duration(milliseconds: 300),
                              duration: const Duration(milliseconds: 500),
                              child: _buildDeclineButton(isDark),
                            ),
                          ] else ...[
                            FadeInUp(child: _buildExpiredWarning(isDark)),
                          ],
                        ],
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'فاتورة مالية',
                style: TextStyle(
                  color: isDark
                      ? AppColors.primaryGreen
                      : AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
              Container(
                height: 2,
                width: 40,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.text(context),
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isDark, bool expired) {
    final color = expired ? AppColors.errorRed : AppColors.primaryGreen;
    final icon = expired ? Icons.timer_off_rounded : Icons.verified_rounded;
    final label = expired ? 'الفاتورة منتهية الصلاحية' : 'فاتورة نشطة وصالحة';

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, _) {
        final glow = expired ? 0.0 : _pulseController.value * 0.3;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: glow),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvoiceCard(bool isDark, Invoice inv, bool expired) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? AppColors.primaryBlue.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.primaryBlue.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // رأس البطاقة
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.primaryBlue.withValues(alpha: 0.15),
                        AppColors.primaryGreen.withValues(alpha: 0.05),
                      ]
                    : [
                        AppColors.primaryBlue.withValues(alpha: 0.08),
                        Colors.white,
                      ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                // أيقونة الفاتورة
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryBlue.withValues(alpha: 0.15)
                        : AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primaryBlue,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'طلب دفع',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // المبلغ
                Text(
                  '${inv.amount.toStringAsFixed(2)} SDG',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),

          // تفاصيل الفاتورة
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildDetailRow(
                  isDark: isDark,
                  icon: Icons.person_rounded,
                  label: 'مُصدِر الفاتورة',
                  value: inv.creatorName,
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  isDark: isDark,
                  icon: Icons.account_balance_rounded,
                  label: 'رقم الحساب',
                  value: inv.creatorAccountNumber,
                  isMonospace: true,
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  isDark: isDark,
                  icon: Icons.tag_rounded,
                  label: 'رقم الفاتورة',
                  value: inv.invoiceId,
                  isMonospace: true,
                ),
                if (inv.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    isDark: isDark,
                    icon: Icons.notes_rounded,
                    label: 'الوصف',
                    value: inv.description,
                  ),
                ],
                const SizedBox(height: 16),
                _buildDetailRow(
                  isDark: isDark,
                  icon: Icons.schedule_rounded,
                  label: 'صالحة حتى',
                  value: _formatDate(inv.expiresAt),
                  valueColor: expired
                      ? AppColors.errorRed
                      : (isDark
                            ? AppColors.primaryGreen
                            : AppColors.primaryBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? (isDark ? Colors.white : Colors.black),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: isMonospace ? 'Courier' : null,
                  letterSpacing: isMonospace ? 1.5 : 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton(bool isDark) {
    return GestureDetector(
      onTap: _isProcessing ? null : _executePayment,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.primaryGreen, const Color(0xFF3DD68C)]
                : [AppColors.primaryBlue, const Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.primaryGreen.withValues(alpha: 0.35)
                  : AppColors.primaryBlue.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: isDark ? Colors.black : Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'موافق وتحويل الأموال',
              style: TextStyle(
                color: isDark ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeclineButton(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.25)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_rounded, color: AppColors.errorRed, size: 20),
            SizedBox(width: 10),
            Text(
              'رفض الفاتورة',
              style: TextStyle(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredWarning(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: const Column(
        children: [
          Icon(Icons.timer_off_rounded, color: AppColors.errorRed, size: 40),
          SizedBox(height: 12),
          Text(
            'انتهت صلاحية هذه الفاتورة',
            style: TextStyle(
              color: AppColors.errorRed,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'يرجى طلب فاتورة جديدة من المُرسِل',
            style: TextStyle(color: AppColors.errorRed, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
