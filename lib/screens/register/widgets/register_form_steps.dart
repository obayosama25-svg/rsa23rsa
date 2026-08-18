import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sudacards/theme/app_colors.dart';
import 'package:sudacards/models/profile_models.dart';

class RegisterFormSteps {
  static Widget buildPage1({
    required AccountCategory category,
    required TextEditingController phoneController,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController confirmPasswordController,
    required TextEditingController firstNameController,
    required TextEditingController fatherNameController,
    required TextEditingController grandFatherNameController,
    required TextEditingController lastNameController,
    required TextEditingController entityNameController,
    required TextEditingController commercialRegController,
    required TextEditingController managerController,
    required TextEditingController addressController,
    required Widget Function({required Widget child}) glassWrapper,
  }) {
    bool isIndividual = category == AccountCategory.individual;

    return glassWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeInDown(
            child: const Text(
              'البيانات الأساسية',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInLeft(
            delay: const Duration(milliseconds: 100),
            child: _buildNeonTextField(
              phoneController,
              'رقم الهاتف',
              Icons.phone_android,
              type: TextInputType.phone,
            ),
          ),
          const SizedBox(height: 16),
          FadeInLeft(
            delay: const Duration(milliseconds: 150),
            child: _buildNeonTextField(
              emailController,
              'البريد الإلكتروني',
              Icons.email_outlined,
              type: TextInputType.emailAddress,
            ),
          ),
          const SizedBox(height: 16),
          FadeInRight(
            delay: const Duration(milliseconds: 200),
            child: _buildNeonTextField(
              passwordController,
              'كلمة المرور',
              Icons.lock_outline,
              isPassword: true,
            ),
          ),
          const SizedBox(height: 16),
          FadeInRight(
            delay: const Duration(milliseconds: 250),
            child: _buildNeonTextField(
              confirmPasswordController,
              'تأكيد كلمة المرور',
              Icons.lock_outline,
              isPassword: true,
            ),
          ),
          const SizedBox(height: 16),
          if (isIndividual) ...[
            Row(
              children: [
                Expanded(
                  child: FadeInLeft(
                    delay: const Duration(milliseconds: 300),
                    child: _buildNeonTextField(
                      firstNameController,
                      'الاسم الأول',
                      SolarIconsOutline.user,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FadeInRight(
                    delay: const Duration(milliseconds: 350),
                    child: _buildNeonTextField(
                      fatherNameController,
                      'اسم الأب',
                      SolarIconsOutline.user,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FadeInLeft(
                    delay: const Duration(milliseconds: 400),
                    child: _buildNeonTextField(
                      grandFatherNameController,
                      'اسم الجد',
                      SolarIconsOutline.user,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FadeInRight(
                    delay: const Duration(milliseconds: 450),
                    child: _buildNeonTextField(
                      lastNameController,
                      'اسم العائلة / اللقب',
                      SolarIconsOutline.user,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            FadeInLeft(
              delay: const Duration(milliseconds: 300),
              child: _buildNeonTextField(
                entityNameController,
                'اسم ${category.label} المعتمد',
                Icons.business_outlined,
              ),
            ),
            const SizedBox(height: 16),
            FadeInRight(
              delay: const Duration(milliseconds: 400),
              child: _buildNeonTextField(
                commercialRegController,
                'رقم السجل / الترخيص (اختياري)',
                Icons.confirmation_number_outlined,
              ),
            ),
            const SizedBox(height: 16),
            FadeInLeft(
              delay: const Duration(milliseconds: 500),
              child: _buildNeonTextField(
                managerController,
                'اسم المسؤول',
                Icons.person_outline,
              ),
            ),
            const SizedBox(height: 16),
            FadeInRight(
              delay: const Duration(milliseconds: 600),
              child: _buildNeonTextField(
                addressController,
                'العنوان',
                Icons.location_on_outlined,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildPage2({
    required AccountCategory category,
    required XFile? personalPhoto,
    required XFile? idPhoto,
    required XFile? signaturePhoto,
    required XFile? commercialDocPhoto,
    required XFile? logoPhoto,
    required Function(String) onPickImage,
    required VoidCallback onShowAcceptedDocs,
    required Widget Function({required Widget child}) glassWrapper,
  }) {
    bool isIndividual = category == AccountCategory.individual;

    return glassWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeInDown(
            child: const Text(
              'المستندات والصور',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (isIndividual) ...[
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _buildScannerBox(
                'صورة شخصية',
                personalPhoto,
                'personal',
                onPickImage,
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildScannerBox(
                'إثبات الهوية (بطاقة/جواز)',
                idPhoto,
                'id',
                onPickImage,
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: _buildScannerBox(
                'صورة التوقيع',
                signaturePhoto,
                'signature',
                onPickImage,
              ),
            ),
            const SizedBox(height: 8),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: Center(
                child: TextButton.icon(
                  onPressed: onShowAcceptedDocs,
                  icon: const Icon(SolarIconsOutline.infoCircle, color: AppColors.primaryBlue),
                  label: const Text(
                    'عرض المستندات المقبولة',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _buildScannerBox(
                'شعار ${category.label} (Logo) - اختياري',
                logoPhoto,
                'logo',
                onPickImage,
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildScannerBox(
                'المستند الرسمي (سجل/رخصة)',
                commercialDocPhoto,
                'commercial',
                onPickImage,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildPage3({
    required bool acceptedTerms,
    required ValueChanged<bool?> onTermsChanged,
    required VoidCallback onShowTerms,
    required Widget Function({required Widget child}) glassWrapper,
  }) {
    return glassWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadeInDown(
            child: const Text(
              'المراجعة والموافقة',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeIn(
            delay: const Duration(milliseconds: 400),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.5),
                ),
              ),
              child: const Text(
                '> جاري الاستعداد لتأكيد الحساب...\n> مراجعة البيانات المدخلة...\n> تشفير المستندات وحفظها بأمان...',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontFamily: 'Courier',
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: Row(
              children: [
                Theme(
                  data: ThemeData(unselectedWidgetColor: Colors.white54),
                  child: Checkbox(
                    value: acceptedTerms,
                    activeColor: AppColors.primaryGreen,
                    checkColor: Colors.black,
                    onChanged: onTermsChanged,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTermsChanged(!acceptedTerms),
                    child: const Text(
                      'أقر وأوافق على ',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onShowTerms,
                  child: const Text(
                    'المواثيق والشروط',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildNeonTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? type,
    bool isPassword = false,
    String? prefixText,
    TextDirection? textDirection,
  }) {
    bool obscure = isPassword;
    
    // Default to LTR for phone, email, and password to avoid Bidi layout freezing in RTL
    final effectiveTextDirection = textDirection ?? 
        ((type == TextInputType.phone || 
          type == TextInputType.emailAddress || 
          isPassword) 
            ? TextDirection.ltr 
            : null);

    return StatefulBuilder(
      builder: (context, setState) {
        return TextField(
          controller: controller,
          keyboardType: type,
          obscureText: obscure,
          textDirection: effectiveTextDirection,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: Icon(icon, color: AppColors.primaryGreen),
            prefixText: prefixText,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        obscure = !obscure;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.darkSurfaceLight.withValues(alpha: 0.5),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildScannerBox(
    String title,
    XFile? file,
    String type,
    Function(String) onTap,
  ) {
    bool hasFile = file != null;
    return GestureDetector(
      onTap: () => onTap(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.4),
          border: Border.all(
            color: hasFile ? AppColors.primaryGreen : Colors.white24,
            width: hasFile ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: hasFile ? 1.0 : null,
                    color: hasFile
                        ? AppColors.primaryGreen
                        : AppColors.primaryBlue.withValues(alpha: 0.5),
                    strokeWidth: 2,
                  ),
                ),
                Icon(
                  hasFile ? Icons.check : Icons.cloud_upload_outlined,
                  color: hasFile ? AppColors.primaryGreen : Colors.white,
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasFile
                        ? 'تم رفع الملف بنجاح'
                        : 'انقر لرفع المستند / الصورة',
                    style: TextStyle(
                      color: hasFile ? AppColors.primaryGreen : Colors.grey,
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
