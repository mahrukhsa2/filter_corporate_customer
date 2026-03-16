import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/reports_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/summary_stat_card.dart';
import 'reports_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportsViewModel(),
      child: const _ReportsBody(),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportsViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          CustomAppBar(title: "Reports", showBackButton: true),
          Expanded(
            child: vm.isLoading
                ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryLight))
                : RefreshIndicator(
              color: AppColors.primaryLight,
              onRefresh: () => vm.refresh(context: context),
              child: isWide
                  ? _WideLayout(vm: vm)
                  : _NarrowLayout(vm: vm),
            ),
          ),
        ],
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  final ReportsViewModel vm;
  const _NarrowLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        _SummaryCards(summary: vm.summary!),
        const SizedBox(height: 20),
        _CategoriesSection(vm: vm),
        const SizedBox(height: 20),
        _CustomReportSection(vm: vm),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  final ReportsViewModel vm;
  const _WideLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        children: [
          _SummaryCards(summary: vm.summary!),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: _CategoriesSection(vm: vm),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: _CustomReportSection(vm: vm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExportMenu extends StatelessWidget {
  final ReportsViewModel vm;
  const _ExportMenu({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.isExporting) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.onPrimaryLight),
        ),
      );
    }

    return PopupMenuButton<String>(
      onSelected: (format) async {
        await vm.exportAll(format);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Exporting all reports as $format…'),
          backgroundColor: AppColors.secondaryLight,
          behavior: SnackBarBehavior.floating,
        ));
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'PDF',
          child: Row(children: [
            const Icon(Icons.picture_as_pdf_outlined,
                size: 18, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text('Export as PDF', style: AppTextStyles.bodyMedium),
          ]),
        ),
        PopupMenuItem(
          value: 'Excel',
          child: Row(children: [
            const Icon(Icons.table_chart_outlined,
                size: 18, color: Colors.green),
            const SizedBox(width: 10),
            Text('Export as Excel', style: AppTextStyles.bodyMedium),
          ]),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_rounded,
                size: 16, color: AppColors.onPrimaryLight),
            const SizedBox(width: 6),
            Text('Export',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onPrimaryLight,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final ReportsSummary summary;
  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;

    final cards = [
      SummaryStatCard(
        title:      'Total Spent',
        subtitle:   'This Year',
        value:      'SAR ${_fmt(summary.totalSpentThisYear)}',
        icon:       Icons.account_balance_wallet_outlined,
        iconColor:  AppColors.secondaryLight,
        iconBgColor: AppColors.secondaryLight.withOpacity(0.08),
      ),
      SummaryStatCard(
        title:      'This Month',
        subtitle:   '${summary.thisMonthInvoices} Invoices',
        value:      'SAR ${_fmt(summary.thisMonthAmount)}',
        icon:       Icons.receipt_long_outlined,
        iconColor:  Colors.blue.shade700,
        iconBgColor: Colors.blue.shade50,
      ),
      SummaryStatCard(
        title:      'Total Savings',
        subtitle:   '(${summary.savingsPercent}%)',
        value:      'SAR ${_fmt(summary.totalSavings)}',
        icon:       Icons.savings_outlined,
        iconColor:  Colors.green.shade700,
        iconBgColor: Colors.green.shade50,
      ),
      SummaryStatCard(
        title:      'Wallet Used',
        subtitle:   '(${summary.walletUsedPercent.toInt()}% of total)',
        value:      'SAR ${_fmt(summary.walletUsed)}',
        icon:       Icons.account_balance_outlined,
        iconColor:  Colors.purple.shade700,
        iconBgColor: Colors.purple.shade50,
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .asMap()
            .entries
            .map((e) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: e.key < cards.length - 1 ? 12 : 0),
            child: e.value,
          ),
        ))
            .toList(),
      );
    }

    return Column(
      children: [
        Row(children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: cards[2]),
          const SizedBox(width: 12),
          Expanded(child: cards[3]),
        ]),
      ],
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final ReportsViewModel vm;
  const _CategoriesSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Report Categories',
      icon: Icons.grid_view_rounded,
      child: Column(
        children: vm.categories.map((cat) {
          return _ReportCategoryTile(category: cat);
        }).toList(),
      ),
    );
  }
}

class _ReportCategoryTile extends StatelessWidget {
  final ReportCategory category;
  const _ReportCategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.pushNamed(context, category.route),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_categoryIcon(category),
                      size: 20, color: AppColors.secondaryLight),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackgroundLight,
                          )),
                      const SizedBox(height: 2),
                      Text(category.subtitle,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: AppColors.secondaryLight),
                ),
              ],
            ),
          ),
        ),
        if (category != ReportCategory.values.last)
          Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  IconData _categoryIcon(ReportCategory cat) {
    switch (cat) {
      case ReportCategory.monthlyBilling:     return Icons.receipt_long_outlined;
      case ReportCategory.bookingHistory:     return Icons.calendar_month_outlined;
      case ReportCategory.quotationHistory:   return Icons.request_quote_outlined;
      case ReportCategory.walletTransactions: return Icons.account_balance_wallet_outlined;
      case ReportCategory.savingsDiscount:    return Icons.savings_outlined;
      case ReportCategory.vehicleUsage:       return Icons.directions_car_outlined;
      case ReportCategory.paymentHistory:     return Icons.payments_outlined;
    }
  }
}

class _CustomReportSection extends StatelessWidget {
  final ReportsViewModel vm;
  const _CustomReportSection({required this.vm});

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final now = DateTime.now();
    final initial = isFrom
        ? (vm.customFromDate ?? now.subtract(const Duration(days: 30)))
        : (vm.customToDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryLight,
            onPrimary: AppColors.onPrimaryLight,
            surface: AppColors.surfaceLight,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    if (isFrom) {
      vm.setCustomFromDate(picked);
    } else {
      vm.setCustomToDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Generate Custom Report',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Date range row ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _DatePickerTile(
                  label: 'From',
                  date: vm.customFromDate,
                  onTap: () => _pickDate(context, true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 18, color: Colors.grey.shade400),
              ),
              Expanded(
                child: _DatePickerTile(
                  label: 'To',
                  date: vm.customToDate,
                  onTap: () => _pickDate(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Report type dropdown ────────────────────────────────────
          DropdownButtonFormField<ReportCategory>(
            value: vm.customCategory,
            decoration: InputDecoration(
              labelText: 'Report Type',
              labelStyle: AppTextStyles.bodySmall
                  .copyWith(color: Colors.grey.shade600),
              prefixIcon: const Icon(Icons.bar_chart_rounded),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.primaryLight, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
            ),
            items: ReportCategory.values
                .map((c) => DropdownMenuItem(
              value: c,
              child: Text(c.title,
                  style: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ))
                .toList(),
            onChanged: (v) {
              if (v != null) vm.setCustomCategory(v);
            },
          ),
          const SizedBox(height: 16),

          // ── Error (fetch/export failed) ─────────────────────────────
          if (vm.customError != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 15, color: Colors.red.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.customError!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Generate button ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Generate & Download Excel',
              isLoading: vm.isGeneratingCustom,
              backgroundColor: vm.canGenerateCustom
                  ? AppColors.secondaryLight
                  : Colors.grey.shade300,
              textColor: vm.canGenerateCustom
                  ? Colors.white
                  : Colors.grey.shade500,
              onPressed: vm.isGeneratingCustom || !vm.canGenerateCustom
                  ? () {}
                  : () async {
                await vm.generateCustomReport(context: context);
                if (!context.mounted) return;
                if (vm.customError == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${vm.customCategory.title} report downloaded!'),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.secondaryLight),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackgroundLight,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasDate
              ? AppColors.primaryLight.withOpacity(0.08)
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDate ? AppColors.primaryLight : Colors.grey.shade300,
            width: hasDate ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: hasDate
                      ? AppColors.secondaryLight
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    hasDate ? _formatDate(date!) : 'Select',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: hasDate
                          ? AppColors.onBackgroundLight
                          : Colors.grey.shade400,
                      fontWeight:
                      hasDate ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

String _fmt(double v) {
  final parts = v.toStringAsFixed(0).split('');
  final buf = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
    buf.write(parts[i]);
  }
  return buf.toString();
}