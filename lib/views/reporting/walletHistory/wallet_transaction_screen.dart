import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/wallet_transaction_model.dart';
import '../../../services/invoice_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import 'wallet_transaction_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class WalletTransactionScreen extends StatelessWidget {
  const WalletTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WalletTransactionViewModel(),
      child: const _WTBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _WTBody extends StatelessWidget {
  const _WTBody();

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<WalletTransactionViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          const CustomAppBar(
              title: 'Wallet Transaction History', showBackButton: true),
          Expanded(
            child: vm.isLoading && vm.summary == null
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
  final WalletTransactionViewModel vm;
  const _NarrowLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: vm.summary != null
                ? _BalanceCard(summary: vm.summary!)
                : const SizedBox(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          sliver: SliverToBoxAdapter(child: _FiltersBar(vm: vm)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          sliver: SliverToBoxAdapter(child: _TableCard(vm: vm)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          sliver: SliverToBoxAdapter(
            child: vm.summary != null
                ? _SummarySection(summary: vm.summary!)
                : const SizedBox(),
          ),
        ),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  final WalletTransactionViewModel vm;
  const _WideLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          sliver: SliverToBoxAdapter(
            child: vm.summary != null
                ? _BalanceCard(summary: vm.summary!)
                : const SizedBox(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
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
                      ? _SummarySection(summary: vm.summary!)
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
// Current balance card (prominent, top of screen)
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final WalletSummary summary;
  const _BalanceCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                size: 26, color: AppColors.primaryLight),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Balance',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white60)),
                const SizedBox(height: 2),
                Text('SAR ${_fmt(summary.currentBalance)}',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    )),
              ],
            ),
          ),
          // Top-up shortcut
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/wallet-topup'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded,
                      size: 16, color: AppColors.onPrimaryLight),
                  const SizedBox(width: 4),
                  Text('Top-up',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onPrimaryLight,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filters bar
// ─────────────────────────────────────────────────────────────────────────────

class _FiltersBar extends StatefulWidget {
  final WalletTransactionViewModel vm;
  const _FiltersBar({required this.vm});

  @override
  State<_FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends State<_FiltersBar> {
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
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
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
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
                    _minCtrl.clear();
                    _maxCtrl.clear();
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

          // ── Row 2: type + amount range ─────────────────────────────────
          Row(
            children: [
              // Type dropdown
              Expanded(
                flex: 3,
                child: _TypeDropdown(
                  value: f.type,
                  onChanged: (t) => vm.updateFilters(t == null
                      ? f.copyWith(clearType: true)
                      : f.copyWith(type: t)),
                ),
              ),
              const SizedBox(width: 8),

              // Min amount
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      vm.updateFilters(parsed == null
                          ? f.copyWith(clearMin: true)
                          : f.copyWith(minAmount: parsed));
                    },
                    style: AppTextStyles.bodySmall,
                    decoration: _amountDecoration('Min Amount'),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Max amount
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      vm.updateFilters(parsed == null
                          ? f.copyWith(clearMax: true)
                          : f.copyWith(maxAmount: parsed));
                    },
                    style: AppTextStyles.bodySmall,
                    decoration: _amountDecoration('Max Amount'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _amountDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
      AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade400),
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
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table — fixed-width columns, horizontal scroll
// ─────────────────────────────────────────────────────────────────────────────

const double _colDate        = 100.0;
const double _colDesc        = 230.0;
const double _colAmount      = 120.0;
const double _colType        = 100.0;
const double _colBalance     = 110.0;
const double _colAction      = 110.0;
const double _rowHPad        =  16.0;

double get _totalTableWidth =>
    _rowHPad * 2 +
        _colDate +
        _colDesc +
        _colAmount +
        _colType +
        _colBalance +
        _colAction;

class _TableCard extends StatelessWidget {
  final WalletTransactionViewModel vm;
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
            width: _totalTableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _TableHeader(),

                // Table-only loader — shown while filters are being applied
                if (vm.isTableLoading)
                  SizedBox(
                    width: _totalTableWidth,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryLight,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  )

                // Empty state
                else if (vm.items.isEmpty)
                  SizedBox(
                    width: _totalTableWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text('No transactions match your filters',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  )

                // Rows
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
          _TH(label: 'Date',        width: _colDate),
          _TH(label: 'Description', width: _colDesc),
          _TH(label: 'Amount',      width: _colAmount),
          _TH(label: 'Type',        width: _colType),
          _TH(label: 'Balance After', width: _colBalance),
          _TH(label: 'Action',      width: _colAction),
        ],
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
            fontSize: 12,
          )),
    );
  }
}

class _TableRow extends StatelessWidget {
  final WalletTransaction item;
  final bool isEven;
  final bool isLast;
  const _TableRow({
    required this.item,
    required this.isEven,
    required this.isLast,
  });

  /// Debit → View Invoice (InvoiceService using referenceNumber)
  /// Credit / TopUp → View Receipt (local detail sheet)
  void _handleAction(BuildContext context) {
    if (item.type == WalletTransactionType.debit) {
      // Use referenceNumber if available, fall back to id
      final invoiceId = (item.referenceNumber != null &&
          item.referenceNumber!.isNotEmpty)
          ? item.referenceNumber!
          : item.id;
      InvoiceService.showInvoiceDetails(
        context:   context,
        invoiceId: invoiceId,
      );
    } else {
      // Credit or TopUp → show receipt sheet
      _showDetail(context);
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
    //  backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t      = item.type;
    final isDebit = t == WalletTransactionType.debit;

    return Container(
      width: _totalTableWidth,
      padding: const EdgeInsets.symmetric(
          horizontal: _rowHPad, vertical: 16),
      decoration: BoxDecoration(
        color: isEven ? AppColors.surfaceLight : const Color(0xFFF7F8FA),
        border: isLast
            ? null
            : Border(
            bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Date
          SizedBox(
            width: _colDate,
            child: Text(_shortDate(item.date),
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey.shade600)),
          ),

          // Description
          SizedBox(
            width: _colDesc,
            child: Text(item.description,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onBackgroundLight),
                overflow: TextOverflow.ellipsis),
          ),

          // Amount (coloured)
          SizedBox(
            width: _colAmount,
            child: Text(item.formattedAmount,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDebit
                      ? Colors.red.shade600
                      : Colors.green.shade700,
                  fontWeight: FontWeight.w800,
                )),
          ),

          // Type chip
          SizedBox(
            width: _colType,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: t.bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.icon, size: 11, color: t.color),
                  const SizedBox(width: 4),
                  Text(t.label,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: t.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11)),
                ],
              ),
            ),
          ),

          // Balance after
          SizedBox(
            width: _colBalance,
            child: Text(item.formattedBalance,
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackgroundLight)),
          ),

          // Action — Receipt for credit/topUp, Invoice for debit
          SizedBox(
            width: _colAction,
            child: GestureDetector(
              onTap: () => _handleAction(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: item.type == WalletTransactionType.debit
                      ? AppColors.primaryLight.withOpacity(0.15)
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.type == WalletTransactionType.debit
                          ? Icons.receipt_long_outlined
                          : Icons.receipt_outlined,
                      size: 11,
                      color: item.type == WalletTransactionType.debit
                          ? AppColors.secondaryLight
                          : Colors.green.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.type == WalletTransactionType.debit
                          ? 'Invoice'
                          : 'Receipt',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: item.type == WalletTransactionType.debit
                              ? AppColors.secondaryLight
                              : Colors.green.shade700,
                          fontWeight: FontWeight.w700,
                          fontSize: 11),
                    ),
                  ],
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
  final WalletTransaction item;
  const _DetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final t       = item.type;
    final isDebit = t == WalletTransactionType.debit;

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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(t.icon, color: t.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800)),
                    Text(_longDate(item.date),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Text(
                item.formattedAmount,
                style: AppTextStyles.h3.copyWith(
                  color: isDebit
                      ? Colors.red.shade600
                      : Colors.green.shade700,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),

          _DetailRow('Date',          _longDate(item.date)),
          _DetailRow('Type',          t.label),
          _DetailRow('Amount',        item.formattedAmount),
          _DetailRow('Balance After', item.formattedBalance),
          if (item.referenceNumber != null)
            _DetailRow('Reference',   item.referenceNumber!),
          const SizedBox(height: 20),

          // Download invoice button — shown for debit transactions with reference
          if (isDebit &&
              item.referenceNumber != null &&
              item.referenceNumber!.isNotEmpty) ...[
            OutlinedButton.icon(
              onPressed: () => InvoiceService.downloadInvoiceWithUI(
                context: context,
                invoiceId: item.referenceNumber!,
              ),
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Download Invoice'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondaryLight,
                side: BorderSide(
                    color: AppColors.primaryLight.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
            const SizedBox(height: 10),
          ],
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
  const _DetailRow(this.label, this.value);

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
                    color: AppColors.onBackgroundLight)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary stats section
// ─────────────────────────────────────────────────────────────────────────────

class _SummarySection extends StatelessWidget {
  final WalletSummary summary;
  const _SummarySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final netPositive = summary.netMovement >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
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

        // 2-col grid
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Top-ups',
                value: 'SAR ${_fmt(summary.totalTopUps)}',
                icon: Icons.add_card_rounded,
                color: Colors.blue.shade700,
                bgColor: Colors.blue.shade50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Total Spent',
                value: 'SAR ${_fmt(summary.totalSpent)}',
                icon: Icons.arrow_upward_rounded,
                color: Colors.red.shade600,
                bgColor: Colors.red.shade50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Net movement — full-width card
        Center(
          child:
          SizedBox(
            width: 200,
            child: _StatCard(
              label: 'Net Wallet Movement',
              value:
              '${netPositive ? '+' : '-'}SAR ${_fmt(summary.netMovement.abs())}',
              icon: netPositive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: AppColors.secondaryDark,
              bgColor: AppColors.primaryLight.withOpacity(0.08),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Export buttons
        _ExportButtons(),
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
                    style: AppTextStyles.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    )),
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.grey.shade500,
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
// Export PDF + Excel buttons (reads vm from context)
// ─────────────────────────────────────────────────────────────────────────────

class _ExportButtons extends StatelessWidget {
  const _ExportButtons();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WalletTransactionViewModel>();

    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Export PDF',
            isLoading: vm.isExporting,
            backgroundColor: AppColors.secondaryLight,
            textColor: Colors.white,
            onPressed: vm.isExporting
                ? () {}
                : () async {
              await vm.exportReport('PDF');
              if (!context.mounted) return;
              if (vm.exportError != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(vm.exportError!),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Exported as PDF successfully'),
                  backgroundColor: AppColors.secondaryLight,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            text: 'Export Excel',
            isLoading: vm.isExporting,
            backgroundColor: AppColors.primaryLight,
            textColor: AppColors.onPrimaryLight,
            onPressed: vm.isExporting
                ? () {}
                : () async {
              await vm.exportReport('Excel');
              if (!context.mounted) return;
              if (vm.exportError != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(vm.exportError!),
                  backgroundColor: Colors.red.shade600,
                  behavior: SnackBarBehavior.floating,
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Exported as Excel successfully'),
                  backgroundColor: AppColors.secondaryLight,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable filter widgets
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
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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

class _TypeDropdown extends StatelessWidget {
  final WalletTransactionType? value;
  final ValueChanged<WalletTransactionType?> onChanged;
  const _TypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: DropdownButtonFormField<WalletTransactionType?>(
        value: value,
        isExpanded: true,
        style: AppTextStyles.bodySmall.copyWith(color: Colors.black),
        decoration: InputDecoration(
          hintText: 'All Types',
          hintStyle: AppTextStyles.bodySmall
              .copyWith(color: Colors.black),
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
            child: Text('All Types',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ),
          ...WalletTransactionType.values.map((t) => DropdownMenuItem(
            value: t,
            child: Text(t.label,
                style:
                AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          )),
        ],
        onChanged: onChanged,
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