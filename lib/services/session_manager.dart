import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_account.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'registration_service.dart';
import 'api_service.dart';
import 'biometric_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SessionManager — إدارة جلسة المستخدم النشطة
///
/// يتولى:
/// • حفظ واسترجاع بيانات الجلسة من SharedPreferences
/// • التحقق التلقائي عند فتح التطبيق
/// • تسجيل الخروج وتنظيف الجلسة
/// • ربط الجهاز بالحساب (أمان: حساب واحد لكل جهاز)
/// ─────────────────────────────────────────────────────────────────────────────
class SessionManager {
  static const String _keyUserId      = 'session_user_id';
  static const String _keyIsLoggedIn  = 'session_is_logged_in';
  static const String _keyDeviceId    = 'session_device_id';
  static const String _keyToken       = 'session_jwt_token';

  final DatabaseService _db   = DatabaseService();
  final AuthService     _auth = AuthService();

  // ─── Singleton ─────────────────────────────────────────────────
  static SessionManager? _instance;
  SessionManager._internal();
  factory SessionManager() {
    _instance ??= SessionManager._internal();
    return _instance!;
  }

  // ─── حالة الجلسة الحالية في الذاكرة ──────────────────────────
  UserAccount? _currentUser;
  UserAccount? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  
  String? _token;
  String? get token => _token;

  // ─── بدء التطبيق: التحقق من وجود جلسة سابقة ──────────────────

  /// يُستدعى عند بدء التطبيق في SplashScreen
  /// يُعيد المستخدم إذا كانت الجلسة نشطة، أو null إذا لم تكن
  Future<UserAccount?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final savedUserId = prefs.getString(_keyUserId);
      final savedToken = prefs.getString(_keyToken);

      if (!isLoggedIn || savedUserId == null) return null;

      // التحقق من الجهاز (إن وجد)
      final currentDeviceId = await RegistrationService.getDeviceId();
      final savedDeviceId   = prefs.getString(_keyDeviceId);

      if (savedDeviceId != null && savedDeviceId.isNotEmpty && currentDeviceId != savedDeviceId) {
        debugPrint('[Session] الجهاز تغيّر — مسح الجلسة ⚠️');
        await logout();
        return null;
      }

      // جلب بيانات المستخدم المباشرة من السيرفر (Stateless)
      _token = savedToken; // تعيين التوكن لاستخدامه عبر ApiService
      
      try {
        final response = await ApiService.get('/users/me');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final serverUser = data['user'] ?? data['data'] ?? {};
            final accountNum = serverUser['accountNumber']?.toString() ?? '';
            final uId = serverUser['userId'] ?? (accountNum.isNotEmpty ? '2490$accountNum' : (serverUser['_id'] ?? savedUserId));
            _currentUser = UserAccount(
              id: uId,
              accountNumber: accountNum,
              email: serverUser['email'] ?? '',
              loginPasswordHash: '', // بيانات وهمية لأسباب أمنية
              passwordHash: '',
              pinHash: '',
              hasSetPin: true,
              firstName: serverUser['firstName'] ?? '',
              middleName: serverUser['middleName'] ?? '',
              lastName: serverUser['lastName'] ?? '',
              dateOfBirth: DateTime.now(),
              balance: (serverUser['balance'] as num?)?.toDouble() ?? 0.0,
              creationDate: DateTime.now(),
              deviceId: savedDeviceId ?? currentDeviceId,
              isActive: true,
            );
            debugPrint('[Session] تم استعادة الجلسة بأمان من السيرفر: ${_currentUser!.id} ✅');
            return _currentUser;
          }
        } else if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 404) {
          // فقط عند رفض السيرفر الصريح للتوكن أو عدم وجود الحساب يتم مسح وتطهير الجلسة
          debugPrint('[Session] التوكن غير صالح أو الحساب غير موجود على السيرفر ⚠️');
          await BiometricService().purgeAllDeviceData();
          await logout();
          return null;
        }
      } catch (apiErr) {
        debugPrint('[Session] خطأ أثناء جلب بيانات الجلسة من السيرفر: $apiErr');
      }

      return null;
    } catch (e) {
      debugPrint('[Session] خطأ في استعادة الجلسة: $e');
      return null;
    }
  }

  // ─── تسجيل الدخول ──────────────────────────────────────────────

  /// تسجيل الدخول وحفظ الجلسة
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final result = await _auth.login(
      email: email,
      loginPassword: password,
    );

    if (result.isSuccess && result.user != null) {
      _currentUser = result.user;
      await _saveSession(result.user!, result.token ?? '');

      // تحديث بيانات البصمة في حال كانت مفعّلة مسبقاً
      final bio = BiometricService();
      if (await bio.isBiometricEnabled()) {
        await bio.saveBiometricCredentials(
          accountNumber: result.user!.accountNumber,
          token: result.token ?? '',
          email: result.user!.email,
        );
      }
    }

    return result;
  }

  /// تسجيل الدخول بالبصمة باستخدام الاعتمادات المحفوظة
  Future<AuthResult> loginWithBiometric() async {
    try {
      final bioService = BiometricService();
      final creds = await bioService.getSavedBiometricCredentials();
      if (creds == null) {
        return AuthResult.failure('لا توجد بيانات بصمة محفوظة، يرجى الدخول بكلمة المرور أولاً');
      }

      final authenticated = await bioService.authenticate(
        localizedReason: 'يرجى تأكيد هويتك عبر البصمة لتسجيل الدخول إلى SudaCards',
      );

      if (!authenticated) {
        return AuthResult.failure('فشل التحقق من البصمة أو تم إلغاؤه');
      }

      final savedToken = creds['token']!;
      _token = savedToken;

      final response = await ApiService.get('/users/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final serverUser = data['user'];
          final currentDeviceId = await RegistrationService.getDeviceId();
          final accountNum = serverUser['accountNumber']?.toString() ?? creds['accountNumber'] ?? '';
          final uId = serverUser['userId'] ?? (accountNum.isNotEmpty ? '2490$accountNum' : (serverUser['_id'] ?? ''));
          _currentUser = UserAccount(
            id: uId,
            accountNumber: accountNum,
            email: serverUser['email'] ?? creds['email'] ?? '',
            loginPasswordHash: '',
            passwordHash: '',
            pinHash: '',
            hasSetPin: true,
            firstName: serverUser['firstName'] ?? '',
            middleName: serverUser['middleName'] ?? '',
            lastName: serverUser['lastName'] ?? '',
            dateOfBirth: DateTime.now(),
            balance: (serverUser['balance'] as num?)?.toDouble() ?? 0.0,
            creationDate: DateTime.now(),
            deviceId: currentDeviceId,
            isActive: true,
          );
          await _saveSession(_currentUser!, savedToken);
          debugPrint('[BiometricLogin] تم الدخول بالبصمة بنجاح ✅');
          return AuthResult.success(_currentUser!, savedToken);
        }
      } else if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 404) {
        debugPrint('[BiometricLogin] الحساب غير موجود على السيرفر أو تم حذفه، تطهير البيانات... 🧹');
        await bioService.purgeAllDeviceData();
        return AuthResult.failure('الحساب غير موجود على السيرفر أو تم حذفه، تم تنظيف الهاتف');
      }

      return AuthResult.failure('انتهت صلاحية الجلسة، يرجى تسجيل الدخول بكلمة المرور');
    } catch (e) {
      debugPrint('[BiometricLogin] خطأ في تسجيل الدخول بالبصمة: $e');
      return AuthResult.failure('حدث خطأ أثناء المصادقة البيومترية');
    }
  }

  /// تسجيل مستخدم جديد وحفظ جلسته تلقائياً
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
  }) async {
    final result = await _auth.register(
      email: email,
      loginPassword: loginPassword,
      bankPassword: bankPassword,
      pin: pin,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      idImagePath: idImagePath,
    );

    if (result.isSuccess && result.user != null) {
      _currentUser = result.user;
      await _saveSession(result.user!, result.token ?? '');
    }

    return result;
  }

  Future<AuthResult> verifyOtp(String email, String otpCode) async {
    return await _auth.verifyOtp(email, otpCode);
  }

  // ─── تحديث بيانات المستخدم في الجلسة ──────────────────────────

  /// يُستدعى بعد أي تعديل على الحساب (تغيير رصيد، PIN، إلخ)
  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    final updated = await _db.getUserById(_currentUser!.id);
    if (updated != null) _currentUser = updated;
  }

  /// تحديث الرصيد في الذاكرة مباشرةً (بعد عملية ناجحة)
  void updateBalanceLocally(double newBalance) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(balance: newBalance);
  }

  // ─── تغيير الـ PIN ──────────────────────────────────────────────

  Future<AuthResult> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (_currentUser == null) return AuthResult.failure('لا توجد جلسة نشطة');
    final result = await _auth.changePin(
      userId: _currentUser!.id,
      currentPin: currentPin,
      newPin: newPin,
    );
    if (result.isSuccess) await refreshUser();
    return result;
  }

  // ─── تغيير كلمة مرور التطبيق ───────────────────────────────────

  Future<AuthResult> changeLoginPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return AuthResult.failure('لا توجد جلسة نشطة');
    final result = await _auth.changeLoginPassword(
      userId: _currentUser!.id,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (result.isSuccess) await refreshUser();
    return result;
  }

  // ─── التحقق من الـ PIN ──────────────────────────────────────────

  Future<bool> verifyPin(String pin) async {
    if (_currentUser == null) return false;
    return _auth.verifyPin(_currentUser!.id, pin);
  }

  // ─── تسجيل الخروج ──────────────────────────────────────────────

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyDeviceId);
    await prefs.remove(_keyToken);
    await prefs.setBool(_keyIsLoggedIn, false);
    debugPrint('[Session] تم تسجيل الخروج ✅');
  }

  // ─── حفظ الجلسة داخلياً ────────────────────────────────────────

  Future<void> _saveSession(UserAccount user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await RegistrationService.getDeviceId();
    await prefs.setString(_keyUserId, user.id);
    await prefs.setString(_keyDeviceId, deviceId);
    await prefs.setString(_keyToken, token);
    await prefs.setBool(_keyIsLoggedIn, true);
    _token = token;
    debugPrint('[Session] تم حفظ الجلسة: ${user.id} ✅');
  }

  // تحديث بيانات المستخدم الحالي (مثلاً بعد تعيين رمز PIN)
  void updateSessionUser(UserAccount user) {
    _currentUser = user;
  }

  // ─── مساعد: التحقق إذا كان الجهاز مرتبطاً بحساب ──────────────

  /// يُستخدم في شاشة التسجيل لمنع إنشاء حساب ثانٍ على نفس الجهاز
  Future<bool> isDeviceAlreadyRegistered() async {
    final deviceId = await RegistrationService.getDeviceId();
    return !(await _db.isDeviceFree(deviceId));
  }
}
