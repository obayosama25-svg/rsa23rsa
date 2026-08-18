import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sudacards/theme/app_colors.dart';
import 'package:sudacards/models/profile_models.dart';
import 'package:sudacards/screens/register/register_form_screen.dart';

class RegisterTypeScreen extends StatefulWidget {
  const RegisterTypeScreen({super.key});

  @override
  State<RegisterTypeScreen> createState() => _RegisterTypeScreenState();
}

class _RegisterTypeScreenState extends State<RegisterTypeScreen>
    with SingleTickerProviderStateMixin {
  AccountCategory? _selectedCategory;
  AccountSubType? _selectedSubType;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onCategorySelected(AccountCategory category) {
    setState(() {
      _selectedCategory = category;
      // Reset subtype if changing category
      _selectedSubType = category == AccountCategory.individual
          ? AccountSubType.none
          : null;
    });

    if (category != AccountCategory.individual) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _onNext() {
    if (_selectedCategory == null) return;
    if (_selectedCategory != AccountCategory.individual && _selectedSubType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار التخصص الفرعي للاستمرار'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // 3. شاشة اختيار نوع الحساب (Register Type Screen)
    // التوجيه إلى شاشة فورم التسجيل مع تمرير الفئة المختارة:
    // Register Type -> Register Form Screen
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RegisterFormScreen(
          initialCategory: _selectedCategory!,
          initialSubType: _selectedSubType ?? AccountSubType.none,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  List<AccountSubType> _getSubTypesForCategory(AccountCategory category) {
    switch (category) {
      case AccountCategory.individual:
        return [];
      case AccountCategory.business:
        return [
          AccountSubType.company,
          AccountSubType.cafe,
          AccountSubType.restaurant,
          AccountSubType.shop,
          AccountSubType.supermarket,
          AccountSubType.hotel,
          AccountSubType.salon,
        ];
      case AccountCategory.medical:
        return [
          AccountSubType.hospital,
          AccountSubType.clinic,
          AccountSubType.healthCenter,
          AccountSubType.pharmacy,
          AccountSubType.lab,
        ];
      case AccountCategory.educational:
        return [
          AccountSubType.school,
          AccountSubType.university,
          AccountSubType.trainingCenter,
        ];
      case AccountCategory.charity:
        return [AccountSubType.charityOrganization];
      case AccountCategory.government:
        return [
          AccountSubType.governmentEntity,
          AccountSubType.freelancer,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.15),
                    AppColors.darkBackground,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ما هو نوع حسابك؟',
                            style: TextStyle(
                              color: AppColors.textPremium,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'اختر الفئة التي تناسب نشاطك لنقوم بتخصيص تجربتك.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildCategoriesGrid(),
                          if (_selectedCategory != null &&
                              _selectedCategory != AccountCategory.individual) ...[
                            const SizedBox(height: 32),
                            const Text(
                              'حدد تخصصك الفرعي',
                              style: TextStyle(
                                color: AppColors.textPremium,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSubCategoryDropdown(),
                          ],
                          const SizedBox(height: 100), // spacing for bottom button
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Actions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryGreen),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'تسجيل جديد',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 48), // balance
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: AccountCategory.values.length,
      itemBuilder: (context, index) {
        final category = AccountCategory.values[index];
        final isSelected = _selectedCategory == category;

        return GestureDetector(
          onTap: () => _onCategorySelected(category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryBlue.withValues(alpha: 0.2)
                  : AppColors.darkSurface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primaryGreen : AppColors.glassBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category.icon,
                        size: 40,
                        color: isSelected ? AppColors.primaryGreen : Colors.white70,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        category.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubCategoryDropdown() {
    final subTypes = _getSubTypesForCategory(_selectedCategory!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AccountSubType>(
          value: _selectedSubType,
          hint: const Text(
            'اختر التخصص الفرعي...',
            style: TextStyle(color: AppColors.textMuted),
          ),
          dropdownColor: AppColors.darkSurfaceLight,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryGreen),
          items: subTypes.map((AccountSubType type) {
            return DropdownMenuItem<AccountSubType>(
              value: type,
              child: Text(
                type.label,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSubType = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.darkBackground,
            AppColors.darkBackground.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedCategory != null
              ? AppColors.primaryGreen
              : AppColors.darkSurfaceLight,
          foregroundColor: _selectedCategory != null ? Colors.black : Colors.white54,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _selectedCategory != null ? 10 : 0,
          shadowColor: AppColors.primaryGreen.withValues(alpha: 0.5),
        ),
        onPressed: _selectedCategory != null ? _onNext : null,
        child: const Text(
          'متابعة التسجيل',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
