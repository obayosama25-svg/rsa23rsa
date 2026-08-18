import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_account.dart';
import '../models/transaction.dart' as app_tx;

/// ─────────────────────────────────────────────────────────────────────────────
/// DatabaseService — قاعدة البيانات المحلية SQLite
///
/// هذه القاعدة مصممة للعمل محلياً ثم الارتباط بالسيرفر لاحقاً.
/// كل جدول مُعلَّق بـ TODO لمواضع ربط الـ API.
/// ─────────────────────────────────────────────────────────────────────────────
class DatabaseService {
  static const String _dbName = 'bank249.db';
  static const int _dbVersion = 1;

  // Singleton
  static DatabaseService? _instance;
  static Database? _database;

  DatabaseService._internal();

  factory DatabaseService() {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  // ─── أسماء الجداول ─────────────────────────────────────────────
  static const String tableUsers = 'users';
  static const String tableTransactions = 'transactions';
  static const String tableDeviceBindings = 'device_bindings';
  static const String tableSettings = 'settings';

  // ─── الحصول على قاعدة البيانات ─────────────────────────────────
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ─── إنشاء الجداول ─────────────────────────────────────────────
  Future<void> _onCreate(Database db, int version) async {
    // TODO: [BACKEND] عند الربط بالسيرفر، هذه الجداول ستُستبدل بـ API calls
    // وستُستخدم هنا فقط كـ cache محلي

    // جدول المستخدمين
    await db.execute('''
      CREATE TABLE $tableUsers (
        id              TEXT PRIMARY KEY,          -- 12 رقم، يُنشئه السيرفر
        accountNumber   TEXT NOT NULL,             -- 8 أرقام، رقم الحساب البنكي
        email           TEXT NOT NULL UNIQUE,      -- البريد الإلكتروني
        loginPasswordHash TEXT NOT NULL,           -- كلمة مرور التطبيق (SHA-256)
        passwordHash    TEXT NOT NULL,             -- كلمة المرور البنكية (SHA-256)
        pinHash         TEXT NOT NULL,             -- رقم APN للصراف (SHA-256)
        firstName       TEXT NOT NULL,             -- الاسم الأول
        middleName      TEXT NOT NULL DEFAULT '',  -- الاسم الأوسط
        lastName        TEXT NOT NULL,             -- اسم العائلة
        dateOfBirth     TEXT NOT NULL,             -- تاريخ الميلاد (ISO 8601)
        idImagePath     TEXT,                      -- مسار صورة إثبات الشخصية
        balance         REAL NOT NULL DEFAULT 0.0, -- الرصيد
        creationDate    TEXT NOT NULL,             -- تاريخ إنشاء الحساب
        deviceId        TEXT NOT NULL,             -- معرف الجهاز المرتبط
        isActive        INTEGER NOT NULL DEFAULT 1 -- 1=نشط، 0=موقوف
      )
    ''');

    // جدول ربط الأجهزة (حساب واحد لكل جهاز)
    await db.execute('''
      CREATE TABLE $tableDeviceBindings (
        deviceId        TEXT PRIMARY KEY,          -- معرف الجهاز
        userId          TEXT NOT NULL,             -- معرف الحساب المرتبط
        bindingDate     TEXT NOT NULL,             -- تاريخ الربط
        FOREIGN KEY (userId) REFERENCES $tableUsers(id)
      )
    ''');

    // جدول العمليات المالية
    await db.execute('''
      CREATE TABLE $tableTransactions (
        transactionId   TEXT PRIMARY KEY,          -- معرف العملية الفريد
        senderId        TEXT NOT NULL,             -- حساب المُرسِل
        receiverId      TEXT NOT NULL,             -- حساب المُستقبِل
        receiverName    TEXT NOT NULL,             -- اسم المستفيد
        amount          REAL NOT NULL,             -- المبلغ
        type            TEXT NOT NULL,             -- credit / debit
        note            TEXT,                      -- ملاحظات
        timestamp       TEXT NOT NULL,             -- وقت العملية
        status          TEXT NOT NULL DEFAULT 'completed', -- الحالة
        FOREIGN KEY (senderId) REFERENCES $tableUsers(id)
      )
    ''');

    // جدول إعدادات التطبيق
    await db.execute('''
      CREATE TABLE $tableSettings (
        key             TEXT PRIMARY KEY,
        value           TEXT NOT NULL,
        updatedAt       TEXT NOT NULL
      )
    ''');

    debugPrint('[DB] تم إنشاء قاعدة البيانات bank249.db بنجاح ✅');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // TODO: [MIGRATION] إضافة منطق الترقية عند تغيير الإصدار
    debugPrint('[DB] ترقية قاعدة البيانات من $oldVersion إلى $newVersion');
  }

  // ═══════════════════════════════════════════════════════════════
  // CRUD — جدول المستخدمين
  // ═══════════════════════════════════════════════════════════════

  /// إدراج مستخدم جديد
  /// TODO: [BACKEND] استبدل هذا بـ POST /api/users عند ربط السيرفر
  Future<void> insertUser(UserAccount user) async {
    final db = await database;
    await db.insert(
      tableUsers,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // ربط الجهاز تلقائياً عند إنشاء الحساب
    await _bindDevice(user.deviceId, user.id);
    debugPrint('[DB] تم إدراج المستخدم: ${user.id} ✅');
  }

  /// جلب المستخدم بالمعرف
  /// TODO: [BACKEND] استبدل بـ GET /api/users/:id
  Future<UserAccount?> getUserById(String id) async {
    final db = await database;
    final maps = await db.query(
      tableUsers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserAccount.fromMap(maps.first);
  }

  /// جلب المستخدم بالبريد الإلكتروني
  /// TODO: [BACKEND] استبدل بـ GET /api/users?email=:email
  Future<UserAccount?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      tableUsers,
      where: 'email = ?',
      whereArgs: [email.toLowerCase().trim()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserAccount.fromMap(maps.first);
  }

  /// جلب المستخدم المرتبط بالجهاز الحالي
  /// TODO: [BACKEND] استبدل بـ GET /api/device/:deviceId/user
  Future<UserAccount?> getUserByDeviceId(String deviceId) async {
    final db = await database;
    final bindings = await db.query(
      tableDeviceBindings,
      where: 'deviceId = ?',
      whereArgs: [deviceId],
      limit: 1,
    );
    if (bindings.isEmpty) return null;
    final userId = bindings.first['userId'] as String;
    return getUserById(userId);
  }

  /// تحديث بيانات المستخدم
  /// TODO: [BACKEND] استبدل بـ PATCH /api/users/:id
  Future<void> updateUser(UserAccount user) async {
    final db = await database;
    await db.update(
      tableUsers,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    debugPrint('[DB] تم تحديث المستخدم: ${user.id} ✅');
  }

  /// تحديث رصيد المستخدم فقط
  Future<void> updateBalance(String userId, double newBalance) async {
    final db = await database;
    await db.update(
      tableUsers,
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// تحديث رقم APN (PIN) للمستخدم
  /// TODO: [BACKEND] استبدل بـ PATCH /api/users/:id/pin
  Future<void> updatePin(String userId, String newPinHash) async {
    final db = await database;
    await db.update(
      tableUsers,
      {'pinHash': newPinHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
    debugPrint('[DB] تم تحديث الـ PIN للمستخدم: $userId ✅');
  }

  /// تحديث كلمة مرور التطبيق
  Future<void> updateLoginPassword(
      String userId, String newLoginPasswordHash) async {
    final db = await database;
    await db.update(
      tableUsers,
      {'loginPasswordHash': newLoginPasswordHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// التحقق من أن الجهاز غير مرتبط بحساب آخر
  Future<bool> isDeviceFree(String deviceId) async {
    final db = await database;
    final res = await db.query(
      tableDeviceBindings,
      where: 'deviceId = ?',
      whereArgs: [deviceId],
      limit: 1,
    );
    return res.isEmpty;
  }

  // ═══════════════════════════════════════════════════════════════
  // CRUD — جدول العمليات المالية
  // ═══════════════════════════════════════════════════════════════

  /// إدراج عملية مالية
  /// TODO: [BACKEND] استبدل بـ POST /api/transactions
  Future<void> insertTransaction(app_tx.Transaction tx) async {
    final db = await database;
    await db.insert(
      tableTransactions,
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    debugPrint('[DB] تم تسجيل العملية: ${tx.transactionId} ✅');
  }

  /// جلب كل عمليات حساب معين (مرسلة ومستقبلة)
  /// TODO: [BACKEND] استبدل بـ GET /api/users/:id/transactions
  Future<List<app_tx.Transaction>> getUserTransactions(String userId) async {
    final db = await database;
    final maps = await db.query(
      tableTransactions,
      where: 'senderId = ? OR receiverId = ?',
      whereArgs: [userId, userId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => app_tx.Transaction.fromMap(m)).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // ربط الجهاز
  // ═══════════════════════════════════════════════════════════════

  Future<void> _bindDevice(String deviceId, String userId) async {
    final db = await database;
    await db.insert(
      tableDeviceBindings,
      {
        'deviceId': deviceId,
        'userId': userId,
        'bindingDate': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    debugPrint('[DB] تم ربط الجهاز $deviceId بالحساب $userId ✅');
  }

  // ═══════════════════════════════════════════════════════════════
  // الإعدادات العامة
  // ═══════════════════════════════════════════════════════════════

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      tableSettings,
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final res = await db.query(
      tableSettings,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first['value'] as String?;
  }

  // ═══════════════════════════════════════════════════════════════
  // إدارة قاعدة البيانات
  // ═══════════════════════════════════════════════════════════════

  /// حذف كل البيانات (للتطوير فقط)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(tableTransactions);
    await db.delete(tableDeviceBindings);
    await db.delete(tableSettings);
    await db.delete(tableUsers);
    debugPrint('[DB] تم مسح كل البيانات ⚠️');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
