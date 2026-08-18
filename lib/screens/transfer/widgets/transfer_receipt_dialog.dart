import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../theme/app_colors.dart';

class TransferReceiptDialog {
  static void showConfirmation({
    required BuildContext context,
    required String accountName,
    required String? accountId,
    required String accountNumber,
    required String amount,
    required String comment,
    required VoidCallback onConfirm,
  }) {
    final String tempId = 'REQ-${DateTime.now().toUtc().millisecondsSinceEpoch.toString().substring(8)}';
    final String tempTime = DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now().toUtc());

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Confirmation',
      barrierColor: Colors.black.withValues(alpha: 0.95),
      pageBuilder: (context, a1, a2) {
        final screenSize = MediaQuery.of(context).size;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: screenSize.width * 0.9,
              height: screenSize.height * 0.9,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.darkSurface.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_outlined,
                      color: AppColors.primaryBlue,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'مراجعة بيانات العملية',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      children: [
                        _buildReceiptRow('رقم الطلب:', tempId),
                        _buildReceiptRow('وقت المراجعة:', tempTime),
                        const Divider(color: Colors.white10, height: 32),
                        _buildConfirmRow('المستلم:', accountName),
                        if (accountId != null)
                          _buildConfirmRow('معرف المستلم (12 رقم):', accountId),
                        _buildConfirmRow('للحساب:', accountNumber),
                        _buildConfirmRow('المبلغ:', '$amount SDG'),
                        if (comment.isNotEmpty)
                          _buildConfirmRow('التعليق:', comment),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: onConfirm,
                      child: const Text(
                        'إرسال وتأكيد التحويل الآن',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'إلغاء والتراجع عن العملية',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void showSuccess({
    required BuildContext context,
    required String accountName,
    required String? accountId,
    required String accountNumber,
    required String amount,
    required String comment,
    required VoidCallback onClose,
    ReceiptStatus initialStatus = ReceiptStatus.pending,
  }) {
    final String transactionId = 'SUDACARD-${DateTime.now().toUtc().millisecondsSinceEpoch.toString().substring(5)}';
    final String transactionTime = DateFormat('dd-MMM-yyyy HH:mm:ss').format(DateTime.now().toUtc());

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Success',
      barrierColor: Colors.black.withValues(alpha: 0.95),
      pageBuilder: (context, a1, a2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: _GlowingReceiptDialog(
              accountName: accountName,
              accountId: accountId,
              accountNumber: accountNumber,
              amount: amount,
              comment: comment,
              transactionId: transactionId,
              transactionTime: transactionTime,
              onClose: onClose,
              initialStatus: initialStatus,
            ),
          ),
        );
      },
    );
  }

  static Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  static Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

enum ReceiptStatus {
  success,
  pending,
  failed,
}

class _GlowingReceiptDialog extends StatefulWidget {
  final String accountName;
  final String? accountId;
  final String accountNumber;
  final String amount;
  final String comment;
  final String transactionId;
  final String transactionTime;
  final VoidCallback onClose;
  final ReceiptStatus initialStatus;

  const _GlowingReceiptDialog({
    required this.accountName,
    required this.accountId,
    required this.accountNumber,
    required this.amount,
    required this.comment,
    required this.transactionId,
    required this.transactionTime,
    required this.onClose,
    this.initialStatus = ReceiptStatus.pending,
  });

  @override
  State<_GlowingReceiptDialog> createState() => _GlowingReceiptDialogState();
}

class _GlowingReceiptDialogState extends State<_GlowingReceiptDialog> with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _refreshController;
  late ReceiptStatus _status;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _triggerRefresh() {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    _refreshController.repeat();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      final cleanAmount = widget.amount.replaceAll(RegExp(r'[^0-9.]'), '');
      final amountVal = double.tryParse(cleanAmount) ?? 0.0;
      
      setState(() {
        _isRefreshing = false;
        _refreshController.stop();
        if (amountVal > 50000.0) {
          _status = ReceiptStatus.failed;
        } else {
          _status = ReceiptStatus.success;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          final glowOpacity = _glowAnimation.value;
          
          final LinearGradient backgroundGradient;
          final Color borderColor;
          final Color glowColor;

          switch (_status) {
            case ReceiptStatus.success:
              backgroundGradient = const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF072417),
                  Color(0xFF0F3D2A),
                  Color(0xFF051C12),
                ],
              );
              borderColor = const Color(0xFF00FF87);
              glowColor = const Color(0xFF00FF87);
              break;
            case ReceiptStatus.pending:
              backgroundGradient = const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2C2209),
                  Color(0xFF4C3E14),
                  Color(0xFF1E1605),
                ],
              );
              borderColor = const Color(0xFFFFD700);
              glowColor = const Color(0xFFFFD700);
              break;
            case ReceiptStatus.failed:
              backgroundGradient = const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2B0A0D),
                  Color(0xFF4C151A),
                  Color(0xFF1E0406),
                ],
              );
              borderColor = const Color(0xFFFF453A);
              glowColor = const Color(0xFFFF453A);
              break;
          }

          return Container(
            width: screenSize.width * 0.9,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              gradient: backgroundGradient,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.6 * glowOpacity),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.25 * glowOpacity),
                  blurRadius: 35 * glowOpacity,
                  spreadRadius: 6 * glowOpacity,
                ),
              ],
            ),
            child: child,
          );
        },
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderIcon(),
              const SizedBox(height: 16),
              _buildTitleText(),
              const SizedBox(height: 24),
              
              // جدول البيانات
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      _buildTableRow('رقم العملية', widget.transactionId, isDarkRow: false),
                      _buildTableRow('حالة العملية', _getStatusText(), isDarkRow: true, isStatus: true),
                      _buildTableRow('التاريخ و الزمن', widget.transactionTime, isDarkRow: false),
                      _buildTableRow('من حساب', '0723 0527 1360 0001', isDarkRow: true),
                      _buildTableRow('الى حساب', widget.accountNumber, isDarkRow: false),
                      _buildTableRow('إسم المرسل اليه', widget.accountName, isDarkRow: true),
                      _buildTableRow('رقم الموبايل', 'N/A', isDarkRow: false),
                      _buildTableRow('التعليق', widget.comment.isEmpty ? 'N/A' : widget.comment, isDarkRow: true),
                      _buildTableRow('المبلغ', '${widget.amount} SDG', isDarkRow: false, isAmount: true),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // زر موافق
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _status == ReceiptStatus.success
                      ? const Color(0xFF00FF87)
                      : (_status == ReceiptStatus.pending ? const Color(0xFFFFD700) : const Color(0xFFFF453A)),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white30, width: 1),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black45,
                ),
                onPressed: widget.onClose,
                child: const Text(
                  'موافق',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // الأزرار السفلية (إضافة مستفيد، مشاركة، طباعة...)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionIcon(Icons.person_add_alt_1_rounded, 'إضافة مستفيد'),
                  _buildActionIcon(Icons.refresh_rounded, 'تحويل مرة اخرى'),
                  _buildActionIcon(Icons.share_rounded, 'مشاركة'),
                  _buildActionIcon(Icons.print_rounded, 'طباعة'),
                  _buildActionIcon(Icons.download_rounded, 'تحميل'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_status) {
      case ReceiptStatus.success:
        return 'تمت بنجاح';
      case ReceiptStatus.pending:
        return 'قيد الإجراء';
      case ReceiptStatus.failed:
        return 'فشلت العملية';
    }
  }

  Widget _buildHeaderIcon() {
    switch (_status) {
      case ReceiptStatus.success:
        return ElasticIn(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                color: Color(0xFF0F5132),
                size: 55,
              ),
            ),
          ),
        );
      case ReceiptStatus.pending:
        return ElasticIn(
          child: GestureDetector(
            onTap: _triggerRefresh,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: RotationTransition(
                  turns: _refreshController,
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF856404),
                    size: 50,
                  ),
                ),
              ),
            ),
          ),
        );
      case ReceiptStatus.failed:
        return ElasticIn(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.close_rounded,
                color: Color(0xFF842029),
                size: 55,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildTitleText() {
    switch (_status) {
      case ReceiptStatus.success:
        return const Column(
          children: [
            Text(
              'تمت العملية بنجاح',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case ReceiptStatus.pending:
        return const Column(
          children: [
            Text(
              'العملية قيد الإجراء',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              'اضغط على سهم التحديث لمتابعة حالة العملية',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case ReceiptStatus.failed:
        return const Column(
          children: [
            Text(
              'لم تنجح العملية',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              'رصيدك أقل من حدود العملية',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
    }
  }

  Widget _buildTableRow(
    String label,
    String value, {
    required bool isDarkRow,
    bool isAmount = false,
    bool isStatus = false,
  }) {
    Color valueColor = Colors.white;
    FontWeight valueWeight = FontWeight.w600;
    double valueSize = isAmount ? 18 : 14;

    if (isStatus) {
      if (_status == ReceiptStatus.success) {
        valueColor = const Color(0xFF00FF87);
      } else if (_status == ReceiptStatus.pending) {
        valueColor = const Color(0xFFFFD700);
      } else {
        valueColor = const Color(0xFFFF453A);
      }
      valueWeight = FontWeight.bold;
    }

    return Container(
      color: isDarkRow ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: isStatus
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: valueColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        value,
                        style: TextStyle(
                          color: valueColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Text(
                    value,
                    style: TextStyle(
                      color: isAmount ? const Color(0xFF00FF87) : valueColor,
                      fontSize: valueSize,
                      fontWeight: valueWeight,
                      letterSpacing: value.contains(RegExp(r'[0-9]')) ? 0.5 : 0.0,
                    ),
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
