import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_controller.dart';
import '../theme/app_colors.dart';
import '../models/user_account.dart';
import '../services/session_manager.dart';
import '../services/transaction_service.dart';
import 'home/widgets/home_header.dart';
import 'home/widgets/balance_card.dart';
import 'home/widgets/services_grid.dart';
import 'home/widgets/home_bottom_nav.dart';
import 'home/widgets/qr_action_helper.dart';
import 'home/widgets/expense_list.dart';
import 'home/widgets/trusted_beneficiaries.dart';
import 'statement_screen.dart';
import 'profile/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserAccount? _account;
  bool _isBalanceHidden = false;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAccount();
  }

  Future<void> _loadUserAccount() async {
    // 1. استعادة الجلسة من الذاكرة إذا لم تكن موجودة
    if (!SessionManager().isLoggedIn) {
      final user = await SessionManager().restoreSession();
      if (user == null && mounted) {
        // إذا لم يجد جلسة نشطة، اطرده لشاشة الدخول
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
    }
    
    // 2. عرض البيانات المتوفرة فوراً
    if (mounted) {
      setState(() {
        _account = SessionManager().currentUser;
      });
    }

    // 3. جلب الرصيد الحي من السيرفر وتحديث الواجهة
    final success = await TransactionService.fetchAndUpdateBalance();
    if (mounted) {
      setState(() {
        _account = SessionManager().currentUser;
      });
    }
  }

  void _showQrScanner() {
    QrActionHelper.showQrScanner(context);
  }

  void _showMyQrDialog() {
    if (_account != null) {
      QrActionHelper.showMyQrDialog(context, _account!);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _currentTab,
            children: [
              _buildHomeTab(),
              const Center(child: Text('المحفظة')),
              const Center(child: Text('الإحصائيات')),
              ProfileTab(account: _account),
            ],
          ),
        ),
        bottomNavigationBar: HomeBottomNav(
          currentIndex: _currentTab,
          showStatistics: _account?.userType != 'personal',
          onTabSelected: (index) {
            setState(() => _currentTab = index);
          },
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadUserAccount,
      backgroundColor: Colors.black,
      color: AppColors.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 10),
            HomeHeader(
              account: _account,
              onThemeToggle: () {
                themeNotifier.value = themeNotifier.value == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark;
                setState(() {});
              },
              onNotificationsTap: () {},
            ),
            const SizedBox(height: 32),
            BalanceCard(
              account: _account,
              isBalanceHidden: _isBalanceHidden,
              onToggleBalance: () {
                setState(() => _isBalanceHidden = !_isBalanceHidden);
              },
              onShowQrScanner: _showQrScanner,
              onShowMyQr: _showMyQrDialog,
              onShareAccountDetails: () {},
              onShowStatement: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const ServicesGrid(),
            const SizedBox(height: 32),
            const TrustedBeneficiaries(),
            const SizedBox(height: 32),
            const ExpenseList(),
            const SizedBox(height: 120), // Padding for bottom nav
          ],
        ),
      ),
    );
  }
}
