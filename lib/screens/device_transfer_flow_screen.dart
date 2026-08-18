import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../services/registration_service.dart';
import 'home_screen.dart';

class DeviceTransferFlowScreen extends StatefulWidget {
  final String accountNumber;

  const DeviceTransferFlowScreen({super.key, required this.accountNumber});

  @override
  State<DeviceTransferFlowScreen> createState() => _DeviceTransferFlowScreenState();
}

class _DeviceTransferFlowScreenState extends State<DeviceTransferFlowScreen> {
  int _currentStep = 1;
  bool _isLoading = true;
  String _errorMessage = '';

  List<Map<String, dynamic>> _questions = [];
  final List<TextEditingController> _answerControllers = [];
  final _otpController = TextEditingController();

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

  Future<void> _requestOTP() async {
    setState(() => _isLoading = true);
    try {
      final deviceId = await RegistrationService.getDeviceId();
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/users/device-change/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accountNumber': widget.accountNumber, 'deviceId': deviceId}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success']) {
        setState(() {
          _currentStep = 2;
          _isLoading = false;
          _errorMessage = '';
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الرمز للبريد!'), backgroundColor: AppColors.primaryGreen));
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = data['message'] ?? 'فشل الإرسال';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في الاتصال';
      });
    }
  }

  Future<void> _verifyAndTransfer() async {
    setState(() => _isLoading = true);
    final answers = [];
    for (var i = 0; i < _questions.length; i++) {
      answers.add({
        'question': _questions[i]['question'],
        'answer': _answerControllers[i].text.trim()
      });
    }

    try {
      final deviceId = await RegistrationService.getDeviceId();
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/users/device-change/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accountNumber': widget.accountNumber,
          'deviceId': deviceId,
          'otpCode': _otpController.text.trim(),
          'answers': answers
        }),
      );
      final data = jsonDecode(res.body);
      
      if (res.statusCode == 200 && data['success']) {
        // Success! We need to store the session now since we are logged in.
        // Wait, the API returns a token, but we still need the user object.
        // It's safer to just let the user login again normally now that the device is linked.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم ربط الجهاز بنجاح! يمكنك الدخول الآن.'), backgroundColor: AppColors.primaryGreen));
        Navigator.pop(context); // Go back to login screen
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

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool isObscure = false, TextInputType type = TextInputType.text}) {
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
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

    if (_currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.security, size: 60, color: AppColors.primaryGreen),
          const SizedBox(height: 16),
          const Text(
            'محاولة دخول من جهاز جديد',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'لقد لاحظنا محاولة تسجيل الدخول من جهاز غير مألوف. لحماية حسابك، يرجى تأكيد هويتك عن طريق استلام رمز تحقق (OTP) على بريدك الإلكتروني، والإجابة على أسئلة الأمان.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _requestOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('إرسال الرمز للبريد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('التحقق النهائي:', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildTextField(_otpController, 'رمز الـ OTP المرسل لبريدك', type: TextInputType.number),
          const SizedBox(height: 10),
          const Text('أسئلة الأمان:', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
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
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyAndTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('تأكيد وربط الجهاز', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('نقل الجهاز', style: TextStyle(color: Colors.white)),
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
