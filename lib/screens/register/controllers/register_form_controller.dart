import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sudacards/models/profile_models.dart';
import 'package:sudacards/theme/app_colors.dart';
import 'package:sudacards/services/registration_service.dart';
import 'package:sudacards/screens/register/states/pending_status_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sudacards/screens/register/otp_verification_screen.dart';
import 'package:sudacards/models/user_account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudacards/services/api_service.dart';
/// ─────────────────────────────────────────────────────────────────────────────
/// RegisterFormController
/// هذا الكنترولر مسؤول عن التعامل مع جميع المدخلات والصور والمنطق الخاص بالتسجيل
/// مما يبقي الواجهة (UI) نظيفة ومخصصة للعرض فقط.
/// ─────────────────────────────────────────────────────────────────────────────
class RegisterFormController extends ChangeNotifier {
  final BuildContext context;
  
  // 1. حالة الفورم الأساسية
  late RegisterFormData formData;
  bool isRegistering = false;
  bool acceptedTerms = false;
  int currentPage = 0;
  final PageController pageController = PageController();

  // 2. متحكمات النصوص (Text Controllers)
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  // 3. متحكمات الأفراد
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController grandFatherNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();


  // 4. متحكمات الكيانات
  final TextEditingController entityNameController = TextEditingController();
  final TextEditingController commercialRegController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController managerController = TextEditingController();

  // 5. ملفات الصور (Images)
  XFile? personalPhoto;
  XFile? idPhoto; 
  XFile? signaturePhoto;
  XFile? commercialDocPhoto; 
  XFile? logoPhoto;

  final ImagePicker _picker = ImagePicker();
  bool _isPickingImage = false;


  RegisterFormController(this.context, {required AccountCategory category, required AccountSubType subType}) {
    formData = RegisterFormData()
      ..category = category
      ..subType = subType;
  }

  /// تغيير الصفحة الحالية في النموذج
  void setPage(int page) {
    currentPage = page;
    notifyListeners();
  }

  /// تغيير حالة قبول الشروط
  void setAcceptedTerms(bool value) {
    acceptedTerms = value;
    notifyListeners();
  }

  /// اختيار الصور
  Future<void> pickImage(ImageSource source, String type) async {
    if (_isPickingImage) return; // منع التداخل إذا كان الملتقط نشطاً بالفعل
    _isPickingImage = true;
    
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        if (type == 'personal') personalPhoto = image;
        if (type == 'id') idPhoto = image;
        if (type == 'signature') signaturePhoto = image;
        if (type == 'commercial') commercialDocPhoto = image;
        if (type == 'logo') logoPhoto = image;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[RegisterFormController] Error picking image: $e');
    } finally {
      _isPickingImage = false;
    }
  }

  /// إتمام عملية التسجيل (Validation + Payload)
  Future<void> completeRegistration() async {
    if (!acceptedTerms) {
      _showError('يجب قبول المواثيق لاستكمال التسجيل.');
      return;
    }
    
    bool isIndividual = formData.category == AccountCategory.individual;

    // التحقق من الحقول الأساسية
    if (phoneController.text.isEmpty || emailController.text.isEmpty || 
        passwordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      _showError('جميع الحقول الأساسية مطلوبة.');
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showError('كلمات المرور غير متطابقة.');
      return;
    }

    // التحقق من الصور والبيانات المتخصصة
    if (isIndividual) {
      if (firstNameController.text.isEmpty || fatherNameController.text.isEmpty || 
          grandFatherNameController.text.isEmpty || lastNameController.text.isEmpty || 
          personalPhoto == null || idPhoto == null || signaturePhoto == null) {
        _showError('جميع حقول الأفراد والصور (الشخصية، الهوية، التوقيع) مطلوبة.');
        return;
      }
    } else {
      if (entityNameController.text.isEmpty || commercialRegController.text.isEmpty || 
          addressController.text.isEmpty || managerController.text.isEmpty || commercialDocPhoto == null) {
        _showError('جميع حقول الكيان والمستند الرسمي للكيان مطلوبة.');
        return;
      }
    }

    // بدء التحميل
    isRegistering = true;
    notifyListeners();

    try {
      // 1. جلب معرف الجهاز
      String deviceId = await RegistrationService.getDeviceId();

      // 2. إرسال الطلب الفعلي للسيرفر كـ Multipart Request لرفع الصور
      final uri = Uri.parse('${ApiService.baseUrl}/users/register');
      final request = http.MultipartRequest('POST', uri);

      // إضافة الحقول النصية (Text Fields)
      request.fields['category'] = formData.category.name;
      request.fields['subType'] = formData.subType.name;
      request.fields['phone'] = phoneController.text.trim();
      request.fields['email'] = emailController.text.trim();
      request.fields['password'] = passwordController.text;
      request.fields['deviceId'] = deviceId;
      
      if (isIndividual) {
        request.fields['firstName'] = firstNameController.text.trim();
        request.fields['middleName'] = '${fatherNameController.text.trim()} ${grandFatherNameController.text.trim()}';
        request.fields['lastName'] = lastNameController.text.trim();
        
        // إضافة الصور المرفوعة للأفراد
        if (personalPhoto != null) {
          final bytes = await personalPhoto!.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'personalPhoto',
            bytes,
            filename: personalPhoto!.name.isNotEmpty ? personalPhoto!.name : 'personalPhoto.jpg',
          ));
        }
        if (idPhoto != null) {
          final bytes = await idPhoto!.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'idPhoto',
            bytes,
            filename: idPhoto!.name.isNotEmpty ? idPhoto!.name : 'idPhoto.jpg',
          ));
        }
        if (signaturePhoto != null) {
          final bytes = await signaturePhoto!.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'signaturePhoto',
            bytes,
            filename: signaturePhoto!.name.isNotEmpty ? signaturePhoto!.name : 'signaturePhoto.jpg',
          ));
        }
      } else {
        request.fields['entityName'] = entityNameController.text.trim();
        request.fields['commercialReg'] = commercialRegController.text.trim();
        request.fields['address'] = addressController.text.trim();
        request.fields['managerName'] = managerController.text.trim();

        // إضافة الصور المرفوعة للشركات
        if (commercialDocPhoto != null) {
          final bytes = await commercialDocPhoto!.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'commercialDocPhoto',
            bytes,
            filename: commercialDocPhoto!.name.isNotEmpty ? commercialDocPhoto!.name : 'commercialDocPhoto.jpg',
          ));
        }
        if (logoPhoto != null) {
          final bytes = await logoPhoto!.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'logoPhoto',
            bytes,
            filename: logoPhoto!.name.isNotEmpty ? logoPhoto!.name : 'logoPhoto.jpg',
          ));
        }
      }

      debugPrint('=== SENDING MULTIPART REGISTRATION ===');
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (!context.mounted) return;

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final userData = data['data'] ?? {};
        userData['id'] = userData['userId'];
        userData['firstName'] = userData['fullName'];
        final account = UserAccount.fromMap(userData);

        // حفظ الإيميل المؤقت فقط ليتم استخدامه في شاشة الـ OTP
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('unverified_email', account.email);
        // تم إلغاء حفظ كائن الحساب بالكامل محلياً لرفع مستوى الأمان

        // 4. توجيه المستخدم لشاشة تأكيد البريد الإلكتروني (OTP)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              email: account.email,
              account: account,
            ),
          ),
          (route) => false,
        );
      } else {
        final errorMsg = data['message'] ?? 'فشلت عملية التسجيل. يرجى المحاولة لاحقاً.';
        _showError(errorMsg);
      }
    } catch (e) {
      debugPrint('[RegisterFormController] Connection error: $e');
      if (context.mounted) {
        _showError('خطأ في الاتصال بالخادم. يرجى التأكد من اتصالك بالإنترنت وسلامة الخادم.');
      }
    } finally {
      isRegistering = false;
      notifyListeners();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.warningOrange),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    fatherNameController.dispose();
    grandFatherNameController.dispose();
    lastNameController.dispose();
    entityNameController.dispose();
    commercialRegController.dispose();
    addressController.dispose();
    managerController.dispose();
    super.dispose();
  }
}
