import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/cyber_background.dart';
import '../models/beneficiary.dart';
import 'transfer/widgets/transfer_form_fields.dart';

import 'transfer/widgets/transfer_receipt_dialog.dart';
import '../services/transaction_service.dart';
import '../services/session_manager.dart';
import 'home/widgets/qr_action_helper.dart';

class TransferScreen extends StatefulWidget {
  final String? initialAccountNumber;
  const TransferScreen({super.key, this.initialAccountNumber});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  bool _isSearching = false;
  bool _showTransferForm = false;
  bool _saveAsBeneficiary = false;
  List<Beneficiary> _localBeneficiaries = [];

  String? _foundAccountName;
  String? _foundAccountId;

  @override
  void initState() {
    super.initState();
    _loadBeneficiaries();
    if (widget.initialAccountNumber != null) {
      _accountController.text = widget.initialAccountNumber!;
      _searchAccount(widget.initialAccountNumber!);
    }
  }

  Future<void> _loadBeneficiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('beneficiaries_json');
    if (jsonList != null) {
      setState(() {
        _localBeneficiaries =
            jsonList.map((str) => Beneficiary.fromJson(str)).toList();
      });
    } else {
      // Migrate old string-based beneficiaries if they exist
      final oldList = prefs.getStringList('beneficiaries');
      if (oldList != null && oldList.isNotEmpty) {
        setState(() {
          _localBeneficiaries = oldList
              .map((name) => Beneficiary(
                    id: 'Migrated',
                    name: name,
                    accountNumber: 'Unknown',
                  ))
              .toList();
        });
        // Save back as json
        await prefs.setStringList(
            'beneficiaries_json',
            _localBeneficiaries.map((b) => b.toJson()).toList());
      }
    }
  }

  Future<void> _saveBeneficiary(Beneficiary beneficiary) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_localBeneficiaries.any((b) => b.accountNumber == beneficiary.accountNumber)) {
      _localBeneficiaries.add(beneficiary);
      await prefs.setStringList(
          'beneficiaries_json',
          _localBeneficiaries.map((b) => b.toJson()).toList());
      setState(() {});
    }
  }

  Future<void> _searchAccount(String accNum) async {
    if (accNum.length < 8) return;

    final currentAccount = SessionManager().currentUser?.accountNumber;
    final currentUserId = SessionManager().currentUser?.id;

    if (accNum.trim() == currentAccount || accNum.trim() == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن التحويل إلى حسابك الشخصي!'),
          backgroundColor: AppColors.warningOrange,
        ),
      );
      setState(() {
        _showTransferForm = false;
        _foundAccountName = null;
        _foundAccountId = null;
      });
      return;
    }

    setState(() => _isSearching = true);

    final userMap = await TransactionService.searchAccount(accNum);

    if (mounted) {
      setState(() {
        _isSearching = false;
        if (userMap != null) {
          _showTransferForm = true;
          _foundAccountName = "${userMap['firstName'] ?? ''} ${userMap['lastName'] ?? ''}".trim();
          _foundAccountId = userMap['_id'];
        } else {
          _showTransferForm = false;
          _foundAccountName = null;
          _foundAccountId = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('رقم الحساب غير موجود'),
              backgroundColor: AppColors.warningOrange,
            ),
          );
        }
      });
    }
  }

  void _scanBarcode() {
    QrActionHelper.showQrScanner(context);
  }

  void _showTransferConfirmationDialog() {
    TransferReceiptDialog.showConfirmation(
      context: context,
      accountName: _foundAccountName ?? "غير معروف",
      accountId: _foundAccountId,
      accountNumber: _accountController.text,
      amount: _amountController.text,
      comment: _commentController.text,
      onConfirm: () {
        Navigator.pop(context); // Close confirmation
        _executeTransfer();
      },
    );
  }

  Future<void> _executeTransfer() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
    );

    final amount = double.tryParse(_amountController.text) ?? 0;
    final success = await TransactionService.transferMoney(
      receiverAccountNumber: _accountController.text,
      amount: amount,
      note: _commentController.text,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading
    }

    if (success) {
      if (_saveAsBeneficiary && _foundAccountName != null && mounted) {
        _saveBeneficiary(Beneficiary(
          id: _foundAccountId ?? '',
          name: _foundAccountName!,
          accountNumber: _accountController.text,
        ));
      }

      if (mounted) {
        TransferReceiptDialog.showSuccess(
          context: context,
          accountName: _foundAccountName ?? "غير معروف",
          accountId: _foundAccountId,
          accountNumber: _accountController.text,
          amount: _amountController.text,
          comment: _commentController.text,
          onClose: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشلت عملية التحويل. تأكد من توفر رصيد كافٍ.'),
            backgroundColor: AppColors.warningOrange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        children: [
          // Background components
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: AppColors.background(context)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    isDark
                        ? AppColors.primaryBlue.withValues(alpha: 0.15)
                        : AppColors.primaryBlue.withValues(alpha: 0.08),
                    AppColors.background(context),
                  ],
                ),
              ),
            ),
          ),
          const TechGridBackground(),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          duration: const Duration(milliseconds: 600),
                          child: TransferFormFields(
                            accountController: _accountController,
                            amountController: _amountController,
                            commentController: _commentController,
                            isSearching: _isSearching,
                            showAmountForm: _showTransferForm,
                            foundAccountName: _foundAccountName,
                            foundAccountId: _foundAccountId,
                            saveAsBeneficiary: _saveAsBeneficiary,
                            onSaveBeneficiaryChanged: (v) =>
                                setState(() => _saveAsBeneficiary = v ?? false),
                            onScanQr: _scanBarcode,
                            onSearchAccount: () =>
                                _searchAccount(_accountController.text),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_showTransferForm)
                          FadeInUp(
                            child: SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? AppColors.primaryGreen.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppColors.primaryBlue.withValues(
                                              alpha: 0.2,
                                            ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_amountController.text.isEmpty) return;
                                    _showTransferConfirmationDialog();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark
                                        ? AppColors.primaryGreen
                                        : AppColors.primaryBlue,
                                    foregroundColor: isDark
                                        ? Colors.black
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'تأكيد وتنفيذ التحويل',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.text(context),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                'إرسال أموال',
                style: TextStyle(
                  color: isDark
                      ? AppColors.primaryGreen
                      : AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
              Container(
                height: 2,
                width: 40,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
