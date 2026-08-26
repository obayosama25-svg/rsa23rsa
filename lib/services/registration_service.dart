import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// RegistrationService — توليد المعرفات وبيانات التسجيل
///
/// TODO: [BACKEND] عند ربط السيرفر:
/// • generateClientId() ← يُستبدل بـ id القادم من السيرفر
/// • generateBankAccountNumber() ← يُحذف، رقم البطاقة = id
/// ─────────────────────────────────────────────────────────────────────────────
class RegistrationService {
  static final Random _rng = Random.secure();

  /// توليد معرف مستخدم مؤقت (12 رقم)
  /// TODO: [BACKEND] السيرفر هو من يُنشئ هذا الـ ID ويتحقق من فرادته
  static String generateClientId() {
    return List.generate(12, (_) => _rng.nextInt(10).toString()).join();
  }

  /// توليد رقم حساب بنكي مؤقت (8 أرقام) — للعمل المحلي فقط
  /// TODO: [BACKEND] يُحذف عند الربط — رقم البطاقة = id
  static String generateBankAccountNumber() {
    return List.generate(8, (_) => _rng.nextInt(10).toString()).join();
  }

  /// توليد كلمة مرور قوية (8 محارف: حروف + أرقام + رموز)
  static String generateStrongPassword() {
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghjkmnpqrstuvwxyz';
    const digits = '23456789';
    const symbols = '!@#\$%^&*';
    const all = upper + lower + digits + symbols;

    final required = [
      upper[_rng.nextInt(upper.length)],
      lower[_rng.nextInt(lower.length)],
      digits[_rng.nextInt(digits.length)],
      symbols[_rng.nextInt(symbols.length)],
    ];
    final rest = List.generate(4, (_) => all[_rng.nextInt(all.length)]);
    final combined = [...required, ...rest]..shuffle(_rng);
    return combined.join();
  }

  /// التحقق من قوة كلمة المرور
  /// يجب: 8+ محارف، حرف كبير، حرف صغير، رقم، رمز
  static bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSymbol = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    return hasUpper && hasLower && hasDigit && hasSymbol;
  }

  /// التحقق من صحة الـ PIN (4 أرقام فقط)
  static bool isPinValid(String pin) {
    return pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin);
  }

  /// التحقق من صحة البريد الإلكتروني
  static bool isEmailValid(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email.trim());
  }

  /// جلب معرف الجهاز الفريد
  static Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown_device';

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        final name = webInfo.browserName.name;
        final hash = (webInfo.userAgent ?? 'web').hashCode.abs();
        deviceId = 'web_${name}_$hash';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'ios_device';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceId = windowsInfo.deviceId;
      }
    } catch (e) {
      debugPrint('[RegistrationService] فشل جلب معرف الجهاز: $e');
    }

    return deviceId;
  }
}
