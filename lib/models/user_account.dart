import 'dart:convert';

/// نموذج حساب المستخدم الكامل
/// ملاحظة: جميع كلمات المرور والـ PIN تُخزَّن مشفرة عبر AuthService
class UserAccount {
  // ─── هوية المستخدم ───────────────────────────────────────────
  /// معرف المستخدم الفريد (12 رقم) — يُنشئه السيرفر
  final String id;

  /// رقم الحساب البنكي (8 أرقام)
  final String accountNumber;

  /// رقم البطاقة البنكية = نفس قيمة id (للتوافق)
  String get cardNumber => id;

  /// رقم البطاقة البنكية المنسق كأرقام بنكية أنيقة (مثال: 2490 1234 5678)
  String get formattedCardNumber {
    // فحص إذا كان المعرف عبارة عن Mongo ObjectId سداسي عشري من 24 حرف
    final isMongoHex = id.length == 24 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(id);
    final String cleanNum = (!isMongoHex && id.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(id))
        ? id
        : (accountNumber.isNotEmpty ? '2490$accountNumber' : '249000000000');

    if (cleanNum.length == 12) {
      return '${cleanNum.substring(0, 4)} ${cleanNum.substring(4, 8)} ${cleanNum.substring(8, 12)}';
    } else if (cleanNum.length == 16) {
      return '${cleanNum.substring(0, 4)} ${cleanNum.substring(4, 8)} ${cleanNum.substring(8, 12)} ${cleanNum.substring(12, 16)}';
    } else if (cleanNum.length == 8) {
      return '2490 ${cleanNum.substring(0, 4)} ${cleanNum.substring(4, 8)}';
    }
    return cleanNum;
  }

  // ─── بيانات الدخول ───────────────────────────────────────────
  /// البريد الإلكتروني للدخول
  final String email;

  /// كلمة مرور التطبيق (مشفرة SHA-256)
  final String loginPasswordHash;

  /// كلمة المرور الرئيسية (8+ حرف/رقم/رمز) مشفرة — للحساب البنكي
  final String passwordHash;

  /// رقم PIN المكون من 4 أرقام مشفر
  final String pinHash;

  /// هل قام المستخدم بإعداد رقم PIN خاص به
  final bool hasSetPin;

  // ─── البيانات الشخصية ─────────────────────────────────────────
  /// الاسم الأول
  final String firstName;

  /// الاسم الأوسط
  final String middleName;

  /// اسم العائلة
  final String lastName;

  /// الاسم الكامل الثلاثي
  String get fullName => '$firstName $middleName $lastName'.trim();

  /// تاريخ الميلاد
  final DateTime dateOfBirth;

  /// المسار المحلي لصورة إثبات الشخصية
  final String? idImagePath;

  // ─── بيانات الحساب البنكي ─────────────────────────────────────
  /// الرصيد الحالي
  final double balance;

  /// تاريخ إنشاء الحساب
  final DateTime creationDate;

  // ─── الأمان والجهاز ───────────────────────────────────────────
  /// معرف الجهاز المرتبط بالحساب (حساب واحد لكل جهاز)
  final String deviceId;

  /// حالة الحساب (نشط/موقوف)
  final bool isActive;

  // ─── نوع الحساب ───────────────────────────────────────────
  /// نوع الحساب (personal, merchant, company...)
  final String userType;

  // ─── Constructor ──────────────────────────────────────────────
  const UserAccount({
    required this.id,
    required this.accountNumber,
    required this.email,
    required this.loginPasswordHash,
    required this.passwordHash,
    required this.pinHash,
    this.hasSetPin = true,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.dateOfBirth,
    this.idImagePath,
    this.balance = 0.0,
    required this.creationDate,
    required this.deviceId,
    this.isActive = true,
    this.userType = 'personal',
  });

  // ─── Serialization ────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountNumber': accountNumber,
      'email': email,
      'loginPasswordHash': loginPasswordHash,
      'passwordHash': passwordHash,
      'pinHash': pinHash,
      'hasSetPin': hasSetPin,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'idImagePath': idImagePath,
      'balance': balance,
      'creationDate': creationDate.toIso8601String(),
      'deviceId': deviceId,
      'isActive': isActive ? 1 : 0,
      'userType': userType,
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'] as String? ?? '',
      accountNumber: map['accountNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      loginPasswordHash: map['loginPasswordHash'] as String? ?? '',
      passwordHash: map['passwordHash'] as String? ?? '',
      pinHash: map['pinHash'] as String? ?? '',
      hasSetPin: map['hasSetPin'] as bool? ?? false,
      firstName: map['firstName'] as String? ?? '',
      middleName: map['middleName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      dateOfBirth: DateTime.parse(
        map['dateOfBirth'] as String? ?? DateTime.now().toUtc().toIso8601String(),
      ),
      idImagePath: map['idImagePath'] as String?,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      creationDate: DateTime.parse(
        map['creationDate'] as String? ?? DateTime.now().toUtc().toIso8601String(),
      ),
      deviceId: map['deviceId'] as String? ?? '',
      isActive: (map['isActive'] as int? ?? 1) == 1,
      userType: map['userType'] as String? ?? 'personal',
    );
  }

  String toJson() => json.encode(toMap());
  factory UserAccount.fromJson(String source) =>
      UserAccount.fromMap(json.decode(source) as Map<String, dynamic>);

  /// نسخة معدّلة من الحساب مع تغيير بعض الحقول
  UserAccount copyWith({
    String? email,
    String? loginPasswordHash,
    String? passwordHash,
    String? pinHash,
    bool? hasSetPin,
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? dateOfBirth,
    String? idImagePath,
    double? balance,
    String? deviceId,
    bool? isActive,
    String? userType,
  }) {
    return UserAccount(
      id: id,
      accountNumber: accountNumber,
      email: email ?? this.email,
      loginPasswordHash: loginPasswordHash ?? this.loginPasswordHash,
      passwordHash: passwordHash ?? this.passwordHash,
      pinHash: pinHash ?? this.pinHash,
      hasSetPin: hasSetPin ?? this.hasSetPin,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      idImagePath: idImagePath ?? this.idImagePath,
      balance: balance ?? this.balance,
      creationDate: creationDate,
      deviceId: deviceId ?? this.deviceId,
      isActive: isActive ?? this.isActive,
      userType: userType ?? this.userType,
    );
  }
}
