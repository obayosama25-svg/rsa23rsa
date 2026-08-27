import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/app_logo.dart';
import '../theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'pending_approval_screen.dart';
import 'package:sudacards/screens/register/otp_verification_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 1. شاشة البداية (Splash Screen)
    Timer(const Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      final unverifiedEmail = prefs.getString('unverified_email');
      
      if (unverifiedEmail != null) {
        final unverifiedAccountNumber = prefs.getString('unverified_account_number') ?? '';
        final unverifiedFullName = prefs.getString('unverified_full_name') ?? '';
        
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (_, _, _) => OTPVerificationScreen(
              email: unverifiedEmail, 
              accountNumber: unverifiedAccountNumber, 
              fullName: unverifiedFullName
            ),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
          ),
        );
        return;
      }

      final pendingEmail = prefs.getString('pending_approval_email');
      if (pendingEmail != null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (_, _, _) => const PendingApprovalScreen(),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, _, _) => const LoginScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            AppLogo(width: 250),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }
}
