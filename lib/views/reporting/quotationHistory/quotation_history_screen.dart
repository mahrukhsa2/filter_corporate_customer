import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/quotation_history_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import 'quotation_history_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class QuotationHistoryScreen extends StatelessWidget {
  const QuotationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuotationHistoryViewModel(),
      child: const _QHBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _QHBody extends StatelessWidget {
  const _QHBody();

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<QuotationHistoryViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
        CustomAppBar(title: "Quotation History", showBackButton: true,),
          // ── Content ──────────────────────────────────────────────────
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
  final QuotationHistoryViewModel vm;
  const _NarrowLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(child: _FiltersBar(vm: vm)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          sliver: SliverToBoxAdapter(child: _TableCard(vm: vm)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          sliver: SliverToBoxAdapter(
            child: vm.summary != null ? _SummaryCard(summary: vm.summary!) : const SizedBox(),
          ),
        ),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  final QuotationHistoryViewModel vm;
  const _WideLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          sliver: SliverToBoxAdapter(child: _FiltersBar(vm: vm)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _TableCard(vm: vm)),
                const SizedBox(width: 20),
                SizedBox(
                  width: 280,
                  child: vm.summary != null
                      ? _SummaryCard(summary: vm.summary!)
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Filters bar
// ─────────────────────────────────────────────────────────────────────────────

class _FiltersBar extends StatefulWidget {
  final QuotationHistoryViewModel vm;
  const _FiltersBar({required this.vm});

  @override
  State<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends State<_FiltersBar> {
  final _productCtrl = TextEditingController();

  @override
  void dispose() {
    _productCtrl.dispose();
    super.dispose();
  }

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
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: date range + clear ──────────────────────────────────
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
                  onTap: () {
                    _productCtrl.clear();
                    vm.clearFilters();
                  },
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

          // ── Row 2: product search + status + submitted by ──────────────
          Row(
            children: [
              // Product search
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _productCtrl,
                    onChanged: (v) => vm.updateFilters(
                        f.copyWith(productQuery: v)),
                    style: AppTextStyles.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Product/Service',
                      hintStyle: AppTextStyles.bodySmall
                          .copyWith(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 16),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primaryLight, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Status dropdown
              Expanded(
                flex: 2,
                child: _StatusDropdown(
                  value: f.status,
                  onChanged: (s) => vm.updateFilters(s == null
                      ? f.copyWith(clearStatus: true)
                      : f.copyWith(status: s)),
                ),
              ),
              const SizedBox(width: 8),

              // Submitted by dropdown
              Expanded(
                flex: 2,
                child: _SubmittedByDropdown(
                  options: vm.submittedByOptions,
                  value: f.submittedBy,
                  onChanged: (v) => vm.updateFilters(v == null
                      ? f.copyWith(clearSubmittedBy: true)
                      : f.copyWith(submittedBy: v)),
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
// Fixed column widths — every cell (header + row) uses the same value
// so header and data stay perfectly aligned during horizontal scroll.
// ─────────────────────────────────────────────────────────────────────────────

const double _colQuotation   = 120.0;
const double _colDate        = 100.0;
const double _colProduct     = 200.0;
const double _colQty         =  80.0;
const double _colPrice       = 130.0;
const double _colStatus      = 100.0;
const double _colAction      = 110.0;
const double _rowHPad        =  16.0; // horizontal padding each side of row

double get _totalTableWidth =>
    _rowHPad * 2 +
        _colQuotation +
        _colDate +
        _colProduct +
        _colQty +
        _colPrice +
        _colStatus +
        _colAction;

// ─────────────────────────────────────────────────────────────────────────────
// Table card — outer card clips + provides horizontal scroll
// ─────────────────────────────────────────────────────────────────────────────

class _TableCard extends StatelessWidget {
  final QuotationHistoryViewModel vm;
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
      // ClipRRect keeps rounded corners when content scrolls horizontally
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _totalTableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────────────────
                _TableHeader(),

                // ── Empty state ─────────────────────────────────────────
                if (vm.items.isEmpty)
                  SizedBox(
                    width: _totalTableWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text('No quotations match your filters',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ),

                // ── Data rows ───────────────────────────────────────────
                ...List.generate(vm.items.length, (i) => _TableRow(
                  item:   vm.items[i],
                  isEven: i % 2 == 0,
                  isLast: i == vm.items.length - 1,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table header row
// ─────────────────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _totalTableWidth,
      padding: const EdgeInsets.symmetric(
          horizontal: _rowHPad, vertical: 14),
      color: AppColors.secondaryLight,
      child: Row(
        children: const [
          _TH(label: 'Quotation #',      width: _colQuotation),
          _TH(label: 'Date',             width: _colDate),
          _TH(label: 'Product / Service',width: _colProduct),
          _TH(label: 'Qty',              width: _colQty),
          _TH(label: 'Quoted Price',     width: _colPrice),
          _TH(label: 'Status',           width: _colStatus),
          _TH(label: 'Action',           width: _colAction),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header cell — fixed width, no Expanded
// ─────────────────────────────────────────────────────────────────────────────

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
            fontSize: 12,
          )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data row
// ─────────────────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final QuotationHistoryItem item;
  final bool isEven;
  final bool isLast;
  const _TableRow({
    required this.item,
    required this.isEven,
    required this.isLast,
  });

  void _showRejectionReason(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.info_outline_rounded,
              color: Colors.red.shade400, size: 20),
          const SizedBox(width: 8),
          const Text('Rejection Reason'),
        ]),
        content: Text(
          item.rejectionReason ?? 'No reason provided.',
          style:
          AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = item.status;

    return Container(
      width: _totalTableWidth,
      padding: const EdgeInsets.symmetric(
          horizontal: _rowHPad, vertical: 16),
      decoration: BoxDecoration(
        color: isEven
            ? AppColors.surfaceLight
            : const Color(0xFFF7F8FA),
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Quotation #
          SizedBox(
            width: _colQuotation,
            child: Text(item.quotationNumber,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight)),
          ),

          // Date
          SizedBox(
            width: _colDate,
            child: Text(_shortDate(item.date),
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey.shade600)),
          ),

          // Product / Service
          SizedBox(
            width: _colProduct,
            child: Text(item.productService,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onBackgroundLight),
                overflow: TextOverflow.ellipsis),
          ),

          // Qty
          SizedBox(
            width: _colQty,
            child: Text(item.qty,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey.shade600)),
          ),

          // Quoted price
          SizedBox(
            width: _colPrice,
            child: Text(item.formattedPrice,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackgroundLight)),
          ),

          // Status chip
          SizedBox(
            width: _colStatus,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: status.bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status.label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: status.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ),
          ),

          // Action button
          SizedBox(
            width: _colAction,
            child: GestureDetector(
              onTap: () => status == QuotationStatus.rejected
                  ? _showRejectionReason(context)
                  : _showDetails(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: status == QuotationStatus.rejected
                      ? Colors.red.shade50
                      : status == QuotationStatus.pending
                      ? Colors.orange.shade50
                      : AppColors.primaryLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == QuotationStatus.rejected
                      ? 'View Reason'
                      : status == QuotationStatus.pending
                      ? 'Follow Up'
                      : 'View Details',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: status == QuotationStatus.rejected
                        ? Colors.red.shade600
                        : status == QuotationStatus.pending
                        ? Colors.orange.shade700
                        : AppColors.secondaryLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final QuotationHistoryItem item;
  const _DetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                borderRadius: BorderRadius.circular(2),
              ),
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
                child: const Icon(Icons.request_quote_outlined,
                    color: AppColors.secondaryLight, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.quotationNumber,
                        style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.w800)),
                    Text(item.productService,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.grey.shade500)),
                  ],
                ),
              ),
              _StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),

          _DetailRow('Date',         _longDate(item.date)),
          _DetailRow('Quantity',     item.qty),
          _DetailRow('Quoted Price', item.formattedPrice),
          _DetailRow('Submitted By', item.submittedBy),
          if (item.rejectionReason != null)
            _DetailRow('Rejection Reason', item.rejectionReason!,
                valueColor: Colors.red.shade700),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey.shade500)),
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
// Summary stats — individual cards
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final QuotationHistorySummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
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
        ),

        // 2×2 grid
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total',
                value: '${summary.total}',
                icon: Icons.format_list_numbered_rounded,
                color: Colors.blue.shade700,
                bgColor: Colors.blue.shade50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Approved',
                value: '${summary.approved}',
                icon: Icons.check_circle_outline_rounded,
                color: Colors.green.shade700,
                bgColor: Colors.green.shade50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Rejected',
                value: '${summary.rejected}',
                icon: Icons.cancel_outlined,
                color: Colors.red.shade600,
                bgColor: Colors.red.shade50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Pending',
                value: '${summary.pending}',
                icon: Icons.hourglass_top_rounded,
                color: Colors.orange.shade700,
                bgColor: Colors.orange.shade50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Total Quoted Value — full-width dark card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                child: const Icon(Icons.attach_money_rounded,
                    size: 20, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Quoted Value',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white60)),
                    const SizedBox(height: 2),
                    Text('SAR ${_fmt(summary.totalQuotedValue)}',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ExportButton(summary: summary),
        const SizedBox(height: 30),

      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
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
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: AppTextStyles.h3.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    )),
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Export button (reads vm from context)
// ─────────────────────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.summary});
  final QuotationHistorySummary summary;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<QuotationHistoryViewModel>();

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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Report exported successfully'),
            backgroundColor: AppColors.secondaryLight,
            behavior: SnackBarBehavior.floating,
          ));
        },
      ),
    );
  }
}



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
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryLight.withOpacity(0.12)
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.primaryLight
                : Colors.grey.shade300,
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
                      fontWeight: active
                          ? FontWeight.w700
                          : FontWeight.normal,
                      fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final QuotationStatus? value;
  final ValueChanged<QuotationStatus?> onChanged;
  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: DropdownButtonFormField<QuotationStatus?>(
        value: value,
        isExpanded: true,
        style: AppTextStyles.bodySmall.copyWith(color: Colors.black),
        decoration: InputDecoration(
          hintText: 'Status',
          hintStyle: AppTextStyles.bodySmall
              .copyWith(color: Colors.grey.shade400),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 10),
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: AppColors.primaryLight, width: 1.5),
          ),
        ),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text('All Status',
                style:
                AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ),
          ...QuotationStatus.values.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s.label,
                style: AppTextStyles.bodySmall
                    .copyWith(fontSize: 11)),
          )),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _SubmittedByDropdown extends StatelessWidget {
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  const _SubmittedByDropdown({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: DropdownButtonFormField<String?>(
        value: value,
        isExpanded: true,
        style: AppTextStyles.bodySmall.copyWith(color: Colors.black),
        decoration: InputDecoration(
          hintText: 'Submitted By',
          hintStyle: AppTextStyles.bodySmall
              .copyWith(color: Colors.grey.shade400),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 10),
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: AppColors.primaryLight, width: 1.5),
          ),
        ),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text('All',
                style:
                AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ),
          ...options.map((o) => DropdownMenuItem(
            value: o,
            child: Text(o,
                style: AppTextStyles.bodySmall
                    .copyWith(fontSize: 11),
                overflow: TextOverflow.ellipsis),
          )),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final QuotationStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label,
          style: AppTextStyles.bodySmall.copyWith(
              color: status.color, fontWeight: FontWeight.w700)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _shortDate(DateTime d) {
  const m = ['Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day.toString().padLeft(2,'0')} ${m[d.month-1]}';
}

String _longDate(DateTime d) {
  const m = ['Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day} ${m[d.month-1]} ${d.year}';
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