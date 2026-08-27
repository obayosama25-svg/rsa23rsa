import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../models/user_account.dart';

class BalanceCard extends StatelessWidget {
  final UserAccount? account;
  final bool isBalanceHidden;
  final VoidCallback onToggleBalance;
  final VoidCallback onShowQrScanner;
  final VoidCallback onShowMyQr;
  final VoidCallback onShareAccountDetails;
  final VoidCallback onShowStatement;

  const BalanceCard({
    super.key,
    required this.account,
    required this.isBalanceHidden,
    required this.onToggleBalance,
    required this.onShowQrScanner,
    required this.onShowMyQr,
    required this.onShareAccountDetails,
    required this.onShowStatement,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    String balance = isBalanceHidden
        ? '••••••••'
        : NumberFormat('#,##0.00').format(account?.balance ?? 0.0);
    final String? accountNumber = account?.accountNumber;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0066FF), Color(0xFF0033CC)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    account?.formattedCardNumber ?? '2490  0000  0000',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'Courier',
                      letterSpacing: 2.0,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  GestureDetector(
                    onTap: onShowQrScanner,
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'الرصيد',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '$balance SDG',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34, // قللت الحجم قليلاً ليستوعب الكلمة
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: onToggleBalance,
                    child: Icon(
                      isBalanceHidden
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildAddCardButton(context, isDark),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم الحساب',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        accountNumber ?? 'غير متوفر',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نوع الحساب',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                      const Text(
                        'حساب جاري',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCardButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: onShowStatement,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'مراجعة الحساب',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
          ],
        ),
      ),
    );
  }
}
