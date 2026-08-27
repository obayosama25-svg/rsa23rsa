import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/cyber_background.dart';
import 'register/register_type_screen.dart';
import 'home_screen.dart';
import 'login/widgets/login_form.dart';
import 'recovery_flow_screen.dart';
import 'device_transfer_flow_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pending_approval_screen.dart';
import '../services/session_manager.dart';
import '../services/biometric_service.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isAuthenticating = false;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);

    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final bioService = BiometricService();
    final isAvailable = await bioService.isBiometricAvailable();
    final isEnabled = await bioService.isBiometricEnabled();
    final creds = await bioService.getSavedBiometricCredentials();

    if (!isAvailable || !isEnabled || creds == null) {
      if (mounted) {
        setState(() {
          _isBiometricAvailable = false;
        });
      }
      return;
    }

    // التحقق السريع من السيرفر للتأكد أن الحساب لم يتم حذفه أو تصفير السيرفر
    final accountOrEmail = creds['accountNumber']?.isNotEmpty == true ? creds['accountNumber']! : creds['email']!;
    if (accountOrEmail.isNotEmpty) {
      try {
        final res = await ApiService.get('/users/status/$accountOrEmail');
        if (res.statusCode == 404) {
          // الحساب غير موجود على السيرفر (تم حذفه أو تم تصفير قاعدة البيانات) -> تطهير فوري للهاتف
          debugPrint('[LoginScreen] الحساب غير موجود على السيرفر، تنفيذ تطهير الهاتف... 🧹');
          await bioService.purgeAllDeviceData();
          if (mounted) {
            setState(() {
              _isBiometricAvailable = false;
              _accountNumberController.clear();
            });
          }
          return;
        }
      } catch (e) {
        debugPrint('[LoginScreen] تعذر التحقق من حالة الحساب: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isBiometricAvailable = true;
      });

      if (creds['accountNumber'] != null && _accountNumberController.text.isEmpty) {
        _accountNumberController.text = creds['accountNumber']!;
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _isAuthenticating = true);
    
    final result = await SessionManager().loginWithBiometric();

    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    if (result.isSuccess) {
      Navigator.pushReplacement(context, FadeInRoute(page: const HomeScreen()));
    } else {
      await _checkBiometricStatus(); // تحديث فوري وإخفاء الزر إذا تم تطهير البيانات
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'فشل التحقق من البصمة'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _accountNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_accountNumberController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رقم الحساب وكلمة المرور'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isAuthenticating = true);
    
    final result = await SessionManager().login(
      email: _accountNumberController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    if (result.isSuccess) {
      Navigator.pushReplacement(context, FadeInRoute(page: const HomeScreen()));
    } else {
      if (result.status == 'account_locked') {
        // Navigate to Recovery Flow
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecoveryFlowScreen(accountNumber: _accountNumberController.text.trim()),
          ),
        );
      } else if (result.status == 'device_mismatch') {
        // Navigate to Device Transfer Flow
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceTransferFlowScreen(accountNumber: _accountNumberController.text.trim()),
          ),
        );
      } else if (result.status == 'pending' || result.status == 'pending_approval' || result.status == 'unverified') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_approval_email', _accountNumberController.text.trim());
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PendingApprovalScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'فشل تسجيل الدخول'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Background components
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(color: AppColors.darkBackground),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.2),
                  radius: 1.2,
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.1),
                    AppColors.darkBackground,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05,
              child: const TechGridBackground(),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(seconds: 1),
                      child: const AppLogo(width: 260),
                    ),
                    const SizedBox(height: 40),
                    const SizedBox(height: 12),
                    FadeIn(
                      delay: const Duration(milliseconds: 700),
                      child: const Text(
                        'يرجى إدخال رقم الحساب للبدء',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // ID Input Card
                    FadeInUp(
                      delay: const Duration(milliseconds: 900),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: AnimatedBuilder(
                            animation: _glowAnimation,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.darkSurface.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.primaryGreen.withValues(
                                      alpha: _glowAnimation.value * 0.4,
                                    ),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryGreen.withValues(
                                        alpha: _glowAnimation.value * 0.2,
                                      ),
                                      blurRadius: 15 * _glowAnimation.value,
                                      spreadRadius: 1 * _glowAnimation.value,
                                    ),
                                  ],
                                ),
                                child: child,
                              );
                            },
                            child: LoginForm(
                              accountNumberController: _accountNumberController,
                              passwordController: _passwordController,
                              isAuthenticating: _isAuthenticating,
                              onLogin: _handleLogin,
                              isBiometricAvailable: _isBiometricAvailable,
                              onBiometricLogin: _handleBiometricLogin,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeInUp(
                      delay: const Duration(milliseconds: 1100),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ليس لديك حساب؟ ',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          TextButton(
                            // 2. شاشة تسجيل الدخول (Login Screen)
                            // التوجيه إلى شاشة اختيار نوع الحساب للتسجيل:
                            // Login Screen -> Register Type Screen
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterTypeScreen(),
                              ),
                            ),
                            child: const Text(
                              'سجل الآن',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FadeInRoute extends PageRouteBuilder {
  final Widget page;
  FadeInRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      );
}
