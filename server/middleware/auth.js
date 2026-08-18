const jwt = require('jsonwebtoken');

/**
 * Middleware للتحقق من JWT Token
 * يُستخدم في كل الـ routes المحمية
 */
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'غير مصرّح — يرجى تسجيل الدخول',
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      message: 'الرمز غير صالح أو منتهي الصلاحية',
    });
  }
}

module.exports = authMiddleware;
