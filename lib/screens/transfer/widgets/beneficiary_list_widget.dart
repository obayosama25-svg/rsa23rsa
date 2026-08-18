import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../theme/app_colors.dart';
import '../../../../models/beneficiary.dart';

class BeneficiaryListWidget extends StatelessWidget {
  final List<Beneficiary> beneficiaries;
  final Function(Beneficiary) onSelect;

  const BeneficiaryListWidget({
    super.key,
    required this.beneficiaries,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (beneficiaries.isEmpty) {
      return FadeInUp(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: const Center(
            child: Text(
              'لا يوجد أشخاص موثوقين مسجلين حالياً',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: beneficiaries.length,
        itemBuilder: (context, index) {
          final beneficiary = beneficiaries[index];
          return FadeInRight(
            delay: Duration(milliseconds: 100 * index),
            child: GestureDetector(
              onTap: () => onSelect(beneficiary),
              child: Container(
                width: 90,
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.black,
                      child: Icon(
                        Icons.person_outline,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      beneficiary.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

