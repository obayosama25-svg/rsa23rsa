import 'dart:ui';
import 'package:sudacards/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/session_manager.dart';
import '../services/registration_service.dart';
import '../models/profile_models.dart';
import '../widgets/cyber_background.dart';
import 'register/widgets/register_form_steps.dart';
import 'register/otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _grandFatherNameController =
      TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _entityNameController = TextEditingController();
  final TextEditingController _commercialRegController =
      TextEditingController();
  final TextEditingController _managerController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Files
  XFile? _personalPhoto;
  XFile? _passportPhoto;
  XFile? _signaturePhoto;

  final ImagePicker _picker = ImagePicker();

  bool _isRegistering = false;
  bool _acceptedTerms = false;

  void _showTermsDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, a1, a2) {
        return ScaleTransition(
          scale: a1,
          child: AlertDialog(
            backgroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
            title: const Text(
              'المواثيق الأمنية //',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),
            content: const SingleChildScrollView(
              child: Text(
                '1. باتصالك بالشبكة الآمنة، أنت توافق على جميع الشروط.\n\n'
                '2. سيتم تشفير وتأمين مسحك الحيويومسح الأوراق الرسمية.\n\n'
                '3. سيتم تفعيل القفل العتادي بجهازك فور اكتمال إنشاء الحساب.\n\n'
                '4. حافظ على الحماية القصوى لبياناتك.\n',
                style: TextStyle(
                  height: 1.5,
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'تأكيد وفهم',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAcceptedDocsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'المستندات المقبولة',
          style: TextStyle(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '• بطاقة قومية سارية المفعول\n• جواز سفر ساري\n• رخصة قيادة سارية\n\nيجب أن يتم تصوير المستندات والشخصية بكاميرا الهاتف مباشرة لتأكيد الهوية وأن تكون الصور واضحة ومقروءة.',
          style: TextStyle(color: Colors.white70, height: 1.8),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'حسناً',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        if (type == 'personal') _personalPhoto = image;
        if (type == 'id') _passportPhoto = image;
        if (type == 'signature') _signaturePhoto = image;
      });
    }
  }

  Future<void> _completeRegistration() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'فشل العبور: يجب قبول المواثيق الأمنية.',
            style: TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_firstNameController.text.isEmpty ||
        _fatherNameController.text.isEmpty ||
        _grandFatherNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'بيانات مفقودة: الحقول مطلوبة.',
            style: TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'كلمة المرور غير متطابقة.',
            style: TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    if (_personalPhoto == null ||
        _passportPhoto == null ||
        _signaturePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'نقص في المسح الضوئي: وفر كامل المستندات.',
            style: TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isRegistering = true);

    try {
      final session = SessionManager();

      // التحقق من أن الجهاز غير مرتبط بحساب آخر
      final alreadyRegistered = await session.isDeviceAlreadyRegistered();
      if (alreadyRegistered) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذا الجهاز مرتبط بحساب موجود بالفعل.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isRegistering = false);
        return;
      }

      // توليد كلمة مرور وPIN مؤقتَين للعمل المحلي
      // TODO: [BACKEND] المستخدم سيُدخل هذه البيانات في شاشة مخصصة
      final autoPassword = RegistrationService.generateStrongPassword();
      final autoPin = '0000'; // PIN افتراضي — يغيّره المستخدم لاحقاً

      final first = _firstNameController.text.trim();
      final middle =
          '${_fatherNameController.text.trim()} ${_grandFatherNameController.text.trim()}'
              .trim();
      final last = _lastNameController.text.trim();

      final result = await session.register(
        email: _emailController.text.trim(),
        loginPassword: autoPassword,
        bankPassword: autoPassword,
        pin: autoPin,
        firstName: first,
        middleName: middle,
        lastName: last,
        dateOfBirth: DateTime(
          2000,
          1,
          1,
        ), // TODO: إضافة حقل تاريخ الميلاد للنموذج
        idImagePath: _passportPhoto?.path,
      );

      if (!result.isSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'خطأ غير متوقع'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isRegistering = false);
        return;
      }

      final account = result.user!;

      // Simulate processing
      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OTPVerificationScreen(
            email: _emailController.text.trim(),
            account: account,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ نظام: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _fatherNameController.dispose();
    _grandFatherNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _entityNameController.dispose();
    _commercialRegController.dispose();
    _managerController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.darkSurface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
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
                  center: const Alignment(0, -0.5),
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
              opacity: Theme.of(context).brightness == Brightness.dark
                  ? 0.3
                  : 0.05,
              child: const TechGridBackground(),
            ),
          ),
          // Top AppBar Replacement
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.primaryGreen,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        'التسجيل المشفر',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // balance
                    ],
                  ),
                ),
                // Main Carousel area
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: RegisterFormSteps.buildPage1(
                            category: AccountCategory.individual,
                            phoneController: _phoneController,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            confirmPasswordController:
                                _confirmPasswordController,
                            firstNameController: _firstNameController,
                            fatherNameController: _fatherNameController,
                            grandFatherNameController:
                                _grandFatherNameController,
                            lastNameController: _lastNameController,
                            entityNameController: _entityNameController,
                            commercialRegController: _commercialRegController,
                            managerController: _managerController,
                            addressController: _addressController,
                            glassWrapper: ({required Widget child}) =>
                                _buildGlassContainer(child: child),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: RegisterFormSteps.buildPage2(
                            category: AccountCategory.individual,
                            personalPhoto: _personalPhoto,
                            idPhoto: _passportPhoto,
                            signaturePhoto: _signaturePhoto,
                            commercialDocPhoto: null,
                            logoPhoto: null,
                            onPickImage: (type) =>
                                _pickImage(ImageSource.camera, type),
                            onShowAcceptedDocs: _showAcceptedDocsDialog,
                            glassWrapper: ({required Widget child}) =>
                                _buildGlassContainer(child: child),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: RegisterFormSteps.buildPage3(
                            acceptedTerms: _acceptedTerms,
                            onTermsChanged: (v) =>
                                setState(() => _acceptedTerms = v ?? false),
                            onShowTerms: _showTermsDialog,
                            glassWrapper: ({required Widget child}) =>
                                _buildGlassContainer(child: child),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer Navigation
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Progress dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          bool isActive = index <= _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 30 : 10,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primaryGreen
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primaryGreen
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : [],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentPage > 0)
                            TextButton(
                              onPressed: _isRegistering
                                  ? null
                                  : () {
                                      _pageController.previousPage(
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                              child: const Text(
                                'رجوع <<',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 80),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 10,
                              shadowColor: AppColors.primaryGreen.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            onPressed: _isRegistering
                                ? null
                                : () {
                                    if (_currentPage < 2) {
                                      _pageController.nextPage(
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    } else {
                                      _completeRegistration();
                                    }
                                  },
                            child: _isRegistering
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : Text(
                                    _currentPage < 2
                                        ? 'التالي >>'
                                        : 'إتمام العملية الآن',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
