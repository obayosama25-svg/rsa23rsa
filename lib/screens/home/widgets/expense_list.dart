import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../statement/widgets/transaction_details_dialog.dart';
import '../../../services/transaction_service.dart';
import '../../../models/transaction.dart' as model;

class ExpenseList extends StatefulWidget {
  const ExpenseList({super.key});

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  List<model.Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final txs = await TransactionService.getRecentTransactions(limit: 7);
    if (mounted) {
      setState(() {
        _transactions = txs;
        _isLoading = false;
      });
    }
  }

  /// تنسيق المبلغ بالفواصل
  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }

  /// خصائص بصرية لكل نوع عملية
  _TxStyle _getTxStyle(model.TransactionType type, String note, bool isDark) {
    if (note.contains('تغذية') || note.contains('deposit')) {
      return _TxStyle(
        icon: Icons.south_west_rounded,
        iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
        iconColor: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
        label: 'تغذية حساب',
        subtitle: 'إيداع',
      );
    }
    if (note.contains('خصم') || note.contains('withdrawal') || note.contains('سحب')) {
      return _TxStyle(
        icon: Icons.north_east_rounded,
        iconBg: isDark ? const Color(0xFF4C1D2A) : const Color(0xFFFEE2E2),
        iconColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
        label: 'سحب نقدي',
        subtitle: 'سحب',
      );
    }
    if (note.contains('كهرباء')) {
      return _TxStyle(
        icon: Icons.bolt_rounded,
        iconBg: isDark ? const Color(0xFF422006) : const Color(0xFFFEF3C7),
        iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
        label: 'شحن كهرباء',
        subtitle: 'خدمات',
      );
    }
    if (note.contains('اتصالات') || note.contains('زين') || note.contains('سوداني')) {
      return _TxStyle(
        icon: Icons.cell_tower_rounded,
        iconBg: isDark ? const Color(0xFF2E1065) : const Color(0xFFEDE9FE),
        iconColor: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
        label: 'شحن رصيد',
        subtitle: 'اتصالات',
      );
    }
    if (type == model.TransactionType.credit) {
      return _TxStyle(
        icon: Icons.south_west_rounded,
        iconBg: isDark ? const Color(0xFF0C2D48) : const Color(0xFFDBEAFE),
        iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        label: '',
        subtitle: 'حوالة واردة',
      );
    }
    return _TxStyle(
      icon: Icons.north_east_rounded,
      iconBg: isDark ? const Color(0xFF1C1917) : const Color(0xFFF1F5F9),
      iconColor: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF475569),
      label: '',
      subtitle: 'حوالة صادرة',
    );
  }

  String _getTxTitle(model.Transaction tx, _TxStyle style) {
    if (style.label.isNotEmpty) return style.label;
    return tx.receiverName;
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)]
                          : [const Color(0xFF2563EB), const Color(0xFF7C3AED)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'آخر الحركات المالية',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            _buildLoadingShimmer(isDark)
          else if (_transactions.isEmpty)
            _buildEmptyState(isDark)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final isCredit = tx.type == model.TransactionType.credit;
                final style = _getTxStyle(tx.type, tx.note ?? '', isDark);

                return FadeInUp(
                  delay: Duration(milliseconds: 60 * index),
                  duration: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _TransactionTile(
                      isDark: isDark,
                      isCredit: isCredit,
                      title: _getTxTitle(tx, style),
                      subtitle: style.subtitle,
                      amount: _formatAmount(tx.amount),
                      date: DateFormat('dd MMM · hh:mm a', 'ar').format(tx.timestamp),
                      style: style,
                      showDivider: index < _transactions.length - 1,
                      onTap: () {
                        final txData = {
                          'type': isCredit ? 'received' : 'sent',
                          'date': DateFormat('dd MMMM yyyy - hh:mm a', 'ar').format(tx.timestamp),
                          'id': tx.transactionId,
                          'name': tx.receiverName,
                          'amount': tx.amount.toStringAsFixed(2),
                          'comment': tx.note ?? 'تحويل مالي',
                        };
                        TransactionDetailsDialog.show(context: context, tx: txData);
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return Column(
      children: List.generate(4, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 14, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 8),
                  Container(width: 80, height: 10, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[100], borderRadius: BorderRadius.circular(6))),
                ],
              ),
            ),
            Container(width: 80, height: 16, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], borderRadius: BorderRadius.circular(6))),
          ],
        ),
      )),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: isDark ? Colors.white24 : Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد حركات مالية بعد',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey[500],
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// عنصر حركة مالية واحدة
class _TransactionTile extends StatelessWidget {
  final bool isDark;
  final bool isCredit;
  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final _TxStyle style;
  final bool showDivider;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.isDark,
    required this.isCredit,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.style,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: style.iconColor.withValues(alpha: 0.08),
        highlightColor: style.iconColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Row(
                children: [
                  // أيقونة العملية
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: style.iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        style.icon,
                        color: style.iconColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // العنوان والوصف
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          date,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // المبلغ
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isCredit ? '+' : '-'} $amount',
                        style: TextStyle(
                          color: isCredit
                              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                              : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SDG',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (showDivider)
                Padding(
                  padding: const EdgeInsets.only(right: 62, top: 12),
                  child: Divider(
                    height: 1,
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// خصائص بصرية لنوع المعاملة
class _TxStyle {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String subtitle;

  _TxStyle({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subtitle,
  });
}
