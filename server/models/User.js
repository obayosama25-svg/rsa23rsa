const mongoose = require('mongoose');

/**
 * نموذج المستخدم — يطابق ما يتوقعه تطبيق Flutter
 */
const userSchema = new mongoose.Schema(
  {
    // رقم الحساب البنكي (8 أرقام، يُولَّد تلقائياً)
    accountNumber: {
      type: String,
      unique: true,
      required: true,
    },

    // نوع الحساب
    category: {
      type: String,
      enum: ['individual', 'merchant', 'company'],
      default: 'individual',
    },

    // بيانات الدخول
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: true,
    },

    // البيانات الشخصية
    firstName: { type: String, required: true, trim: true },
    middleName: { type: String, default: '', trim: true },
    lastName: { type: String, required: true, trim: true },
    dateOfBirth: { type: Date },

    // صور الوثائق
    idPhotoPath: { type: String, default: '' },
    idImagePath: { type: String, default: '' },
    personalPhotoPath: { type: String, default: '' },
    signaturePhotoPath: { type: String, default: '' },
    logoPhotoPath: { type: String, default: '' },

    // بيانات الحساب
    balance: { type: Number, default: 0.0 },
    deviceId: { type: String, default: '' },
    isActive: { type: Boolean, default: true },
    biometricEnabled: { type: Boolean, default: false },
    biometricDeviceId: { type: String, default: null },

    // حالة التفعيل
    status: {
      type: String,
      enum: ['pending_otp', 'pending_approval', 'active', 'suspended'],
      default: 'pending_otp',
    },

    // OTP للتحقق
    otpCode: { type: String, default: null },
    otpExpiry: { type: Date, default: null },

    // أسئلة الأمان لاستعادة الحساب
    securityQuestions: [
      {
        question: String,
        answer: String,
      },
    ],

    // نوع المستخدم
    userType: {
      type: String,
      default: 'personal',
    },
  },
  {
    timestamps: true,
  }
);

// ─── Static: توليد رقم حساب فريد ─────────────────────────
userSchema.statics.generateAccountNumber = async function () {
  let accountNumber;
  let exists = true;
  while (exists) {
    accountNumber = Array.from({ length: 8 }, () =>
      Math.floor(Math.random() * 10)
    ).join('');
    exists = await this.findOne({ accountNumber });
  }
  return accountNumber;
};

// ─── Virtual: الاسم الكامل ────────────────────────────────
userSchema.virtual('fullName').get(function () {
  return `${this.firstName} ${this.middleName} ${this.lastName}`.trim();
});

// ─── JSON transform: إخفاء كلمة المرور ───────────────────
userSchema.set('toJSON', {
  virtuals: true,
  transform: function (_doc, ret) {
    delete ret.password;
    delete ret.otpCode;
    delete ret.otpExpiry;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('User', userSchema);
