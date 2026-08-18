import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_colors.dart';
import 'statement/widgets/transaction_item.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import '../models/transaction.dart' as model;

class StatementScreen extends StatefulWidget {
  const StatementScreen({super.key});

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final txs = await TransactionService.getRecentTransactions(limit: 100);
    if (mounted) {
      setState(() {
        _transactions = txs.map((tx) {
          final isCredit = tx.type == model.TransactionType.credit;
          return {
            'name': tx.receiverName,
            'id': tx.transactionId,
            'amount': tx.amount.toStringAsFixed(2),
            'date': DateFormat('dd MMMM yyyy - hh:mm a', 'ar').format(tx.timestamp),
            'type': isCredit ? 'received' : 'sent',
            'comment': tx.note ?? 'تحويل مالي',
          };
        }).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.text(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'كشف الحساب',
          style: TextStyle(
            color: AppColors.text(context),
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
          labelColor: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'آخر 24 ساعة'),
            Tab(text: 'آخر 3 أيام'),
            Tab(text: 'آخر أسبوع'),
            Tab(text: 'آخر شهر'),
            Tab(text: 'آخر 3 أشهر'),
            Tab(text: 'آخر 6 أشهر'),
            Tab(text: 'آخر عام'),
            Tab(text: 'المزيد'),
          ],
        ),
      ),
      extendBodyBehindAppBar: false,
      body: TabBarView(
        controller: _tabController,
        children: List.generate(8, (index) => _buildTradingTab(isDark)),
      ),
    );
  }

  Widget _buildTradingTab(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_transactions.isEmpty) {
      return Center(
        child: Text(
          'لا توجد عمليات ماليّة مسجلة',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        return FadeInLeft(
          delay: Duration(milliseconds: (index % 10) * 100),
          child: TransactionItem(
            tx: _transactions[index],
            isDark: isDark,
          ),
        );
      },
    );
  }
}
