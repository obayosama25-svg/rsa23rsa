const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const nodemailer = require('nodemailer');
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const auth = require('../middleware/auth');

const router = express.Router();

// ─── إعداد Multer لرفع الصور ──────────────────────────────
const fs = require('fs');
const uploadsDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadsDir),
  filename: (_req, file, cb) => {
    const uniqueName = `${Date.now()}-${Math.round(Math.random() * 1e9)}${path.extname(file.originalname || '.jpg')}`;
    cb(null, uniqueName);
  },
});
const upload = multer({ storage, limits: { fileSize: 15 * 1024 * 1024 } }); // 15MB max

// ─── إعداد Nodemailer لإرسال OTP ─────────────────────────
function getMailTransporter() {
  if (process.env.SMTP_HOST === 'smtp.gmail.com' || (process.env.SMTP_USER && process.env.SMTP_USER.includes('@gmail.com'))) {
    return nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });
  }
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.hostinger.com',
    port: parseInt(process.env.SMTP_PORT || '465'),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });
}

// ─── توليد OTP عشوائي (6 أرقام) ──────────────────────────
function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// ─── إرسال OTP بالبريد ────────────────────────────────────
async function sendOtpEmail(email, otpCode) {
  try {
    const transporter = getMailTransporter();
    await transporter.sendMail({
      from: process.env.SMTP_FROM || '"SudaCard" <noreply@sudacard.com>',
      to: email,
      subject: 'رمز التحقق — SudaCard',
      html: `
        <div dir="rtl" style="font-family: Arial, sans-serif; padding: 20px;">
          <h2 style="color: #0D1B2A;">رمز التحقق الخاص بك</h2>
          <p>رمز التحقق هو:</p>
          <h1 style="color: #00C853; letter-spacing: 8px; font-size: 36px;">${otpCode}</h1>
          <p>صالح لمدة 10 دقائق فقط.</p>
          <hr/>
          <p style="color: #888;">SudaCard — بطاقتك الذكية</p>
        </div>
      `,
    });
    console.log(`[MAIL] OTP sent to ${email}`);
    return true;
  } catch (err) {
    console.error(`[MAIL] Failed to send OTP: ${err.message}`);
    // في حالة فشل الإرسال، نطبع الـ OTP في الـ logs للتطوير
    console.log(`[DEV] OTP for ${email}: ${otpCode}`);
    return false;
  }
}

// ═══════════════════════════════════════════════════════════
// POST /api/users/register — تسجيل حساب جديد
// ═══════════════════════════════════════════════════════════
router.post(
  '/register',
  upload.fields([
    { name: 'idPhoto', maxCount: 1 },
    { name: 'personalPhoto', maxCount: 1 },
    { name: 'signaturePhoto', maxCount: 1 },
  ]),
  async (req, res) => {
    try {
      const { category, email, password, deviceId, firstName, middleName, lastName, dateOfBirth } = req.body;

      // التحقق من البيانات المطلوبة
      if (!email || !password || !firstName || !lastName) {
        return res.status(400).json({
          success: false,
          message: 'يرجى تعبئة جميع الحقول المطلوبة',
        });
      }

      // التحقق من عدم وجود حساب بنفس البريد
      const existingUser = await User.findOne({ email: email.toLowerCase().trim() });
      if (existingUser) {
        return res.status(409).json({
          success: false,
          message: 'هذا البريد الإلكتروني مسجل مسبقاً',
        });
      }

      // التحقق من عدم وجود حساب بنفس الجهاز
      if (deviceId) {
        const existingDevice = await User.findOne({ deviceId, status: { $ne: 'suspended' } });
        if (existingDevice) {
          return res.status(409).json({
            success: false,
            message: 'هذا الجهاز مرتبط بحساب آخر',
          });
        }
      }

      // تشفير كلمة المرور
      const hashedPassword = await bcrypt.hash(password, 12);

      // توليد رقم الحساب
      const accountNumber = await User.generateAccountNumber();

      // توليد OTP
      const otpCode = generateOtp();
      const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 دقائق

      // مسارات الصور
      const files = req.files || {};
      const idPhotoPath = files.idPhoto ? `/uploads/${files.idPhoto[0].filename}` : '';
      const personalPhotoPath = files.personalPhoto ? `/uploads/${files.personalPhoto[0].filename}` : '';
      const signaturePhotoPath = files.signaturePhoto ? `/uploads/${files.signaturePhoto[0].filename}` : '';

      // إنشاء المستخدم
      const user = new User({
        accountNumber,
        category: category || 'individual',
        email: email.toLowerCase().trim(),
        password: hashedPassword,
        deviceId: deviceId || '',
        firstName: firstName.trim(),
        middleName: (middleName || '').trim(),
        lastName: lastName.trim(),
        dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null,
        idPhotoPath,
        idImagePath: idPhotoPath,
        personalPhotoPath,
        signaturePhotoPath,
        otpCode,
        otpExpiry,
        status: 'pending_otp',
        hasSetPin: false,
        isLocked: false,
        failedLoginAttempts: 0,
        pinHash: '',
        pin: '',
      });

      await user.save();

      // إرسال OTP بالبريد
      await sendOtpEmail(email, otpCode);

      res.status(201).json({
        success: true,
        message: 'تم التسجيل بنجاح. يرجى التحقق من بريدك الإلكتروني لإدخال رمز التأكيد.',
        data: {
          userId: user._id.toString(),
          accountNumber: user.accountNumber,
        },
      });
    } catch (err) {
      console.error('[REGISTER] Error:', err);
      res.status(500).json({
        success: false,
        message: 'حدث خطأ في الخادم أثناء التسجيل',
      });
    }
  }
);

// ═══════════════════════════════════════════════════════════
// POST /api/users/verify-otp — تأكيد رمز التحقق
// ═══════════════════════════════════════════════════════════
router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otpCode } = req.body;

    if (!email || !otpCode) {
      return res.status(400).json({
        success: false,
        message: 'يرجى إدخال البريد ورمز التحقق',
      });
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'الحساب غير موجود',
      });
    }

    // التحقق من الرمز
    if (user.otpCode !== otpCode) {
      return res.status(400).json({
        success: false,
        message: 'رمز التحقق غير صحيح',
      });
    }

    // التحقق من الصلاحية
    if (user.otpExpiry && new Date() > user.otpExpiry) {
      return res.status(400).json({
        success: false,
        message: 'انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد.',
      });
    }

    // تفعيل الحساب
    user.status = 'active';
    user.otpCode = null;
    user.otpExpiry = null;
    await user.save();

    res.json({
      success: true,
      message: 'تم تأكيد الحساب بنجاح',
    });
  } catch (err) {
    console.error('[VERIFY-OTP] Error:', err);
    res.status(500).json({
      success: false,
      message: 'حدث خطأ في الخادم',
    });
  }
});

// ═══════════════════════════════════════════════════════════
// POST /api/users/resend-otp — إعادة إرسال رمز التحقق
// ═══════════════════════════════════════════════════════════
router.post('/resend-otp', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email: email.toLowerCase().trim() });
    if (!user) {
      return res.status(404).json({ success: false, message: 'الحساب غير موجود' });
    }

    const otpCode = generateOtp();
    user.otpCode = otpCode;
    user.otpExpiry = new Date(Date.now() + 10 * 60 * 1000);
    await user.save();

    await sendOtpEmail(email, otpCode);

    res.json({ success: true, message: 'تم إرسال رمز تحقق جديد' });
  } catch (err) {
    console.error('[RESEND-OTP] Error:', err);
    res.status(500).json({ success: false, message: 'حدث خطأ في الخادم' });
  }
});

// ═══════════════════════════════════════════════════════════
// POST /api/users/login — تسجيل الدخول
// ═══════════════════════════════════════════════════════════
router.post('/login', async (req, res) => {
  try {
    const { email, password, deviceId } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'يرجى إدخال البريد وكلمة المرور',
      });
    }

    // البحث عن المستخدم (بالبريد أو رقم الحساب)
    const user = await User.findOne({
      $or: [
        { email: email.toLowerCase().trim() },
        { accountNumber: email.trim() },
      ]
    }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      });
    }

    // التحقق من قفل الحساب
    if (user.isLocked || user.status === 'suspended') {
      return res.status(403).json({
        success: false,
        status: 'account_locked',
        message: 'تم إغلاق الحساب مؤقتاً لدواعي أمنية بسبب إدخال كلمة مرور خاطئة. يرجى استعادة الحساب.',
      });
    }

    // التحقق من حالة الحساب
    if (user.status === 'pending_otp') {
      return res.status(403).json({
        success: false,
        message: 'يرجى تأكيد حسابك أولاً عبر رمز التحقق المرسل لبريدك',
        status: 'pending_otp',
      });
    }

    // التحقق من كلمة المرور
    let isMatch = false;
    if (user.password && user.password.startsWith('$2')) {
      isMatch = await bcrypt.compare(password, user.password);
    } else if (user.password) {
      const crypto = require('crypto');
      const sha256 = (str) => crypto.createHash('sha256').update(str).digest('hex');
      isMatch = (user.password === password || user.password === sha256(password));
    }

    if (!isMatch) {
      user.failedLoginAttempts = (user.failedLoginAttempts || 0) + 1;
      if (user.failedLoginAttempts >= 3) {
        user.isLocked = true;
        await user.save();
        return res.status(403).json({
          success: false,
          status: 'account_locked',
          message: 'تم إغلاق الحساب بسبب إدخال كلمة مرور خاطئة 3 مرات متتالية. يرجى استعادة الحساب.',
        });
      }
      await user.save();
      const remaining = 3 - user.failedLoginAttempts;
      return res.status(401).json({
        success: false,
        message: `كلمة المرور غير صحيحة. يتبقى لك ${remaining} ${remaining === 1 ? 'محاولة واحدة' : 'محاولات'} قبل إغلاق الحساب.`,
      });
    }

    // إعادة تعيين محاولات الدخول الخاطئة عند النجاح
    user.failedLoginAttempts = 0;
    user.isLocked = false;

    // تحديث معرف الجهاز
    if (deviceId) {
      user.deviceId = deviceId;
      await user.save();
    }

    // إنشاء JWT token
    const token = jwt.sign(
      { userId: user._id.toString() },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      message: 'تم الدخول بنجاح',
      token,
      user: {
        id: user._id.toString(),
        accountNumber: user.accountNumber,
        email: user.email,
        firstName: user.firstName,
        middleName: user.middleName,
        lastName: user.lastName,
        balance: user.balance,
        isActive: user.isActive,
        status: user.status,
        userType: user.userType,
      },
    });
  } catch (err) {
    console.error('[LOGIN] Error:', err);
    res.status(500).json({
      success: false,
      message: 'حدث خطأ في الخادم',
    });
  }
});

// ═══════════════════════════════════════════════════════════
// GET /api/users/me — جلب بيانات المستخدم الحالي (محمي)
// ═══════════════════════════════════════════════════════════
router.get('/me', auth, async (req, res) => {
  try {
    const mongoose = require('mongoose');
    let user = null;
    if (mongoose.Types.ObjectId.isValid(req.userId)) {
      user = await User.findById(req.userId);
    }
    if (!user) {
      user = await User.findOne({
        $or: [
          { accountNumber: req.userId },
          { email: req.userId },
          { userId: req.userId }
        ]
      });
    }
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'الحساب غير موجود',
      });
    }

    res.json({
      success: true,
      user: {
        _id: user._id.toString(),
        userId: user._id.toString(),
        accountNumber: user.accountNumber,
        email: user.email,
        firstName: user.firstName,
        middleName: user.middleName,
        lastName: user.lastName,
        balance: user.balance,
        isActive: user.isActive,
        status: user.status,
        userType: user.userType,
        dateOfBirth: user.dateOfBirth,
        createdAt: user.createdAt,
      },
    });
  } catch (err) {
    console.error('[ME] Error:', err);
    res.status(500).json({
      success: false,
      message: 'حدث خطأ في الخادم',
    });
  }
});

// ═══════════════════════════════════════════════════════════
// GET /api/users/me/transactions — جلب عمليات المستخدم (محمي)
// ═══════════════════════════════════════════════════════════
router.get('/me/transactions', auth, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 20;
    const userId = req.userId;

    const transactions = await Transaction.find({
      $or: [{ senderId: userId }, { receiverId: userId }],
    })
      .sort({ timestamp: -1 })
      .limit(limit)
      .populate('senderId', 'firstName lastName accountNumber _id')
      .populate('receiverId', 'firstName lastName accountNumber _id');

    res.json({
      success: true,
      transactions,
    });
  } catch (err) {
    console.error('[TRANSACTIONS] Error:', err);
    res.status(500).json({
      success: false,
      message: 'حدث خطأ في جلب العمليات',
    });
  }
});

// ═══════════════════════════════════════════════════════════
// GET /api/users/search/:accountNumber — البحث عن حساب
// ═══════════════════════════════════════════════════════════
router.get('/search/:accountNumber', auth, async (req, res) => {
  try {
    const user = await User.findOne({
      accountNumber: req.params.accountNumber,
      status: 'active',
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'الحساب غير موجود',
      });
    }

    res.json({
      success: true,
      user: {
        id: user._id.toString(),
        accountNumber: user.accountNumber,
        firstName: user.firstName,
        lastName: user.lastName,
        fullName: user.fullName,
      },
    });
  } catch (err) {
    console.error('[SEARCH] Error:', err);
    res.status(500).json({
      success: false,
      message: 'حدث خطأ في البحث',
    });
  }
});

// ═══════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════
// RECOVERY ROUTES (استعادة الحساب المغلق)
// ═══════════════════════════════════════════════════════════

// 1. جلب أسئلة الأمان للحساب
router.get(['/recover/questions/:accountNumber', '/recovery/questions/:accountNumber'], async (req, res) => {
  try {
    const accParam = (req.params.accountNumber || '').trim();
    const user = await User.findOne({
      $or: [
        { accountNumber: accParam },
        { email: accParam.toLowerCase() },
      ]
    });
    if (!user) {
      return res.status(404).json({ success: false, message: 'الحساب غير موجود' });
    }
    if (!user.securityQuestions || user.securityQuestions.length === 0) {
      return res.status(400).json({ success: false, message: 'لم يتم إعداد أسئلة أمان لهذا الحساب مسبقاً.' });
    }
    const questions = user.securityQuestions.map((q, i) => ({
      index: i,
      question: q.question,
    }));
    const hasSetPin = Boolean(user.hasSetPin && user.pinHash && user.pinHash.trim().length > 0);
    res.json({ success: true, questions, hasSetPin });
  } catch (err) {
    console.error('[RECOVERY-GET-Q] Error:', err);
    res.status(500).json({ success: false, message: 'حدث خطأ في الخادم' });
  }
});

// 2. التحقق من إجابات أسئلة الأمان
router.post(['/recover/verify-questions', '/recovery/verify-questions', '/recovery/verify'], async (req, res) => {
  try {
    const { accountNumber, answers } = req.body;
    const user = await User.findOne({
      $or: [
        { accountNumber: (accountNumber || '').trim() },
        { email: (accountNumber || '').toLowerCase().trim() }
      ]
    });

    if (!user || !user.securityQuestions || user.securityQuestions.length === 0) {
      return res.status(404).json({ success: false, message: 'الحساب أو أسئلة الأمان غير موجودة' });
    }

    const crypto = require('crypto');
    const sha256 = (str) => crypto.createHash('sha256').update(str).digest('hex');

    let correct = 0;
    for (const ans of (answers || [])) {
      const userQ = user.securityQuestions.find(sq => sq.question === ans.question);
      if (userQ) {
        const inputAnswer = (ans.answer || '').trim().toLowerCase();
        const storedAnswer = (userQ.answer || '').trim().toLowerCase();
        const storedHash = (userQ.answerHash || '').trim();
        if (inputAnswer === storedAnswer || (storedHash && sha256(inputAnswer) === storedHash)) {
          correct++;
        }
      }
    }

    if (correct >= 1 && correct >= Math.min(2, user.securityQuestions.length)) {
      return res.json({ success: true, message: 'الإجابات صحيحة' });
    } else {
      return res.status(400).json({ success: false, message: 'إجابات أسئلة الأمان غير صحيحة' });
    }
  } catch (err) {
    console.error('[RECOVER-VERIFY-Q] Error:', err);
    res.status(500).json({ success: false, message: 'حدث خطأ في الخادم' });
  }
});

// 3. التحقق من البريد والـ PIN وإرسال OTP
router.post(['/recover/verify-pin', '/recovery/verify-pin'], async (req, res) => {
  try {
    const { accountNumber, email, pin } = req.body;
    const user = await User.findOne({
      $or: [
        { accountNumber: (accountNumber || '').trim() },
        { email: (accountNumber || '').toLowerCase().trim() }
      ]
    });

    if (!user) {
      return res.status(404).json({ success: false, message: 'الحساب غير موجود' });
    }

    const inputEmail = (email || '').toLowerCase().trim();
    const userEmail = (user.email || '').toLowerCase().trim();
    if (inputEmail !== userEmail) {
      return res.status(400).json({ success: false, message: 'البريد الإلكتروني غير متطابق مع بيانات الحساب' });
    }

    // إذا كان الحساب يمتلك PIN وتم تفعيله نتحقق منه
    if (user.hasSetPin && user.pinHash && user.pinHash.trim().length > 0) {
      const crypto = require('crypto');
      const sha256 = (str) => crypto.createHash('sha256').update(str).digest('hex');
      const inputPin = (pin || '').trim();
      if (user.pinHash !== sha256(inputPin) && user.pin !== inputPin) {
        return res.status(400).json({ success: false, message: 'رمز الـ PIN غير صحيح' });
      }
    }

    // توليد OTP
    const otpCode = generateOtp();
    user.otpCode = otpCode;
    user.otpExpiry = new Date(Date.now() + 10 * 60 * 1000);
    await user.save();

    await sendOtpEmail(user.email, otpCode);

    res.json({
      success: true,
      message: 'تم إرسال رمز التحقق إلى بريدك الإلكتروني بنجاح',
      email: user.email.replace(/(.{2})(.*)(@.*)/, '$1***$3')
    });
  } catch (err) {
    console.error('[RECOVER-VERIFY-PIN] Error:', err);
    res.status(500).json({ success: false, message: 'حدث خطأ في الخادم' });
  }
});

// 4. إعادة تعيين كلمة المرور وإلغاء القفل
router.post(['/recover/reset-password', '/recovery/reset-password', '/recovery/reset'], async (req, res) => {
  try {
    const { accountNumber, email, otpCode, newPassword } = req.body;
    const user = await User.findOne({
      $or: [
        { accountNumber: (accountNumber || '').trim() },
        { email: (email || accountNumber || '').toLowerCase().trim() }
      ]
    });

    if (!user) {
      return res.status(404).json({ success: false, message: 'الحساب غير موجود' });
    }

    if (!user.otpCode || user.otpCode !== (otpCode || '').trim()) {
      return res.status(400).json({ success: false, message: 'رمز التحقق (OTP) غير صحيح' });
    }

    if (user.otpExpiry && new Date() > user.otpExpiry) {
      return res.status(400).json({ success: false, message: 'انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد.' });
    }

    // تعيين كلمة المرور الجديدة وإلغاء القفل
    user.password = await bcrypt.hash(newPassword, 12);
    const crypto = require('crypto');
    user.loginPasswordHash = crypto.createHash('sha256').update(newPassword).digest('hex');
    user.otpCode = null;
    user.otpExpiry = null;
    user.isLocked = false;
    user.failedLoginAttempts = 0;
    if (user.status === 'suspended') user.status = 'active';
    await user.save();

    res.json({
      success: true,
      message: 'تم استعادة الحساب وإلغاء القفل وتعيين كلمة المرور بنجاح 🎉'
    });
  } catch (err) {
    console.error('[RECOVER-RESET-PASS] Error:', err);
    res.status(500).json({ success: false, message: 'حدث خطأ في الخادم' });
  }
});

// ═══════════════════════════════════════════════════════════
// PUT /api/users/security/biometric — تحديث حالة الدخول بالبصمة
// ═══════════════════════════════════════════════════════════
router.put('/security/biometric', auth, async (req, res) => {
  try {
    const { enabled, deviceId } = req.body;
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'المستخدم غير موجود' });
    }

    user.biometricEnabled = Boolean(enabled);
    user.biometricDeviceId = enabled ? (deviceId || user.deviceId) : null;
    await user.save();

    res.json({
      success: true,
      message: enabled ? 'تم تفعيل الدخول بالبصمة على السيرفر' : 'تم تعطيل الدخول بالبصمة على السيرفر',
      biometricEnabled: user.biometricEnabled,
    });
  } catch (err) {
    console.error('[BIOMETRIC] Error:', err);
    res.status(500).json({ success: false, message: 'حدث خطأ في الخادم' });
  }
});

// ═══════════════════════════════════════════════════════════
// GET /api/users/status/:identifier — فحص حالة موافقة الحساب
// ═══════════════════════════════════════════════════════════
router.get('/status/:identifier', async (req, res) => {
  try {
    const idParam = (req.params.identifier || '').toLowerCase().trim();
    const user = await User.findOne({
      $or: [
        { email: idParam },
        { accountNumber: idParam },
      ]
    });
    if (!user) {
      return res.status(404).json({ success: false, message: 'الحساب غير موجود' });
    }

    res.json({
      success: true,
      status: user.status,
      isActive: user.isActive,
      isApproved: user.status === 'approved' || (user.status === 'active' && user.isActive),
    });
  } catch (err) {
    console.error('[STATUS] Error:', err);
    res.status(500).json({ success: false, message: 'حدث خطأ في الخادم' });
  }
});

module.exports = router;
