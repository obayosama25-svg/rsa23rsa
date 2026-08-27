import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../services/api_service.dart';
class RecoveryFlowScreen extends StatefulWidget {
  final String accountNumber;

  const RecoveryFlowScreen({super.key, required this.accountNumber});

  @override
  State<RecoveryFlowScreen> createState() => _RecoveryFlowScreenState();
}

class _RecoveryFlowScreenState extends State<RecoveryFlowScreen> {
  int _currentStep = 1;
  bool _isLoading = true;
  String _errorMessage = '';

  // Step 1
  List<Map<String, dynamic>> _questions = [];
  final List<TextEditingController> _answerControllers = [];
  bool _hasSetPin = false;

  // Step 2
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();

  // Step 3
  final _otpController = TextEditingController();

  // Step 4
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/users/recover/questions/${widget.accountNumber}'));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success']) {
        final qs = List<Map<String, dynamic>>.from(data['questions']);
        setState(() {
          _questions = qs;
          _hasSetPin = data['hasSetPin'] == true;
          for (var i = 0; i < qs.length; i++) {
            _answerControllers.add(TextEditingController());
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'فشل جلب الأسئلة';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في الاتصال بالخادم';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyQuestions() async {
    setState(() => _isLoading = true);
    final answers = [];
    for (var i = 0; i < _questions.length; i++) {
      answers.add({
        'question': _questions[i]['question'],
        'answer': _answerControllers[i].text.trim()
      });
    }

    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/users/recover/verify-questions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accountNumber': widget.accountNumber, 'answers': answers}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success']) {
        setState(() {
          _currentStep = 2;
          _isLoading = false;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = data['message'] ?? 'إجابات خاطئة';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في الاتصال';
      });
    }
  }

  Future<void> _verifyPinAndEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'يرجى إدخال البريد الإلكتروني الخاص بحسابك');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/users/recover/verify-pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accountNumber': widget.accountNumber,
          'email': email,
          'pin': _normalizeDigits(_pinController.text)
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success']) {
        setState(() {
          _currentStep = 3;
          _isLoading = false;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = data['message'] ?? 'البيانات غير صحيحة';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في الاتصال';
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'كلمة المرور غير متطابقة');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/users/recover/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accountNumber': widget.accountNumber,
          'otpCode': _normalizeDigits(_otpController.text),
          'newPassword': _newPasswordController.text
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success']) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استعادة الحساب بنجاح!'), backgroundColor: AppColors.primaryGreen));
        Navigator.pop(context); // العودة لشاشة الدخول
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = data['message'] ?? 'رمز خاطئ أو منتهي الصلاحية';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في الاتصال';
      });
    }
  }

  String _normalizeDigits(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    var result = input;
    for (int i = 0; i < arabic.length; i++) {
      result = result.replaceAll(arabic[i], english[i]);
    }
    return result.trim();
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {
    bool isObscure = false, 
    TextInputType type = TextInputType.text,
    TextDirection? textDirection,
    TextAlign? textAlign,
  }) {
    final bool isNumberOrSecret = isObscure || type == TextInputType.number || type == TextInputType.phone || type == TextInputType.emailAddress || type == TextInputType.visiblePassword;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isObscure,
        keyboardType: type,
        textDirection: textDirection ?? (isNumberOrSecret ? TextDirection.ltr : TextDirection.rtl),
        textAlign: textAlign ?? (isNumberOrSecret ? TextAlign.center : TextAlign.start),
        style: TextStyle(
          color: Colors.white,
          letterSpacing: isObscure ? 4 : (type == TextInputType.number ? 2 : 0),
          fontWeight: isNumberOrSecret ? FontWeight.bold : FontWeight.normal,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          hintTextDirection: TextDirection.rtl,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_isLoading && _currentStep == 1 && _questions.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    switch (_currentStep) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('أجب على أسئلة الأمان الخاصة بك:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...List.generate(_questions.length, (index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_questions[index]['question'], style: const TextStyle(color: AppColors.primaryGreen, fontSize: 14)),
                  const SizedBox(height: 8),
                  _buildTextField(_answerControllers[index], 'الإجابة...'),
                ],
              );
            }),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('متابعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _hasSetPin ? 'التحقق الثانوي:' : 'تأكيد البريد الإلكتروني:',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _hasSetPin 
                ? 'يرجى إدخال البريد الإلكتروني ورقم PIN المرتبط بالحساب' 
                : 'يرجى إدخال بريدك الإلكتروني لاستلام رمز التحقق (OTP)',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildTextField(_emailController, 'البريد الإلكتروني', type: TextInputType.emailAddress),
            if (_hasSetPin)
              _buildTextField(_pinController, 'رقم الـ PIN (4 أرقام)', isObscure: true, type: TextInputType.number),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyPinAndEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('تأكيد وطلب الرمز', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        );
      case 3:
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('إعادة تعيين كلمة المرور:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField(_otpController, 'رمز الـ OTP (6 أرقام)', type: TextInputType.number),
            _buildTextField(_newPasswordController, 'كلمة المرور الجديدة', isObscure: true),
            _buildTextField(_confirmPasswordController, 'تأكيد كلمة المرور', isObscure: true),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('حفظ كلمة المرور', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('استعادة الحساب المغلق', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_errorMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.errorRed)),
                child: Text(_errorMessage, style: const TextStyle(color: AppColors.errorRed)),
              ),
            _buildStepContent(),
          ],
        ),
      ),
    );
  }
}
