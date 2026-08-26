import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'database_service.dart';
import 'registration_service.dart';
import 'api_service.dart';
import '../models/user_account.dart';


/// ─────────────────────────────────────────────────────────────────────────────
/// AuthService — خدمة المصادقة والتشفير
///
/// تتولى:
/// • تشفير كلمات المرور والـ PIN
/// • التحقق عند الدخول
/// • إنشاء حسابات جديدة
/// • التحقق من قيود الجهاز (حساب واحد لكل جهاز)
/// ─────────────────────────────────────────────────────────────────────────────
class AuthService {
  final DatabaseService _db = DatabaseService();

  // ─── التشفير ────────────────────────────────────────────────────

  /// تشفير أي نص بـ SHA-256
  static String hashValue(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// التحقق من تطابق النص مع الـ hash المخزن
  static bool verifyHash(String input, String storedHash) {
    return hashValue(input) == storedHash;
  }

  // ─── توليد القيم الأمنية ─────────────────────────────────────────

  /// توليد كلمة مرور قوية (8 محارف: حروف + أرقام + رموز)
  static String generateStrongPassword() {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghjkmnpqrstuvwxyz';
    const digits = '23456789';
    const symbols = '!@#\$%^&*';
    const all = upper + lower + digits + symbols;

    final rng = Random.secure();
    // ضمان وجود كل نوع على الأقل مرة واحدة
    final required = [
      upper[rng.nextInt(upper.length)],
      lower[rng.nextInt(lower.length)],
      digits[rng.nextInt(digits.length)],
      symbols[rng.nextInt(symbols.length)],
    ];
    final rest = List.generate(4, (_) => all[rng.nextInt(all.length)]);
    final combined = [...required, ...rest]..shuffle(rng);
    return combined.join();
  }

  /// توليد رقم PIN للصراف (4 أرقام)
  static String generatePin() {
    final rng = Random.secure();
    return List.generate(4, (_) => rng.nextInt(10).toString()).join();
  }

  /// توليد معرف عملية فريد (UUID بسيط)
  static String generateTransactionId() {
    final bytes = Uint8List(16);
    final rng = Random.secure();
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // ─── إنشاء حساب جديد ────────────────────────────────────────────

  Future<AuthResult> register({
    required String email,
    required String loginPassword,
    required String bankPassword,
    required String pin,
    required String firstName,
    required String middleName,
    required String lastName,
    required DateTime dateOfBirth,
    String? idImagePath,
    String? personalPhotoPath,
    String? signaturePhotoPath,
  }) async {
    try {
      final deviceId = await RegistrationService.getDeviceId();
      
      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/users/register'));
      request.fields['category'] = 'individual';
      request.fields['email'] = email.toLowerCase().trim();
      request.fields['password'] = loginPassword;
      request.fields['deviceId'] = deviceId;
      request.fields['firstName'] = firstName.trim();
      request.fields['middleName'] = middleName.trim();
      request.fields['lastName'] = lastName.trim();
      request.fields['dateOfBirth'] = dateOfBirth.toIso8601String();

      if (idImagePath != null && !kIsWeb) {
        request.files.add(await http.MultipartFile.fromPath('idPhoto', idImagePath));
      }
      if (personalPhotoPath != null && !kIsWeb) {
        request.files.add(await http.MultipartFile.fromPath('personalPhoto', personalPhotoPath));
      }
      if (signaturePhotoPath != null && !kIsWeb) {
        request.files.add(await http.MultipartFile.fromPath('signaturePhoto', signaturePhotoPath));
      }

      var streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      var response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        // Return a mock success so the UI can proceed to OTP
        final account = UserAccount(
          id: data['data']['userId'],
          accountNumber: data['data']['accountNumber'],
          email: email,
          loginPasswordHash: hashValue(loginPassword),
          passwordHash: hashValue(bankPassword),
          pinHash: hashValue(pin),
          firstName: firstName,
          middleName: middleName,
          lastName: lastName,
          dateOfBirth: dateOfBirth,
          idImagePath: idImagePath,
          balance: 0.0,
          creationDate: DateTime.now().toUtc(),
          deviceId: deviceId,
        );
        return AuthResult.success(account);
      } else {
        return AuthResult.failure(data['message'] ?? 'فشل التسجيل في السيرفر');
      }
    } catch (e) {
      debugPrint('[Auth] خطأ في التسجيل عبر السيرفر: $e');
      return AuthResult.failure('حدث خطأ في الاتصال بالخادم أثناء التسجيل');
    }
  }

  // ─── الدخول ────────────────────────────────────────────────────

  /// تسجيل الدخول بالبريد وكلمة المرور
  /// TODO: [BACKEND] أرسل POST /api/login وتحقق من الـ token
  /// تسجيل الدخول بالبريد وكلمة المرور
  /// تم الربط بالسيرفر وتحميل البيانات وتحديث قاعدة البيانات المحلية
  Future<AuthResult> login({
    required String email,
    required String loginPassword,
  }) async {
    try {
      final deviceId = await RegistrationService.getDeviceId();

      // إرسال الطلب للسيرفر
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/users/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'password': loginPassword,
          'deviceId': deviceId,
        }),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final serverUser = data['user'];
        final token = data['token'];
        
        // رسم وتجهيز كائن الحساب لحفظه محلياً كـ Cache
        final account = UserAccount(
          id: serverUser['id'],
          accountNumber: serverUser['accountNumber'],
          email: serverUser['email'].toString().toLowerCase().trim(),
          loginPasswordHash: hashValue(loginPassword),
          passwordHash: hashValue('bank1234'), // افتراضي متطابق مع السيرفر
          pinHash: hashValue('1234'), // افتراضي
          firstName: serverUser['firstName'] ?? '',
          middleName: ' ',
          lastName: serverUser['lastName'] ?? '',
          dateOfBirth: DateTime.now(), // افتراضي للتخزين المحلي
          idImagePath: '',
          balance: (serverUser['balance'] as num).toDouble(),
          creationDate: DateTime.now(),
          deviceId: deviceId,
          isActive: true,
        );

        // 🚀 تحديث أمني: لم نعد نحفظ أي بيانات في قاعدة البيانات المحلية!
        // الاعتماد كلياً على الذاكرة المؤقتة (RAM) والـ Token
        
        debugPrint('[Auth] تم الدخول والاتصال بالسيرفر بنجاح: ${account.id} ✅');
        return AuthResult.success(account, token);
      } else {
        final errorMsg = data['message'] ?? 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        final status = data['status'];
        return AuthResult.failure(errorMsg, status: status);
      }
    } catch (e) {
      debugPrint('[Auth] خطأ في الدخول عبر السيرفر: $e');
      return AuthResult.failure('حدث خطأ في الاتصال بالخادم. يرجى التأكد من تشغيل السيرفر ووجود إنترنت.');
    }
  }

  /// الدخول بالجهاز فقط (تم تعطيله لأسباب أمنية لمنع حفظ الحساب محلياً)
  Future<AuthResult> loginByDevice() async {
    return AuthResult.failure('الرجاء تسجيل الدخول مجدداً.');
  }

  // ─── التحقق من الـ OTP ───────────────────────────────────────────
  Future<AuthResult> verifyOtp(String email, String otpCode) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/users/verify-otp'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email.toLowerCase().trim(),
          'otpCode': otpCode,
        }),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return AuthResult.success(null);
      } else {
        return AuthResult.failure(data['message'] ?? 'رمز التحقق غير صحيح');
      }
    } catch (e) {
      debugPrint('[Auth] خطأ في تأكيد الـ OTP عبر السيرفر: $e');
      return AuthResult.failure('حدث خطأ في الاتصال بالخادم أثناء التحقق من الرمز');
    }
  }

  // ─── التحقق من الـ PIN ───────────────────────────────────────────

  Future<bool> verifyPin(String userId, String pin) async {
    final user = await _db.getUserById(userId);
    if (user == null) return false;
    return verifyHash(pin, user.pinHash);
  }

  /// تغيير رقم الـ PIN
  Future<AuthResult> changePin({
    required String userId,
    required String currentPin,
    required String newPin,
  }) async {
    if (!await verifyPin(userId, currentPin)) {
      return AuthResult.failure('رقم PIN الحالي غير صحيح');
    }
    if (newPin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(newPin)) {
      return AuthResult.failure('يجب أن يكون PIN مكوناً من 4 أرقام');
    }
    await _db.updatePin(userId, hashValue(newPin));
    return AuthResult.success(null);
  }

  /// تغيير كلمة مرور التطبيق
  Future<AuthResult> changeLoginPassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = await _db.getUserById(userId);
    if (user == null) return AuthResult.failure('الحساب غير موجود');
    if (!verifyHash(currentPassword, user.loginPasswordHash)) {
      return AuthResult.failure('كلمة المرور الحالية غير صحيحة');
    }
    await _db.updateLoginPassword(userId, hashValue(newPassword));
    return AuthResult.success(null);
  }
}

// ─── نتيجة العملية ────────────────────────────────────────────────
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserAccount? user;
  final String? token;
  final String? status;

  const AuthResult._({
    required this.isSuccess,
    this.errorMessage,
    this.user,
    this.token,
    this.status,
  });

  factory AuthResult.success(UserAccount? user, [String? token]) =>
      AuthResult._(isSuccess: true, user: user, token: token);

  factory AuthResult.failure(String message, {String? status}) =>
      AuthResult._(isSuccess: false, errorMessage: message, status: status);
}
