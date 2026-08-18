import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../theme/app_colors.dart';
import '../../../../models/beneficiary.dart';
import '../../beneficiaries_screen.dart';

class TrustedBeneficiaries extends StatefulWidget {
  const TrustedBeneficiaries({super.key});

  @override
  State<TrustedBeneficiaries> createState() => _TrustedBeneficiariesState();
}

class _TrustedBeneficiariesState extends State<TrustedBeneficiaries> {
  List<Beneficiary> _beneficiaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBeneficiaries();
  }

  Future<void> _loadBeneficiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('beneficiaries_json');
    if (jsonList != null) {
      setState(() {
        _beneficiaries = jsonList.map((str) => Beneficiary.fromJson(str)).toList();
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading || _beneficiaries.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayList = _beneficiaries.take(7).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المستفيدين الموثوقين',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: displayList.length + 1, // +1 for the 'See All' button
              itemBuilder: (context, index) {
                if (index == displayList.length) {
                  return FadeInRight(
                    delay: Duration(milliseconds: 100 * index),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BeneficiariesScreen(),
                          ),
                        ).then((_) => _loadBeneficiaries()); // Reload when coming back
                      },
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.primaryGreen.withValues(alpha: 0.2) : AppColors.primaryBlue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: isDark ? AppColors.primaryGreen : AppColors.primaryBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'المزيد',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final beneficiary = displayList[index];
                return FadeInRight(
                  delay: Duration(milliseconds: 100 * index),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0),
                          child: Text(
                            beneficiary.name.isNotEmpty ? beneficiary.name.substring(0, 1) : '?',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          beneficiary.name,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
