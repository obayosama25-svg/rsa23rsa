const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth');
const Invoice = require('../models/Invoice');
const User = require('../models/User');

// إنشاء فاتورة جديدة
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { amount, description } = req.body;
    
    if (!amount || amount <= 0) {
      return res.status(400).json({ success: false, message: 'مبلغ غير صالح' });
    }

    // جلب بيانات المستخدم الذي يقوم بإنشاء الفاتورة
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'المستخدم غير موجود' });
    }

    // إنشاء رقم فاتورة فريد
    const invoiceId = 'INV-' + Date.now();
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 5); // صالحة لمدة 5 ساعات فقط

    const newInvoice = new Invoice({
      invoiceId,
      creatorAccountNumber: user.accountNumber,
      creatorName: `${user.firstName} ${user.middleName || ''} ${user.lastName}`.replace(/\s+/g, ' ').trim(),
      amount,
      description: description || '',
      status: 'pending',
      expiresAt
    });

    await newInvoice.save();

    res.json({
      success: true,
      invoice: {
        invoiceId: newInvoice.invoiceId,
        creatorAccountNumber: newInvoice.creatorAccountNumber,
        creatorName: newInvoice.creatorName,
        amount: newInvoice.amount,
        description: newInvoice.description,
        status: newInvoice.status,
        createdAt: newInvoice.createdAt.toISOString(),
        expiresAt: newInvoice.expiresAt.toISOString()
      }
    });

  } catch (error) {
    console.error('Create Invoice Error:', error);
    res.status(500).json({ success: false, message: 'خطأ في السيرفر أثناء إنشاء الفاتورة' });
  }
});

// جلب تفاصيل فاتورة والتحقق من صلاحيتها (5 ساعات)
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const invoice = await Invoice.findOne({ invoiceId: req.params.id });
    if (!invoice) {
      return res.status(404).json({ success: false, message: 'الفاتورة غير موجودة' });
    }

    if (new Date() > new Date(invoice.expiresAt)) {
      return res.status(410).json({
        success: false,
        message: 'انتهت صلاحية رابط المطالبة (صالح لمدة 5 ساعات فقط). يرجى طلب رابط جديد.',
        isExpired: true
      });
    }

    res.json({
      success: true,
      invoice: {
        invoiceId: invoice.invoiceId,
        creatorAccountNumber: invoice.creatorAccountNumber,
        creatorName: invoice.creatorName,
        amount: invoice.amount,
        description: invoice.description,
        status: invoice.status,
        createdAt: invoice.createdAt.toISOString(),
        expiresAt: invoice.expiresAt.toISOString()
      }
    });
  } catch (error) {
    console.error('Get Invoice Error:', error);
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
});

// سداد الفاتورة / المطالبة
router.post('/:id/pay', authMiddleware, async (req, res) => {
  try {
    const invoice = await Invoice.findOne({ invoiceId: req.params.id });
    if (!invoice) {
      return res.status(404).json({ success: false, message: 'الفاتورة غير موجودة' });
    }

    if (invoice.status === 'paid') {
      return res.status(400).json({ success: false, message: 'تم سداد هذه المطالبة مسبقاً' });
    }

    if (new Date() > new Date(invoice.expiresAt)) {
      return res.status(410).json({
        success: false,
        message: 'انتهت صلاحية رابط المطالبة (صالح لمدة 5 ساعات فقط). يرجى إنشاء مطالبة جديدة.',
        isExpired: true
      });
    }

    const payer = await User.findById(req.userId);
    if (!payer) {
      return res.status(404).json({ success: false, message: 'حساب الدافع غير موجود' });
    }

    if (payer.accountNumber === invoice.creatorAccountNumber) {
      return res.status(400).json({ success: false, message: 'لا يمكنك سداد مطالبة خاصة بك لنفسك' });
    }

    if (payer.balance < invoice.amount) {
      return res.status(400).json({ success: false, message: 'رصيدك غير كافٍ لسداد هذه المطالبة' });
    }

    const receiver = await User.findOne({ accountNumber: invoice.creatorAccountNumber });
    if (!receiver) {
      return res.status(404).json({ success: false, message: 'حساب المستفيد غير موجود' });
    }

    // خصم وإيداع
    payer.balance -= invoice.amount;
    receiver.balance += invoice.amount;
    invoice.status = 'paid';

    await payer.save();
    await receiver.save();
    await invoice.save();

    // إنشاء المعاملة
    const Transaction = require('../models/Transaction');
    const transactionId = 'TXN-' + Date.now();
    await Transaction.create({
      transactionId,
      senderId: payer._id,
      receiverId: receiver._id,
      amount: invoice.amount,
      type: 'payment',
      category: 'transfer',
      note: invoice.description || `سداد مطالبة ${invoice.invoiceId}`,
      description: `سداد مطالبة ${invoice.invoiceId}`,
      timestamp: new Date()
    });

    res.json({
      success: true,
      message: `تم سداد المطالبة بمبلغ ${invoice.amount.toLocaleString()} SDG بنجاح!`,
      newBalance: payer.balance,
      transactionId
    });

  } catch (error) {
    console.error('Pay Invoice Error:', error);
    res.status(500).json({ success: false, message: 'خطأ في السيرفر أثناء سداد المطالبة' });
  }
});

module.exports = router;
