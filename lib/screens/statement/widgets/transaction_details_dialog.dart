import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class TransactionDetailsDialog {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> tx,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Transaction Details',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, a1, a2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: _WhiteReceiptDialog(tx: tx),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}

class _WhiteReceiptDialog extends StatefulWidget {
  final Map<String, dynamic> tx;

  const _WhiteReceiptDialog({required this.tx});

  @override
  State<_WhiteReceiptDialog> createState() => _WhiteReceiptDialogState();
}

class _WhiteReceiptDialogState extends State<_WhiteReceiptDialog> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    // إعداد حركة النيون
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true); // يومض باستمرار للداخل والخارج

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isReceived = widget.tx['type'] == 'received';
    
    // جلب رقم المعاملة البنكي المكون من 16 رقماً بكل دقة
    final String transactionId = (widget.tx['id'] != null && widget.tx['id'].toString().isNotEmpty) 
        ? widget.tx['id'].toString() 
        : (widget.tx['transactionId'] != null ? widget.tx['transactionId'].toString() : 'N/A');

    final String comment = widget.tx['comment'] ?? widget.tx['note'] ?? '';
    
    // ضبط مسمى العملية حسب التصنيف والملاحظات
    String typeTitle = isReceived ? 'حوالة واردة' : 'حوالة صادرة';
    if (comment.contains('تغذية')) {
      typeTitle = 'تغذية حساب (إيداع)';
    } else if (comment.contains('خصم')) {
      typeTitle = 'خصم إداري';
    } else if (comment.contains('كهرباء')) {
      typeTitle = 'شحن كهرباء';
    } else if (comment.contains('اتصالات')) {
      typeTitle = 'شحن اتصالات';
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          final glowValue = _glowAnimation.value;
          return Container(
            width: screenSize.width * 0.95,
            height: screenSize.height * 0.90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              // تأثير النيون الأمني يحيط بكامل الإيصال
              border: Border.all(
                color: const Color(0xFF0284C7).withValues(alpha: 0.5 * glowValue), // لون أزرق فخم
                width: 2 + (2 * glowValue), // يتمدد ويتقلص ببطء
              ),
              boxShadow: [
                // الظل الطبيعي
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
                // إشعاع النيون الأزرق
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.6 * glowValue), // أزرق سماوي مضيء
                  blurRadius: 25 * glowValue,
                  spreadRadius: 6 * glowValue,
                ),
                // إشعاع داخلي لتعزيز تأثير النيون
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.4 * glowValue),
                  blurRadius: 40 * glowValue,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            // محتوى الإيصال القابل للتمرير
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    // الشعار العلوي
                    FadeInDown(
                      child: Image.asset(
                        'assets/images/sudacard_logo.png',
                        height: 60,
                        errorBuilder: (context, error, stackTrace) => 
                            const Text('SudaCard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // شريط أمان متحرك دلالة على الأصالة
                    FadeIn(
                      delay: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'إيصال بنكي موثق',
                              style: TextStyle(
                                color: const Color(0xFF1E3A8A),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF93C5FD).withValues(alpha: 0.5),
                                    blurRadius: 5,
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // العنوان
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: const Text(
                        'عملية ناجحة',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FadeInUp(
                      delay: const Duration(milliseconds: 350),
                      child: Text(
                        typeTitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // بطاقة البيانات
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            children: [
                              _buildTableRow('رقم المرجع', transactionId, isDarkRow: false),
                              _buildTableRow('التاريخ والوقت', widget.tx['date'] ?? 'N/A', isDarkRow: true),
                              _buildTableRow(isReceived ? 'إسم المرسل / الجهة' : 'إسم المستلم / الجهة', widget.tx['name'] ?? 'حساب النظام', isDarkRow: false),
                              _buildTableRow('البيان / السبب', comment.isEmpty ? 'معاملة مالية معتمدة' : comment, isDarkRow: true),
                              _buildTableRow(
                                'المبلغ المعالج', 
                                '${isReceived ? '+' : ''}${widget.tx['amount']} SDG', 
                                isDarkRow: false, 
                                isAmount: true, 
                                isReceived: isReceived
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // أزرار الإجراءات
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionIcon(Icons.share_rounded, 'مشاركة'),
                          _buildActionIcon(Icons.print_rounded, 'طباعة'),
                          _buildActionIcon(Icons.download_rounded, 'تحميل'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // التذييل - الحقوق والإغلاق
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                border: Border(
                  top: BorderSide(color: const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'جميع الحقوق محفوظة لـ',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/images/sudacard_logo.png',
                        height: 20,
                        errorBuilder: (context, error, stackTrace) => 
                            const Text('SudaCard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'إغلاق الإيصال',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(
    String label,
    String value, {
    required bool isDarkRow,
    bool isAmount = false,
    bool isReceived = false,
  }) {
    Color valueColor = const Color(0xFF0F172A);
    FontWeight valueWeight = FontWeight.w700;
    double valueSize = isAmount ? 22 : 14;

    if (isAmount) {
      valueColor = isReceived ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
      valueWeight = FontWeight.w900;
    }

    return Container(
      color: isDarkRow ? const Color(0xFFF1F5F9) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: valueSize,
                fontWeight: valueWeight,
                fontFamily: value.contains(RegExp(r'[0-9]')) && !isAmount ? 'Courier' : null,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: const Color(0xFF3B82F6), // أزرق احترافي للأيقونات
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
