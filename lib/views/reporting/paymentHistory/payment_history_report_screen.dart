import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/payment_history_report_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import 'payment_history_report_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class PaymentHistoryReportScreen extends StatelessWidget {
  const PaymentHistoryReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaymentHistoryReportViewModel(),
      child: const _PHBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _PHBody extends StatelessWidget {
  const _PHBody();

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<PaymentHistoryReportViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          const CustomAppBar(
              title: 'Payment History', showBackButton: true),
          Expanded(
            child: vm.isLoading
                ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryLight))
                : RefreshIndicator(
              color: AppColors.primaryLight,
              onRefresh: vm.refresh,
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

// ─────────────────────────────────────────────────────────────────────────────
// Layouts
// ─────────────────────────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final PaymentHistoryReportViewModel vm;
  const _NarrowLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _pad(16, child: _FiltersBar(vm: vm)),
        _pad(14, child: _TableCard(vm: vm)),
        if (vm.summary != null)
          _pad(14, child: _SummarySection(summary: vm.summary!)),
        _pad(14, bottom: 32, child: _ExportButton()),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  final PaymentHistoryReportViewModel vm;
  const _WideLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _pad(20, h: 24, child: _FiltersBar(vm: vm)),
        _pad(14, h: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _TableCard(vm: vm)),
                const SizedBox(width: 20),
                SizedBox(
                  width: 280,
                  child: vm.summary != null
                      ? _SummarySection(summary: vm.summary!)
                      : const SizedBox(),
                ),
              ],
            )),
        _pad(14, h: 24, bottom: 32, child: _ExportButton()),
      ],
    );
  }
}

SliverPadding _pad(double top,
    {double h = 16, double bottom = 0, required Widget child}) =>
    SliverPadding(
      padding: EdgeInsets.fromLTRB(h, top, h, bottom),
      sliver: SliverToBoxAdapter(child: child),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Filters bar
// ─────────────────────────────────────────────────────────────────────────────

class _FiltersBar extends StatefulWidget {
  final PaymentHistoryReportViewModel vm;
  const _FiltersBar({required this.vm});

  @override
  State<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends State<_FiltersBar> {
  Future<void> _pickDate(bool isFrom) async {
    final now     = DateTime.now();
    final current = isFrom
        ? widget.vm.filters.fromDate
        : widget.vm.filters.toDate;
    final picked  = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2023),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryLight,
            onPrimary: AppColors.onPrimaryLight,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    widget.vm.updateFilters(isFrom
        ? widget.vm.filters.copyWith(fromDate: picked)
        : widget.vm.filters.copyWith(toDate: picked));
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final f  = vm.filters;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Row 1 — date range + clear
          Row(
            children: [
              Expanded(
                child: _FilterChip(
                  icon: Icons.calendar_today_outlined,
                  label: f.fromDate != null
                      ? _shortDate(f.fromDate!)
                      : 'From Date',
                  active: f.fromDate != null,
                  onTap: () => _pickDate(true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: Colors.grey.shade400),
              ),
              Expanded(
                child: _FilterChip(
                  icon: Icons.calendar_today_outlined,
                  label: f.toDate != null
                      ? _shortDate(f.toDate!)
                      : 'To Date',
                  active: f.toDate != null,
                  onTap: () => _pickDate(false),
                ),
              ),
              if (f.hasAny) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: vm.clearFilters,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.filter_alt_off_outlined,
                        size: 16, color: Colors.red.shade400),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Row 2 — Method + Status dropdowns
          Row(
            children: [
              Expanded(
                child: _MethodDropdown(
                  value: f.method,
                  onChanged: (m) => vm.updateFilters(m == null
                      ? f.copyWith(clearMethod: true)
                      : f.copyWith(method: m)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusDropdown(
                  value: f.status,
                  onChanged: (s) => vm.updateFilters(s == null
                      ? f.copyWith(clearStatus: true)
                      : f.copyWith(status: s)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table — fixed columns, horizontal scroll
// ─────────────────────────────────────────────────────────────────────────────

const double _cDate      = 100.0;
const double _cAmount    = 120.0;
const double _cMethod    = 140.0;
const double _cInvoice   = 110.0;
const double _cStatus    = 100.0;
const double _cRef       = 120.0;
const double _cAction    = 100.0;
const double _rHPad      =  16.0;

double get _tableWidth =>
    _rHPad * 2 +
        _cDate + _cAmount + _cMethod +
        _cInvoice + _cStatus + _cRef + _cAction;

class _TableCard extends StatelessWidget {
  final PaymentHistoryReportViewModel vm;
  const _TableCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  width: _tableWidth,
                  padding: const EdgeInsets.symmetric(
                      horizontal: _rHPad, vertical: 14),
                  color: AppColors.secondaryLight,
                  child: Row(
                    children: const [
                      _TH(label: 'Date',       width: _cDate),
                      _TH(label: 'Amount',     width: _cAmount),
                      _TH(label: 'Method',     width: _cMethod),
                      _TH(label: 'Invoice #',  width: _cInvoice),
                      _TH(label: 'Status',     width: _cStatus),
                      _TH(label: 'Reference',  width: _cRef),
                      _TH(label: 'Action', width: _cAction),
                    ],
                  ),
                ),

                // Table-loading spinner (filter change)
                if (vm.isTableLoading)
                  SizedBox(
                    width: _tableWidth,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryLight),
                      ),
                    ),
                  )

                // Empty state
                else if (vm.items.isEmpty)
                  SizedBox(
                    width: _tableWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text('No payments match your filters',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  )

                // Data rows
                else
                  ...List.generate(
                    vm.items.length,
                        (i) => _TableRow(
                      item:   vm.items[i],
                      isEven: i % 2 == 0,
                      isLast: i == vm.items.length - 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  final double width;
  const _TH({required this.label, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(label,
          style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12)),
    );
  }
}

class _TableRow extends StatelessWidget {
  final PaymentHistoryItem item;
  final bool isEven;
  final bool isLast;
  const _TableRow({
    required this.item,
    required this.isEven,
    required this.isLast,
  });

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaymentDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = item.method;
    final s = item.status;

    return Container(
      width: _tableWidth,
      padding: const EdgeInsets.symmetric(
          horizontal: _rHPad, vertical: 16),
      decoration: BoxDecoration(
        color: isEven ? AppColors.surfaceLight : const Color(0xFFF7F8FA),
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Date
          SizedBox(
            width: _cDate,
            child: Text(_shortDate(item.date),
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey.shade600)),
          ),

          // Amount
          SizedBox(
            width: _cAmount,
            child: Text(item.formattedAmount,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackgroundLight)),
          ),

          // Method chip
          SizedBox(
            width: _cMethod,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: m.bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(m.icon, size: 13, color: m.color),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(m.label,
                      style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onBackgroundLight,
                          fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),

          // Invoice ref
          SizedBox(
            width: _cInvoice,
            child: Text(item.invoiceRef,
                style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey.shade600)),
          ),

          // Status chip
          SizedBox(
            width: _cStatus,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: s.bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(s.label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: s.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ),
          ),

          // Reference
          SizedBox(
            width: _cRef,
            child: Text(item.reference,
                style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey.shade600,
                    fontFamily: 'monospace')),
          ),

          // Action
          SizedBox(
            width: _cAction,
            child: _PHActionBtn(
              label: 'View',
              icon: Icons.visibility_outlined,
              onTap: () => _showDetail(context),
            ),
          ),
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Payment detail bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentDetailSheet extends StatelessWidget {
  final PaymentHistoryItem item;
  const _PaymentDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final m = item.method;
    final s = item.status;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: m.bgColor,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(m.icon, size: 20, color: m.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.invoiceRef,
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryLight)),
                    Text(_shortDate(item.date),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: s.bgColor,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(s.label,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: s.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),

          _PDRow('Amount',     item.formattedAmount,
              valueColor: AppColors.secondaryLight),
          _PDRow('Method',     m.label),
          _PDRow('Reference',  item.reference),
          _PDRow('Invoice Ref', item.invoiceRef),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Close',
              backgroundColor: AppColors.primaryLight,
              textColor: AppColors.onPrimaryLight,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PDRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _PDRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.onBackgroundLight)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment history action button — used in table rows
// ─────────────────────────────────────────────────────────────────────────────

class _PHActionBtn extends StatelessWidget {
  final String     label;
  final IconData   icon;
  final VoidCallback onTap;
  final bool       isSecondary;

  const _PHActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSecondary
              ? AppColors.backgroundLight
              : AppColors.primaryLight.withOpacity(0.15),
          borderRadius: BorderRadius.circular(7),
          border: isSecondary
              ? Border.all(color: Colors.grey.shade300)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 11,
                color: isSecondary
                    ? Colors.grey.shade600
                    : AppColors.secondaryLight),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSecondary
                    ? Colors.grey.shade600
                    : AppColors.secondaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary stats section
// ─────────────────────────────────────────────────────────────────────────────

class _SummarySection extends StatelessWidget {
  final PaymentHistorySummary summary;
  const _SummarySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  size: 15, color: AppColors.secondaryLight),
            ),
            const SizedBox(width: 8),
            Text('Summary Stats',
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackgroundLight)),
          ],
        ),
        const SizedBox(height: 12),

        // 2×2 method breakdown cards
        Row(
          children: [
            Expanded(child: _MethodCard(
              label: 'By Wallet',
              value: 'SAR ${_fmt(summary.byWallet)}',
              icon: PaymentMethod.wallet.icon,
              color: PaymentMethod.wallet.color,
              bgColor: PaymentMethod.wallet.bgColor,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MethodCard(
              label: 'By Card',
              value: 'SAR ${_fmt(summary.byCard)}',
              icon: PaymentMethod.creditCard.icon,
              color: PaymentMethod.creditCard.color,
              bgColor: PaymentMethod.creditCard.bgColor,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MethodCard(
              label: 'By Transfer',
              value: 'SAR ${_fmt(summary.byTransfer)}',
              icon: PaymentMethod.bankTransfer.icon,
              color: PaymentMethod.bankTransfer.color,
              bgColor: PaymentMethod.bankTransfer.bgColor,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MethodCard(
              label: 'By Cash',
              value: 'SAR ${_fmt(summary.byCash)}',
              icon: PaymentMethod.cash.icon,
              color: PaymentMethod.cash.color,
              bgColor: PaymentMethod.cash.bgColor,
            )),
          ],
        ),
        const SizedBox(height: 12),

        // Total paid — full-width dark card
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryLight.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    size: 20, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Paid',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white60)),
                    const SizedBox(height: 2),
                    Text('SAR ${_fmt(summary.totalPaid)}',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        )),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Transactions',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white54, fontSize: 10)),
                  Text('${summary.totalTransactions}',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _MethodCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey.shade500,
                        fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Export button
// ─────────────────────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  const _ExportButton();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PaymentHistoryReportViewModel>();
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Export Report',
        isLoading: vm.isExporting,
        backgroundColor: AppColors.primaryLight,
        textColor: AppColors.onPrimaryLight,
        onPressed: vm.isExporting
            ? () {}
            : () async {
          await vm.exportReport();
          if (!context.mounted) return;
          if (vm.exportError != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(vm.exportError!),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Report exported successfully'),
              backgroundColor: AppColors.secondaryLight,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown widgets  (text color: black)
// ─────────────────────────────────────────────────────────────────────────────

class _MethodDropdown extends StatelessWidget {
  final PaymentMethod? value;
  final ValueChanged<PaymentMethod?> onChanged;
  const _MethodDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: DropdownButtonFormField<PaymentMethod?>(
        value: value,
        isExpanded: true,
        style: AppTextStyles.bodySmall
            .copyWith(color: Colors.black, fontSize: 12),
        dropdownColor: Colors.white,
        decoration: _dropdownDeco('All Methods'),
        items: [
          _ddItem(null, 'All Methods'),
          ...PaymentMethod.values.map((m) => _ddItem(m, m.label)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final PaymentStatus? value;
  final ValueChanged<PaymentStatus?> onChanged;
  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: DropdownButtonFormField<PaymentStatus?>(
        value: value,
        isExpanded: true,
        style: AppTextStyles.bodySmall
            .copyWith(color: Colors.black, fontSize: 12),
        dropdownColor: Colors.white,
        decoration: _dropdownDeco('All Statuses'),
        items: [
          _ddItem(null, 'All Statuses'),
          ...PaymentStatus.values.map((s) => _ddItem(s, s.label)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

DropdownMenuItem<T> _ddItem<T>(T value, String label) =>
    DropdownMenuItem<T>(
      value: value,
      child: Text(label,
          style: AppTextStyles.bodySmall
              .copyWith(color: Colors.black, fontSize: 12),
          overflow: TextOverflow.ellipsis),
    );

InputDecoration _dropdownDeco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: AppTextStyles.bodySmall
      .copyWith(color: Colors.grey.shade400, fontSize: 12),
  isDense: true,
  contentPadding:
  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: Colors.grey.shade300),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide:
    const BorderSide(color: AppColors.primaryLight, width: 1.5),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip (date picker trigger)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryLight.withOpacity(0.12)
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.primaryLight : Colors.grey.shade300,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: active
                    ? AppColors.secondaryLight
                    : Colors.grey.shade500),
            const SizedBox(width: 5),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: active
                          ? AppColors.onBackgroundLight
                          : Colors.grey.shade500,
                      fontWeight:
                      active ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _shortDate(DateTime d) {
  const m = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]}';
}

String _longDate(DateTime d) {
  const m = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

String _fmt(double v) {
  final parts = v.toStringAsFixed(0).split('');
  final buf   = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
    buf.write(parts[i]);
  }
  return buf.toString();
}