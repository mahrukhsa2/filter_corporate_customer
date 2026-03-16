import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/summary_stat_card.dart
//
// Reusable summary/KPI card used across multiple screens:
//   - Reports landing (summary stats)
//   - Home dashboard (KPI cards)
//   - Any screen needing a labelled stat tile
//
// Usage:
//   SummaryStatCard(
//     title:    'Total Spent',
//     subtitle: 'This Year',
//     value:    'SAR 128,500',
//     icon:     Icons.account_balance_wallet_outlined,
//     iconColor: AppColors.secondaryLight,
//     iconBgColor: AppColors.secondaryLight.withOpacity(0.08),
//   )
// ─────────────────────────────────────────────────────────────────────────────

class SummaryStatCard extends StatelessWidget {
  final String   title;
  final String   subtitle;
  final String   value;
  final IconData icon;
  final Color    iconColor;
  final Color    iconBgColor;

  /// Optional: override the value text color (defaults to iconColor)
  final Color? valueColor;

  /// Optional: called when card is tapped
  final VoidCallback? onTap;

  const SummaryStatCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:        iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color:      AppColors.onBackgroundLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Value
            Text(
              value,
              style: AppTextStyles.h3.copyWith(
                color:      valueColor ?? iconColor,
                fontWeight: FontWeight.w800,
                fontSize:   18,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              subtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
