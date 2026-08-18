import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../theme/app_colors.dart';

class TransferFormFields extends StatelessWidget {
  final TextEditingController accountController;
  final TextEditingController amountController;
  final TextEditingController commentController;
  final bool isSearching;
  final bool showAmountForm;
  final String? foundAccountName;
  final String? foundAccountId;
  final bool saveAsBeneficiary;
  final ValueChanged<bool?> onSaveBeneficiaryChanged;
  final VoidCallback onScanQr;
  final VoidCallback onSearchAccount;

  const TransferFormFields({
    super.key,
    required this.accountController,
    required this.amountController,
    required this.commentController,
    required this.isSearching,
    required this.showAmountForm,
    required this.foundAccountName,
    required this.foundAccountId,
    required this.saveAsBeneficiary,
    required this.onSaveBeneficiaryChanged,
    required this.onScanQr,
    required this.onSearchAccount,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: _buildCleanCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputLabel('رقم الحساب المستهدف', isDark),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: accountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        onChanged: (val) {
                           if (val.length >= 8) {
                             onSearchAccount();
                           }
                        },
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                        decoration: _buildInputDecoration(
                          hint: '12345678',
                          isDark: isDark,
                          prefix: Icon(
                            Icons.account_balance_outlined,
                            color: isDark ? Colors.white54 : Colors.black38,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildCircularIconButton(
                      icon: Icons.qr_code_scanner_rounded,
                      onPressed: onScanQr,
                      isDark: isDark,
                      isAccent: true, // Make QR the main accent button since Search is gone
                    ),
                  ],
                ),
                if (foundAccountName != null) ...[
                  _buildVerifiedUserBox(isDark),
                  const SizedBox(height: 16),
                  _buildSwitchOption(
                    label: 'إضافة لقائمة المستفيدين الموثوقين',
                    value: saveAsBeneficiary,
                    onChanged: onSaveBeneficiaryChanged,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showAmountForm) ...[
          const SizedBox(height: 20),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: _buildCleanCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('المبلغ المراد تحويله', isDark),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    decoration: _buildInputDecoration(
                      hint: '0.00',
                      isDark: isDark,
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? AppColors.primaryGreen.withValues(alpha: 0.15) 
                                : AppColors.primaryBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                      ),
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 8.0, left: 12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF3A3A3C) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ج.س',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildInputLabel('ملاحظات إضافية', isDark),
                  TextField(
                    controller: commentController,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 16,
                    ),
                    decoration: _buildInputDecoration(
                      hint: 'اكتب سبب التحويل (اختياري)...',
                      isDark: isDark,
                      prefix: Icon(
                        Icons.edit_note_rounded, 
                        color: isDark ? Colors.white54 : Colors.black38,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputLabel(String labelAr, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        labelAr,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1E293B),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required bool isDark,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : Colors.black38,
        fontSize: 16,
      ),
      prefixIcon: prefix,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF4F5F7), // Soft modern fill
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none, // Clean look, no borders
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildCleanCard({required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.4) 
                : const Color(0xFFE2E8F0).withValues(alpha: 0.8), // Soft elegant shadow
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCircularIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    bool isAccent = false,
    bool isLoading = false,
  }) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: isAccent 
            ? (isDark ? AppColors.primaryGreen : AppColors.primaryBlue)
            : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF4F5F7)),
        shape: BoxShape.circle, // Perfect circles like the reference image
        boxShadow: isAccent 
            ? [
                BoxShadow(
                  color: (isDark ? AppColors.primaryGreen : AppColors.primaryBlue).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: isLoading 
                ? const SizedBox(
                    width: 22, 
                    height: 22, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5, 
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    icon, 
                    color: isAccent 
                        ? (isDark ? Colors.black : Colors.white) 
                        : (isDark ? Colors.white70 : const Color(0xFF1E293B)), 
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedUserBox(bool isDark) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)] 
                : [const Color(0xFFF8FAFC), Colors.white], // Subtle soft gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Row(
          children: [
            Pulse(
              infinite: true,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primaryGreen.withValues(alpha: 0.2) : AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foundAccountName!,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (foundAccountId != null) 
                    Text(
                      foundAccountId!,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        fontSize: 13,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
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

  Widget _buildSwitchOption({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent, // No background, just a clean list item like the reference
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: 26,
              width: 26,
              decoration: BoxDecoration(
                color: value 
                    ? (isDark ? AppColors.primaryGreen : AppColors.primaryBlue)
                    : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF4F5F7)),
                shape: BoxShape.circle, // Circular modern switch/checkbox
                border: Border.all(
                  color: value 
                      ? Colors.transparent 
                      : (isDark ? Colors.white24 : Colors.black12),
                  width: 1.5,
                )
              ),
              child: value 
                  ? Icon(
                      Icons.check_rounded,
                      color: isDark ? Colors.black : Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
