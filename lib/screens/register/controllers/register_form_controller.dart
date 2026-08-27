import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sudacards/models/profile_models.dart';
import 'package:sudacards/theme/app_colors.dart';
import 'package:sudacards/services/registration_service.dart';
import 'package:sudacards/screens/register/states/pending_status_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
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
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
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
        
        // إضافة الصور المرفوعة للأفراد مباشرة وبكفاءة عالية
        if (personalPhoto != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'personalPhoto',
            personalPhoto!.path,
            filename: 'personalPhoto.jpg',
          ));
        }
        if (idPhoto != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'idPhoto',
            idPhoto!.path,
            filename: 'idPhoto.jpg',
          ));
        }
        if (signaturePhoto != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'signaturePhoto',
            signaturePhoto!.path,
            filename: 'signaturePhoto.jpg',
          ));
        }
      } else {
        request.fields['entityName'] = entityNameController.text.trim();
        request.fields['commercialReg'] = commercialRegController.text.trim();
        request.fields['address'] = addressController.text.trim();
        request.fields['managerName'] = managerController.text.trim();

        // إضافة الصور المرفوعة للشركات
        if (commercialDocPhoto != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'commercialDocPhoto',
            commercialDocPhoto!.path,
            filename: 'commercialDocPhoto.jpg',
          ));
        }
        if (logoPhoto != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'logoPhoto',
            logoPhoto!.path,
            filename: 'logoPhoto.jpg',
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

        // حفظ بيانات الحساب المؤقتة فقط ليتم استخدامها في شاشة الـ OTP في حال خروج المستخدم
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('unverified_email', account.email);
        await prefs.setString('unverified_account_number', account.accountNumber);
        await prefs.setString('unverified_full_name', account.fullName);
        // تم إلغاء حفظ كائن الحساب بالكامل محلياً لرفع مستوى الأمان

        // 4. توجيه المستخدم لشاشة تأكيد البريد الإلكتروني (OTP)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              email: account.email,
              accountNumber: account.accountNumber,
              fullName: account.fullName,
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
        _showError('خطأ اتصال: ${e.runtimeType}: $e');
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

  /// ضغط الصورة لتقليل حجمها قبل الرفع (من 3-8 ميقا إلى ~200 كيلو)
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      // فك ترميز الصورة
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 800, // عرض أقصى 800 بكسل
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // إعادة ترميز كـ JPEG بجودة 70%
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData != null) {
        debugPrint('[Compress] ${imageBytes.length ~/ 1024}KB → ${byteData.lengthInBytes ~/ 1024}KB');
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('[Compress] فشل الضغط، سيتم استخدام الصورة الأصلية: $e');
    }
    return imageBytes; // إذا فشل الضغط، أرسل الأصلية
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
