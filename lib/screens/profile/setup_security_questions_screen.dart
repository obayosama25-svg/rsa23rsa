import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../services/api_service.dart';
import '../home_screen.dart'; // مسار الصفحة الرئيسية

class SetupSecurityQuestionsScreen extends StatefulWidget {
  const SetupSecurityQuestionsScreen({super.key});

  @override
  State<SetupSecurityQuestionsScreen> createState() => _SetupSecurityQuestionsScreenState();
}

class _SetupSecurityQuestionsScreenState extends State<SetupSecurityQuestionsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final List<String> _availableQuestions = [
    'ما هو اسم مدرستك الابتدائية؟',
    'ما هو اسم حيوانك الأليف الأول؟',
    'ما هي المدينة التي ولد فيها والدك؟',
    'ما هو لون سيارتك الأولى؟',
    'ما هو اسم فريقك الرياضي المفضل؟',
    'ما هو اسم أفضل أصدقاء طفولتك؟',
    'ما هو طعامك المفضل في الصغر؟'
  ];

  String? _q1, _q2, _q3;
  final _a1Controller = TextEditingController();
  final _a2Controller = TextEditingController();
  final _a3Controller = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_q1 == null || _q2 == null || _q3 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار 3 أسئلة مختلفة')),
      );
      return;
    }

    // التأكد من عدم تكرار الأسئلة
    if (_q1 == _q2 || _q1 == _q3 || _q2 == _q3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن تكرار نفس السؤال')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'questions': [
          {'question': _q1, 'answer': _a1Controller.text},
          {'question': _q2, 'answer': _a2Controller.text},
          {'question': _q3, 'answer': _a3Controller.text},
        ]
      };

      final response = await ApiService.post('/users/me/security-questions', payload);
      
      if (response.statusCode == 200) {
        // حفظ محلي أن الأسئلة تم إعدادها
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasSecurityQuestions', true);

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعداد أسئلة الأمان بنجاح!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        // العودة للرئيسية كما طلب المستخدم
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل حفظ أسئلة الأمان، حاول مجدداً')),
        );
      }
    } catch (e) {
      debugPrint('Setup Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ في الاتصال بالخادم')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF4F6FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const SizedBox.shrink(), // لا يوجد زر تراجع (إجباري)
          title: Text(
            'إعداد أسئلة الأمان',
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0052FF).withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.security_rounded, color: Color(0xFF0052FF), size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'يرجى إعداد 3 أسئلة أمان لحماية حسابك واستعادتة مستقبلاً. يرجى تذكر الإجابات جيداً.',
                            style: TextStyle(color: Color(0xFF0052FF), fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: _buildQuestionSection('السؤال الأول', _q1, (v) => setState(() => _q1 = v), _a1Controller, isDark),
                ),
                const SizedBox(height: 24),
                
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildQuestionSection('السؤال الثاني', _q2, (v) => setState(() => _q2 = v), _a2Controller, isDark),
                ),
                const SizedBox(height: 24),

                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _buildQuestionSection('السؤال الثالث', _q3, (v) => setState(() => _q3 = v), _a3Controller, isDark),
                ),
                const SizedBox(height: 40),

                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0052FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('حفظ والمتابعة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionSection(String title, String? selectedQ, ValueChanged<String?> onChanged, TextEditingController controller, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1826) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedQ,
            hint: const Text('اختر سؤال الأمان'),
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _availableQuestions.map((q) => DropdownMenuItem<String>(value: q, child: Text(q, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: onChanged,
            validator: (v) => v == null ? 'مطلوب' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'إجابتك',
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى كتابة الإجابة' : null,
          ),
        ],
      ),
    );
  }
}
