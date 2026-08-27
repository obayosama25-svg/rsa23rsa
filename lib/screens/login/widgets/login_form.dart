import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController accountNumberController;
  final TextEditingController passwordController;
  final bool isAuthenticating;
  final VoidCallback onLogin;
  final bool isBiometricAvailable;
  final VoidCallback? onBiometricLogin;

  const LoginForm({
    super.key,
    required this.accountNumberController,
    required this.passwordController,
    required this.isAuthenticating,
    required this.onLogin,
    this.isBiometricAvailable = false,
    this.onBiometricLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Account Number Field
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: accountNumberController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0000 0000',
              hintStyle: TextStyle(
                color: Colors.white60,
              ),
              labelText: 'رقم الحساب',
              labelStyle: TextStyle(
                color: Colors.white,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Password Field
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: passwordController,
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 8,
            ),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '********',
              hintStyle: TextStyle(
                color: Colors.white60,
              ),
              labelText: 'كلمة المرور ',
              labelStyle: TextStyle(
                color: Colors.white,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isAuthenticating ? null : onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: AppColors.primaryGreen.withValues(alpha: 0.5),
            ),
            child: isAuthenticating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'دخول',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        if (isBiometricAvailable && onBiometricLogin != null) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Container(height: 1, color: Colors.white12)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'أو باستخدام البصمة',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              Expanded(child: Container(height: 1, color: Colors.white12)),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: isAuthenticating ? null : onBiometricLogin,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isAuthenticating) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'جاري التحقق من السيرفر...',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.fingerprint_rounded,
                      color: AppColors.primaryGreen,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'تسجيل الدخول بالبصمة',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
