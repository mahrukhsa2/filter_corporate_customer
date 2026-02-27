import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/monthly_billing_report_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import 'monthly_billing_report_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class MonthlyBillingReportScreen extends StatelessWidget {
  const MonthlyBillingReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MonthlyBillingReportViewModel(),
      child: const _MBBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _MBBody extends StatelessWidget {
  const _MBBody();

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<MonthlyBillingReportViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          const CustomAppBar(
              title: 'Monthly Billing Report', showBackButton: true),
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
  final MonthlyBillingReportViewModel vm;
  const _NarrowLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _pad(16, child: _FiltersBar(vm: vm)),
        if (vm.overview != null)
          _pad(14, child: _OverviewCard(overview: vm.overview!)),
        _pad(14, child: _InvoiceTable(vm: vm)),
        _pad(14, child: _TrendChart(trend: vm.trend, overview: vm.overview)),
        _pad(14, bottom: 32, child: _ActionButtons()),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  final MonthlyBillingReportViewModel vm;
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
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      if (vm.overview != null)
                        _OverviewCard(overview: vm.overview!),
                      const SizedBox(height: 16),
                      _InvoiceTable(vm: vm),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      _TrendChart(trend: vm.trend, overview: vm.overview),
                    ],
                  ),
                ),
              ],
            )),
        _pad(14, h: 24, bottom: 32, child: _ActionButtons()),
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
// Filters bar — Month/Year selector + Status dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _FiltersBar extends StatelessWidget {
  final MonthlyBillingReportViewModel vm;
  const _FiltersBar({required this.vm});

  @override
  Widget build(BuildContext context) {
    final f = vm.filters;

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
      child: Row(
        children: [
          // Month dropdown
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: DropdownButtonFormField<int>(
                value: f.month ?? 2,
                isExpanded: true,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.black, fontSize: 12),
                dropdownColor: Colors.white,
                decoration: _deco('Month'),
                items: vm.availableMonths
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(vm.monthName(m),
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.black, fontSize: 12)),
                        ))
                    .toList(),
                onChanged: (m) =>
                    vm.updateFilters(f.copyWith(month: m ?? f.month)),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Year dropdown
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: DropdownButtonFormField<int>(
                value: f.year ?? 2026,
                isExpanded: true,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.black, fontSize: 12),
                dropdownColor: Colors.white,
                decoration: _deco('Year'),
                items: vm.availableYears
                    .map((y) => DropdownMenuItem(
                          value: y,
                          child: Text('$y',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.black, fontSize: 12)),
                        ))
                    .toList(),
                onChanged: (y) =>
                    vm.updateFilters(f.copyWith(year: y ?? f.year)),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Status dropdown
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: DropdownButtonFormField<BillingInvoiceStatus?>(
                value: f.status,
                isExpanded: true,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.black, fontSize: 12),
                dropdownColor: Colors.white,
                decoration: _deco('All Statuses'),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text('All',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.black, fontSize: 12)),
                  ),
                  ...BillingInvoiceStatus.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.black, fontSize: 12)),
                      )),
                ],
                onChanged: (s) => vm.updateFilters(
                    s == null
                        ? f.copyWith(clearStatus: true)
                        : f.copyWith(status: s)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _deco(String hint) => InputDecoration(
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
// Overview card
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final MonthlyBillingOverview overview;
  const _OverviewCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryLight.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    size: 18, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 10),
              Text('Monthly Billing Summary',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white70)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(overview.monthLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Billed — large hero value
          Text('SAR ${_fmt(overview.totalBilled)}',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w800,
                fontSize: 28,
              )),
          Text('Total Billed',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white54)),
          const SizedBox(height: 16),

          // 2-col grid: Paid | Outstanding
          Row(
            children: [
              Expanded(
                child: _OvStat(
                  label: 'Total Paid',
                  value: 'SAR ${_fmt(overview.totalPaid)}',
                  color: Colors.green.shade300,
                ),
              ),
              Expanded(
                child: _OvStat(
                  label: 'Outstanding',
                  value: 'SAR ${_fmt(overview.outstanding)}',
                  color: Colors.orange.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Divider
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 12),

          // Due date + wallet row
          Row(
            children: [
              const Icon(Icons.event_outlined,
                  size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text('Due: ${_longDate(overview.dueDate)}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white70)),
              const SizedBox(width: 16),
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    'Wallet used: SAR ${_fmt(overview.walletUsed)}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OvStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _OvStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white54)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice table — horizontal scroll, fixed columns
// ─────────────────────────────────────────────────────────────────────────────

const double _cInv    = 110.0;
const double _cDate   =  96.0;
const double _cVeh    = 100.0;
const double _cDept   = 140.0;
const double _cAmt    = 110.0;
const double _cStat   =  96.0;
const double _cAct    = 110.0;
const double _hPad    =  16.0;

double get _tWidth =>
    _hPad * 2 + _cInv + _cDate + _cVeh + _cDept + _cAmt + _cStat + _cAct;

class _InvoiceTable extends StatelessWidget {
  final MonthlyBillingReportViewModel vm;
  const _InvoiceTable({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        _SectionLabel(icon: Icons.list_alt_outlined, title: 'Invoice List'),
        const SizedBox(height: 10),

        Container(
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
                width: _tWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      width: _tWidth,
                      padding: const EdgeInsets.symmetric(
                          horizontal: _hPad, vertical: 14),
                      color: AppColors.secondaryLight,
                      child: Row(children: const [
                        _TH(label: 'Invoice #',   width: _cInv),
                        _TH(label: 'Date',        width: _cDate),
                        _TH(label: 'Vehicle',     width: _cVeh),
                        _TH(label: 'Department',  width: _cDept),
                        _TH(label: 'Amount',      width: _cAmt),
                        _TH(label: 'Status',      width: _cStat),
                        _TH(label: 'Action',      width: _cAct),
                      ]),
                    ),

                    if (vm.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 36, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text('No invoices match your filters',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: Colors.grey.shade400)),
                          ],
                        ),
                      ),

                    ...List.generate(
                      vm.items.length,
                      (i) => _InvoiceRow(
                        invoice: vm.items[i],
                        isEven:  i % 2 == 0,
                        isLast:  i == vm.items.length - 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  final double width;
  const _TH({required this.label, required this.width});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Text(label,
            style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12)),
      );
}

class _InvoiceRow extends StatelessWidget {
  final BillingInvoice invoice;
  final bool isEven;
  final bool isLast;
  const _InvoiceRow({
    required this.invoice,
    required this.isEven,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final s          = invoice.status;
    final isPending  = s == BillingInvoiceStatus.pending;
    final isOverdue  = s == BillingInvoiceStatus.overdue;
    final actionLabel = (isPending || isOverdue) ? 'Pay Now' : 'View';
    final actionColor = (isPending || isOverdue)
        ? Colors.red.shade600
        : AppColors.secondaryLight;
    final actionBg    = (isPending || isOverdue)
        ? Colors.red.shade50
        : AppColors.primaryLight.withOpacity(0.15);

    return Container(
      width: _tWidth,
      padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 16),
      decoration: BoxDecoration(
        color: isEven ? AppColors.surfaceLight : const Color(0xFFF7F8FA),
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _cInv,
            child: Text(invoice.invoiceNumber,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackgroundLight)),
          ),
          SizedBox(
            width: _cDate,
            child: Text(_shortDate(invoice.date),
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey.shade600)),
          ),
          SizedBox(
            width: _cVeh,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(invoice.vehiclePlate,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ),
          ),
          SizedBox(
            width: _cDept,
            child: Text(invoice.department,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: _cAmt,
            child: Text(invoice.formattedAmount,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackgroundLight)),
          ),
          SizedBox(
            width: _cStat,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 4),
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
          SizedBox(
            width: _cAct,
            child: GestureDetector(
              onTap: () => _handleAction(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: actionBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(actionLabel,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: actionColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context) {
    if (invoice.status == BillingInvoiceStatus.pending ||
        invoice.status == BillingInvoiceStatus.overdue) {
      _showPayDialog(context);
    } else {
      _showInvoiceSheet(context);
    }
  }

  void _showPayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payment_rounded,
                color: AppColors.secondaryLight, size: 22),
            const SizedBox(width: 8),
            const Text('Pay Invoice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice: ${invoice.invoiceNumber}',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 4),
            Text('Amount: ${invoice.formattedAmount}',
                style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.onPrimaryLight,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text('Payment initiated for ${invoice.invoiceNumber}'),
                backgroundColor: AppColors.secondaryLight,
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  void _showInvoiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _InvoiceDetailSheet(invoice: invoice),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice detail bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceDetailSheet extends StatelessWidget {
  final BillingInvoice invoice;
  const _InvoiceDetailSheet({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final s = invoice.status;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: AppColors.secondaryLight, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.invoiceNumber,
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800)),
                    Text(_longDate(invoice.date),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: s.bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s.label,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: s.color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 16),
          _DR('Invoice #',   invoice.invoiceNumber),
          _DR('Date',        _longDate(invoice.date)),
          _DR('Vehicle',     invoice.vehiclePlate),
          _DR('Department',  invoice.department),
          _DR('Amount',      invoice.formattedAmount),
          _DR('Status',      s.label),
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

class _DR extends StatelessWidget {
  final String l, v;
  const _DR(this.l, this.v);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(l,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.grey.shade500)),
            ),
            Expanded(
              child: Text(v,
                  style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackgroundLight)),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Monthly trend bar chart (custom painted, no external lib)
// ─────────────────────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  final List<BillingTrendPoint> trend;
  final MonthlyBillingOverview? overview;
  const _TrendChart({required this.trend, required this.overview});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
            icon: Icons.bar_chart_rounded, title: 'Monthly Trend'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
              // Legend
              Row(
                children: [
                  _LegendDot(color: Colors.green.shade400, label: 'Paid'),
                  const SizedBox(width: 16),
                  _LegendDot(
                      color: Colors.orange.shade300, label: 'Pending'),
                ],
              ),
              const SizedBox(height: 16),

              // Bars
              SizedBox(
                height: 140,
                child: LayoutBuilder(builder: (ctx, bc) {
                  final maxVal = trend
                      .map((p) => p.total)
                      .reduce((a, b) => a > b ? a : b);
                  final barW = (bc.maxWidth - (trend.length - 1) * 8) /
                      trend.length;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: trend.asMap().entries.map((e) {
                      final i     = e.key;
                      final point = e.value;
                      final isLast = overview != null &&
                          point.monthLabel ==
                              overview!.monthLabel.split(' ').first;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: i == 0 ? 0 : 4,
                              right: i == trend.length - 1 ? 0 : 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Stacked bar
                              Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Pending portion
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 600),
                                    curve: Curves.easeOutCubic,
                                    width: barW,
                                    height: maxVal > 0
                                        ? 120 * point.pending / maxVal
                                        : 0,
                                    decoration: BoxDecoration(
                                      color: isLast
                                          ? Colors.orange.shade300
                                          : Colors.orange.shade200,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                    ),
                                  ),
                                  // Paid portion
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 600),
                                    curve: Curves.easeOutCubic,
                                    width: barW,
                                    height: maxVal > 0
                                        ? 120 * point.paid / maxVal
                                        : 0,
                                    color: isLast
                                        ? Colors.green.shade500
                                        : Colors.green.shade300,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Month label
                              Text(point.monthLabel,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isLast
                                        ? AppColors.secondaryLight
                                        : Colors.grey.shade500,
                                    fontWeight: isLast
                                        ? FontWeight.w800
                                        : FontWeight.normal,
                                    fontSize: 10,
                                  )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ),
              const SizedBox(height: 10),

              // Current month summary line
              if (overview != null) ...[
                Divider(color: Colors.grey.shade100, height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ChartStat(
                        label: 'Paid',
                        value: 'SAR ${_fmt(overview!.totalPaid)}',
                        color: Colors.green.shade600,
                      ),
                    ),
                    Container(
                        width: 1, height: 28, color: Colors.grey.shade200),
                    Expanded(
                      child: _ChartStat(
                        label: 'Pending',
                        value: 'SAR ${_fmt(overview!.outstanding)}',
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.grey.shade600, fontSize: 11)),
        ],
      );
}

class _ChartStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ChartStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey.shade500, fontSize: 11)),
            Text(value,
                style: AppTextStyles.bodySmall.copyWith(
                    color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons — Download PDF | Download Excel | Pay Outstanding
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonthlyBillingReportViewModel>();

    return Column(
      children: [
        // Export row
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Download PDF',
                isLoading: vm.isExporting,
                backgroundColor: AppColors.secondaryLight,
                textColor: Colors.white,
                onPressed: vm.isExporting
                    ? () {}
                    : () async {
                        await vm.exportReport('PDF');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PDF downloaded'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Download Excel',
                isLoading: vm.isExporting,
                backgroundColor: AppColors.primaryLight,
                textColor: AppColors.onPrimaryLight,
                onPressed: vm.isExporting
                    ? () {}
                    : () async {
                        await vm.exportReport('Excel');
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Excel downloaded'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Pay Outstanding — full width, red accent
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Pay Outstanding',
            isLoading: vm.isPayingOutstanding,
            backgroundColor: const Color(0xFFC62828),
            textColor: Colors.white,
            onPressed: vm.isPayingOutstanding
                ? () {}
                : () => _confirmPayOutstanding(context, vm),
          ),
        ),
      ],
    );
  }

  void _confirmPayOutstanding(
      BuildContext context, MonthlyBillingReportViewModel vm) {
    final outstanding = vm.overview?.outstanding ?? 0;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade600, size: 22),
            const SizedBox(width: 8),
            const Text('Pay Outstanding'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to pay all outstanding invoices.'),
            const SizedBox(height: 8),
            Text(
              'Total: SAR ${_fmt(outstanding)}',
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryLight),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await vm.payOutstanding();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Outstanding payment initiated'),
                backgroundColor: AppColors.secondaryLight,
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: const Text('Confirm & Pay'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: AppColors.secondaryLight),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onBackgroundLight)),
        ],
      );
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
  final s = v.toStringAsFixed(0).split('');
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
