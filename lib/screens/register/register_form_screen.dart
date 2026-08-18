import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sudacards/theme/app_colors.dart';
import 'package:sudacards/models/profile_models.dart';
import 'package:sudacards/widgets/cyber_background.dart';
import 'package:sudacards/screens/register/controllers/register_form_controller.dart';
import 'package:sudacards/screens/register/widgets/terms_dialog.dart';
import 'package:sudacards/screens/register/widgets/accepted_docs_dialog.dart';
import 'widgets/register_form_steps.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// RegisterFormScreen
/// واجهة التسجيل الأساسية (UI فقط). تعتمد على [RegisterFormController] لإدارة المنطق.
/// مسار التوجيه الحالي: Login -> Register Category -> Register Form -> Pending
/// ─────────────────────────────────────────────────────────────────────────────
class RegisterFormScreen extends StatefulWidget {
  final AccountCategory initialCategory;
  final AccountSubType initialSubType;

  const RegisterFormScreen({
    super.key,
    required this.initialCategory,
    required this.initialSubType,
  });

  @override
  State<RegisterFormScreen> createState() => _RegisterFormScreenState();
}

class _RegisterFormScreenState extends State<RegisterFormScreen> {
  // 1. Initial Setup (Setup Controller)
  late final RegisterFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RegisterFormController(
      context, 
      category: widget.initialCategory, 
      subType: widget.initialSubType,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // حاوية زجاجية للتصميم
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
    // 2. Main Scaffold & Background
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(decoration: const BoxDecoration(color: AppColors.darkBackground)),
          ),
          const Positioned.fill(
            child: TechGridBackground(),
          ),
          SafeArea(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryBlue),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'إكمال التسجيل',
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48), // Balance spacing
                        ],
                      ),
                    ),

                    // Progress Indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Row(
                        children: List.generate(3, (index) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 4,
                              decoration: BoxDecoration(
                                color: _controller.currentPage >= index ? AppColors.primaryGreen : AppColors.glassBorder,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Form Steps PageView
                    Expanded(
                      child: PageView(
                        controller: _controller.pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: _controller.setPage,
                        children: [
                          // Page 1: Basic Info & Fields
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: RegisterFormSteps.buildPage1(
                              category: _controller.formData.category,
                              phoneController: _controller.phoneController,
                              emailController: _controller.emailController,
                              passwordController: _controller.passwordController,
                              confirmPasswordController: _controller.confirmPasswordController,
                              firstNameController: _controller.firstNameController,
                              fatherNameController: _controller.fatherNameController,
                              grandFatherNameController: _controller.grandFatherNameController,
                              lastNameController: _controller.lastNameController,
                              entityNameController: _controller.entityNameController,
                              commercialRegController: _controller.commercialRegController,
                              managerController: _controller.managerController,
                              addressController: _controller.addressController,
                              glassWrapper: ({required Widget child}) =>
                                  _buildGlassContainer(child: child),
                            ),
                          ),
                          // Page 2: Advanced Info & Docs
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: RegisterFormSteps.buildPage2(
                              category: _controller.formData.category,
                              personalPhoto: _controller.personalPhoto,
                              idPhoto: _controller.idPhoto,
                              signaturePhoto: _controller.signaturePhoto,
                              commercialDocPhoto: _controller.commercialDocPhoto,
                              logoPhoto: _controller.logoPhoto,
                              onPickImage: (type) => _controller.pickImage(ImageSource.camera, type),
                              onShowAcceptedDocs: () => AcceptedDocsDialog.show(context),
                              glassWrapper: ({required Widget child}) =>
                                  _buildGlassContainer(child: child),
                            ),
                          ),
                          // Page 3: Terms & Conditions
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: RegisterFormSteps.buildPage3(
                              acceptedTerms: _controller.acceptedTerms,
                              onTermsChanged: (v) => _controller.setAcceptedTerms(v ?? false),
                              onShowTerms: () => TermsDialog.show(context),
                              glassWrapper: ({required Widget child}) =>
                                  _buildGlassContainer(child: child),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 4. Navigation & Action Buttons
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface.withValues(alpha: 0.9),
                        border: Border(top: BorderSide(color: AppColors.glassBorder)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_controller.currentPage > 0)
                            TextButton(
                              onPressed: () {
                                _controller.pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: const Text('السابق', style: TextStyle(color: Colors.white70, fontSize: 16)),
                            )
                          else
                            const SizedBox(width: 60),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _controller.isRegistering
                                ? null
                                : () {
                                    if (_controller.currentPage < 2) {
                                      _controller.pageController.nextPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    } else {
                                      _controller.completeRegistration();
                                    }
                                  },
                            child: _controller.isRegistering
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: AppColors.darkBackground, strokeWidth: 2),
                                  )
                                : Text(
                                    _controller.currentPage < 2 ? 'التالي' : 'إرسال الطلب',
                                    style: const TextStyle(
                                      color: AppColors.darkBackground,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
