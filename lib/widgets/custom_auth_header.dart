import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../views/Navbar/settings_view_model.dart';

class CustomAuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final double? height;

  const CustomAuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBackButton = false,
    this.onBackTap,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final double iconContainerSize = isTablet ? 50 : 40;
    final double iconSize = isTablet ? 30 : 22;

    return Container(
      height: height ?? screenHeight * 0.35,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: isTablet ? 40 : 10), // Reduced top spacing
            // Top row: Logo (centered) | Language (right corner) | Back Button (optional left)
            SizedBox(
              height: 50,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back Button
                  if (showBackButton)
                    Positioned(
                      left: 16,
                      child: InkWell(
                        onTap: onBackTap ?? () => Navigator.pop(context),
                        child: Container(
                          width: iconContainerSize,
                          height: iconContainerSize,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.black,
                              size: iconSize,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Logo – dead center
                  SizedBox(
                    height: 45,
                    child: Image.asset(
                      'assets/images/filter_logo.png',
                      color: Colors.black,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Language icon – absolute right corner
                  Positioned(
                    right: 16,
                    child: Consumer<SettingsViewModel>(
                      builder: (context, settings, _) {
                        return InkWell(
                          onTap: () {
                            final newLocale = settings.locale.languageCode == 'en'
                                ? const Locale('ar')
                                : const Locale('en');
                            settings.updateLocale(newLocale);
                          },
                          child: Container(
                            width: iconContainerSize,
                            height: iconContainerSize,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/global.png',
                                width: iconSize,
                                height: iconSize,
                                color: Colors.black,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.language, size: iconSize, color: Colors.black),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isTablet ? 60 : 30), // Adjusted spacing

            Text(
              title,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.onPrimaryLight,
                fontSize: isTablet ? 22 : 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onPrimaryLight.withOpacity(0.7),
                fontSize: isTablet ? 14 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}