const express = require('express');
const { v4: uuidv4 } = require('uuid');
const User = require('../models/User');
const Transaction = require('../models/Transaction');
const auth = require('../middleware/auth');

const router = express.Router();

// ═══════════════════════════════════════════════════════════
// POST /api/transactions/transfer — تحويل أموال بين حسابين
// ═══════════════════════════════════════════════════════════
router.post('/transfer', auth, async (req, res) => {
  try {
    const { receiverAccountNumber, amount, note } = req.body;
    const senderId = req.userId;

    // التحقق من البيانات
    if (!receiverAccountNumber || !amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'يرجى إدخال رقم الحساب والمبلغ بشكل صحيح',
      });
    }

    // جلب المُرسِل
    const sender = await User.findById(senderId);
    if (!sender) {
      return res.status(404).json({
        success: false,
        message: 'حساب المُرسِل غير موجود',
      });
    }

    // جلب المُستقبِل
    const receiver = await User.findOne({
      accountNumber: receiverAccountNumber,
      status: 'active',
    });
    if (!receiver) {
      return res.status(404).json({
        success: false,
        message: 'حساب المُستقبِل غير موجود أو غير مفعّل',
      });
    }

    // منع التحويل لنفس الحساب
    if (sender._id.toString() === receiver._id.toString()) {
      return res.status(400).json({
        success: false,
        message: 'لا يمكنك التحويل لنفس حسابك',
      });
    }

    // التحقق من الرصيد
    if (sender.balance < amount) {
      return res.status(400).json({
        success: false,
        message: 'الرصيد غير كافٍ لإتمام العملية',
      });
    }

    // تنفيذ التحويل
    sender.balance -= amount;
    receiver.balance += amount;

    await sender.save();
    await receiver.save();

    // تسجيل العملية
    const transaction = new Transaction({
      transactionId: uuidv4(),
      senderId: sender._id,
      receiverId: receiver._id,
      amount,
      type: 'transfer',
      note: note || '',
      description: `تحويل من ${sender.fullName} إلى ${receiver.fullName}`,
      category: 'transfer',
      timestamp: new Date(),
      status: 'completed',
    });

    await transaction.save();

    res.json({
      success: true,
      message: 'تم التحويل بنجاح',
      transaction: {
        transactionId: transaction.transactionId,
        amount: transaction.amount,
        receiverName: receiver.fullName,
        receiverAccount: receiver.accountNumber,
        senderBalance: sender.balance,
        timestamp: transaction.timestamp,
      },
    });
  } catch (err) {
    console.error('[TRANSFER] Error:', err);
    res.status(500).json({
      success: false,
      message: 'حدث خطأ في الخادم أثناء التحويل',
    });
  }
});

module.exports = router;
