import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class HomeFab extends StatelessWidget {
  final VoidCallback onPressed;

  const HomeFab({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.primaryGreen,
      child: const Icon(
        Icons.add_rounded,
        color: Colors.black,
        size: 32,
      ),
    );
  }
}
