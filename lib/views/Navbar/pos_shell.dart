import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

/// Placeholder shell — will be replaced with bottom nav + screens in later sprints.
class PosShell extends StatelessWidget {
  const PosShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 40, color: Colors.black),
            ),
            const SizedBox(height: 20),
            Text(
              'Login Successful!',
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dashboard coming in the next sprint.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryLight.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
