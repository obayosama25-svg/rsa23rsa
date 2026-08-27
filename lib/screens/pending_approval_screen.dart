import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../services/session_manager.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingEmail = prefs.getString('pending_approval_email') ?? prefs.getString('pending_approval_account');
      
      if (pendingEmail != null && pendingEmail.isNotEmpty) {
        final res = await ApiService.get('/users/status/$pendingEmail');
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['isApproved'] == true || data['status'] == 'approved' || data['status'] == 'active') {
            await prefs.remove('pending_approval_email');
            await prefs.remove('pending_approval_account');
            await prefs.remove('pending_approval_name');

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تهانينا! تمت الموافقة على حسابك وتفعيله بنجاح 🎉'),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
            return;
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الحساب لا يزال قيد المراجعة والتدقيق، يرجى الانتظار.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر الاتصال بالسيرفر للتحقق من الحالة.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_approval_email');
    await prefs.remove('pending_approval_account');
    await prefs.remove('pending_approval_name');
    await SessionManager().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // خلفية راقية متدرجة
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A), // Dark slate
                    AppColors.darkBackground,
                    Color(0xFF022C22), // Very dark green tint
                  ],
                ),
              ),
            ),
          ),
          // شكل تجريدي متوهج (Abstract Glow)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.1), blurRadius: 100),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: const AppLogo(width: 180),
                    ),
                    const SizedBox(height: 60),
                    
                    // أيقونة نبض هادئة
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryGreen.withValues(alpha: 0.1),
                            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            size: 80,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    FadeInUp(
                      duration: const Duration(milliseconds: 900),
                      child: const Text(
                        'حسابك قيد المراجعة الآمنة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: const Text(
                        'نعمل حالياً على تدقيق بياناتك لضمان أعلى معايير الأمان لحسابك المالي.\nسيتم إشعارك بمجرد التفعيل.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // أزرار التحكم الجديدة
                    FadeInUp(
                      duration: const Duration(milliseconds: 1100),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: _isChecking 
                                  ? const SizedBox(
                                      width: 20, height: 20, 
                                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                                    )
                                  : const Icon(Icons.refresh_rounded),
                              label: const Text('تحديث الحالة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              onPressed: _isChecking ? null : _checkStatus,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white60,
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('تسجيل الخروج', style: TextStyle(fontSize: 16)),
                            onPressed: _logout,
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
