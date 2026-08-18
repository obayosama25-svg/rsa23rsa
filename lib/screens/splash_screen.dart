import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/app_logo.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudacards/models/user_account.dart' as import_user_account;
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
    // تقوم بعرض شعار التطبيق لمدة 3 ثواني ثم تقوم بتوجيه المستخدم إلى:
    // Splash Screen -> Login Screen
    Timer(const Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      final unverifiedEmail = prefs.getString('unverified_email');
      
      if (unverifiedEmail != null) {
        final accountJson = prefs.getString('unverified_account');
        if (accountJson != null) {
          import_user_account.UserAccount account;
          try {
            account = import_user_account.UserAccount.fromJson(accountJson);
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 800),
                pageBuilder: (_, _, _) => OTPVerificationScreen(email: unverifiedEmail, account: account),
                transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
              ),
            );
            return;
          } catch (e) {
            // Ignored, fallback to login
          }
        }
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
