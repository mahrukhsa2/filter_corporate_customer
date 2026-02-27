import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../views/Navbar/settings_view_model.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final String? title;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  const CustomAppBar({
    super.key,
    this.height = kToolbarHeight,
    this.title,
    this.showBackButton = false,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: height + 25,
      backgroundColor: AppColors.primaryLight,
      elevation: 4,
      shadowColor: Colors.black26,
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),

      // ✅ Custom Back Button
      leading: showBackButton
          ? Padding(
        padding: const EdgeInsets.only(top: 20, left: 12),
        child: InkWell(
          onTap: onBackTap ?? () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 18,
              ),
            ),
          ),
        ),
      )
          : null,
      leadingWidth: showBackButton ? 56 : null,

      // ✅ Title
      title: Padding(
        padding: const EdgeInsets.only(top: 25),
        child: title != null
            ? Text(
          title!,
          style: AppTextStyles.h3.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_car_wash_rounded,
              size: 22,
              color: Colors.black,
            ),
            const SizedBox(width: 6),
            Text(
              'Filter',
              style: AppTextStyles.h3.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),

      // ✅ Language Toggle Button
      actions: [
        Consumer<SettingsViewModel>(
          builder: (context, settings, _) {
            return Padding(
              padding: const EdgeInsets.only(top: 20, right: 12),
              child: InkWell(
                onTap: () {
                  final newLocale =
                  settings.locale.languageCode == 'en'
                      ? const Locale('ar')
                      : const Locale('en');
                  settings.updateLocale(newLocale);
                },
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.language_rounded,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height + 25);
}