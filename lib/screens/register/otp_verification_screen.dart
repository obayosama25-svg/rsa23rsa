import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/cyber_background.dart';
import '../../../services/session_manager.dart';
import 'widgets/register_success_dialog.dart';
import '../../../models/user_account.dart';
import 'package:shared_preferences/shared_preferences.dart';
class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final UserAccount account;
  
  const OTPVerificationScreen({super.key, required this.email, required this.account});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رمز صحيح مكون من 6 أرقام'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);
    
    try {
      final session = SessionManager();
      final result = await session.verifyOtp(widget.email, code);
      
      if (result.isSuccess) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('unverified_email');
        await prefs.remove('unverified_account');
        
        if (!mounted) return;
        RegisterSuccessDialog.show(
          context: context,
          fullName: widget.account.fullName,
          cardNumber: widget.account.accountNumber,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'رمز التحقق غير صحيح'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(decoration: const BoxDecoration(color: AppColors.darkBackground)),
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
                child: FadeInUp(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.4), width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mark_email_read_rounded, size: 80, color: AppColors.primaryGreen),
                            const SizedBox(height: 24),
                            const Text(
                              'تحقق من البريد الإلكتروني',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لقد أرسلنا رمز تحقق مكون من 6 أرقام إلى بريدك:\n${widget.email}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                            ),
                            const SizedBox(height: 32),
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '------',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen.withOpacity(0.5))),
                                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGreen)),
                              ),
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _isVerifying ? null : _verifyOtp,
                                child: _isVerifying
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                    : const Text('تأكيد الرمز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
