const mongoose = require('mongoose');

/**
 * نموذج العمليات المالية — يطابق ما يتوقعه تطبيق Flutter
 */
const transactionSchema = new mongoose.Schema(
  {
    // معرف العملية الفريد
    transactionId: {
      type: String,
      required: true,
      unique: true,
    },

    // المُرسِل
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    // المُستقبِل
    receiverId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    // المبلغ
    amount: {
      type: Number,
      required: true,
      min: 0.01,
    },

    // نوع العملية
    type: {
      type: String,
      enum: ['transfer', 'deposit', 'withdrawal', 'payment', 'topup'],
      default: 'transfer',
    },

    // ملاحظات
    note: { type: String, default: '' },
    description: { type: String, default: '' },
    category: { type: String, default: 'transfer' },

    // وقت العملية
    timestamp: {
      type: Date,
      default: Date.now,
    },

    // حالة العملية
    status: {
      type: String,
      enum: ['pending', 'completed', 'failed', 'cancelled'],
      default: 'completed',
    },
  },
  {
    timestamps: true,
  }
);

// ─── JSON transform ──────────────────────────────────────
transactionSchema.set('toJSON', {
  virtuals: true,
  transform: function (_doc, ret) {
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Transaction', transactionSchema);
