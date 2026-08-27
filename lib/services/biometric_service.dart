import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// BiometricService — إدارة المصادقة ببصمة الإصبع و Face ID
/// ─────────────────────────────────────────────────────────────────────────────
class BiometricService {
  static const String _keyBiometricEnabled = 'biometric_login_enabled';
  static const String _keyBiometricAccount = 'biometric_saved_account';
  static const String _keyBiometricToken   = 'biometric_saved_token';
  static const String _keyBiometricEmail   = 'biometric_saved_email';

  final LocalAuthentication _auth = LocalAuthentication();

  static BiometricService? _instance;
  BiometricService._internal();
  factory BiometricService() {
    _instance ??= BiometricService._internal();
    return _instance!;
  }

  /// فحص هل يدعم الجهاز التحقق بالبصمة/البيومترك وهل هناك بصمة مسجلة
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      debugPrint('[Biometric] خطأ في فحص توفر البصمة: $e');
      return false;
    }
  }

  /// جلب أنواع البيومترك المتوفرة (Face, Fingerprint, Iris)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('[Biometric] خطأ في جلب أنواع البصمة: $e');
      return [];
    }
  }

  /// التحقق هل قام المستخدم بتفعيل الدخول بالبصمة من الإعدادات
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyBiometricEnabled) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// حفظ حالة تفعيل أو تعطيل البصمة
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
    if (!enabled) {
      await clearBiometricCredentials();
    }
  }

  /// طلب التحقق بالبصمة من النظام
  Future<bool> authenticate({String localizedReason = 'يرجى تأكيد هويتك عبر البصمة للمتابعة'}) async {
    try {
      final bool available = await isBiometricAvailable();
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint('[Biometric] فشل التحقق البيومتري: $e');
      return false;
    }
  }

  /// حفظ بيانات الجلسة للاستخدام مع الدخول بالبصمة
  Future<void> saveBiometricCredentials({
    required String accountNumber,
    required String token,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBiometricAccount, accountNumber);
    await prefs.setString(_keyBiometricToken, token);
    await prefs.setString(_keyBiometricEmail, email);
    await prefs.setBool(_keyBiometricEnabled, true);
    debugPrint('[Biometric] تم حفظ اعتمادات البصمة بنجاح ✅');
  }

  /// جلب بيانات الدخول المحفوظة للبصمة
  Future<Map<String, String>?> getSavedBiometricCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
    final token = prefs.getString(_keyBiometricToken);
    final account = prefs.getString(_keyBiometricAccount);
    final email = prefs.getString(_keyBiometricEmail);

    if (!isEnabled || token == null || token.isEmpty) {
      return null;
    }

    return {
      'accountNumber': account ?? '',
      'token': token,
      'email': email ?? '',
    };
  }

  /// مسح بيانات البصمة المحفوظة
  Future<void> clearBiometricCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBiometricAccount);
    await prefs.remove(_keyBiometricToken);
    await prefs.remove(_keyBiometricEmail);
    debugPrint('[Biometric] تم مسح اعتمادات البصمة 🗑️');
  }
}
