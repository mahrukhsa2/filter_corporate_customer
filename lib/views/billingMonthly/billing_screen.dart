import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/billing_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import 'billing_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class MonthlyBillingScreen extends StatelessWidget {
  const MonthlyBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MonthlyBillingViewModel(),
      child: const _BillingBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _BillingBody extends StatelessWidget {
  const _BillingBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonthlyBillingViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          CustomAppBar(title: "Monthly Billing", showBackButton: true,),
          Expanded(
            child: vm.isLoading
                ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryLight))
                : vm.hasError
            // Network / timeout / server error — summary is null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.wifi_off_rounded,
                          size: 60, color: Colors.red.shade300),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Could not load billing data',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackgroundLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vm.errorMessage,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => vm.refresh(context: context),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.onPrimaryLight,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            )
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

// ─────────────────────────────────────────────────────────────────────────────
// Layouts
// ─────────────────────────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final MonthlyBillingViewModel vm;
  const _NarrowLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    final s = vm.summary!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        _OverviewCard(summary: s),
        const SizedBox(height: 16),
        _StatsRow(summary: s),
        const SizedBox(height: 16),
        _InvoiceTable(summary: s),
        const SizedBox(height: 16),
        _PaymentActions(vm: vm, summary: s),
        const SizedBox(height: 16),
        _DownloadButton(summary: s),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  final MonthlyBillingViewModel vm;
  const _WideLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    final s = vm.summary!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                flex: 5,
                child: Column(children: [
                  _OverviewCard(summary: s),
                  const SizedBox(height: 16),
                  _StatsRow(summary: s),
                  const SizedBox(height: 16),
                  _PaymentActions(vm: vm, summary: s),
                  const SizedBox(height: 16),
                  _DownloadButton(summary: s),
                ]),
              ),
              const SizedBox(width: 20),
              // Right column - invoice table
              Expanded(
                flex: 7,
                child: _InvoiceTable(summary: s),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavArrow(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryLight.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? AppColors.secondaryLight : Colors.grey.shade300,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview card  (dark)
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final MonthlyBillingSummary summary;
  const _OverviewCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month label + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  'Monthly Billing – ${summary.monthLabel}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusBadge(status: summary.status),
            ],
          ),
          const SizedBox(height: 16),

          // Total due – big number
          Text('Total Due',
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.white54)),
          const SizedBox(height: 4),
          Text(
            'SAR ${_fmt(summary.totalDue)}',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w900,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: 20),

          // Due date + wallet in a row
          Row(
            children: [
              Expanded(
                child: _OverviewInfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Due Date',
                  value: _formatDate(summary.dueDate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewInfoTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Wallet Balance',
                  value: 'SAR ${_fmt(summary.walletBalance)}',
                  valueColor: AppColors.primaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _OverviewInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(height: 6),
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white54)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row  (paid vs pending mini cards)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final MonthlyBillingSummary summary;
  const _StatsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline_rounded,
            label: 'Paid',
            amount: summary.totalPaid,
            count: summary.paidCount,
            color: Colors.green.shade600,
            bgColor: Colors.green.shade50,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.pending_outlined,
            label: 'Pending',
            amount: summary.totalPending,
            count: summary.pendingCount,
            color: Colors.orange.shade700,
            bgColor: Colors.orange.shade50,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final int count;
  final Color color;
  final Color bgColor;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.count,
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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
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
                Text('$label ($count)',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text('SAR ${_fmt(amount)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice breakdown table
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceTable extends StatelessWidget {
  final MonthlyBillingSummary summary;
  const _InvoiceTable({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;

    return Container(
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
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.list_alt_rounded,
                      size: 16, color: AppColors.secondaryLight),
                ),
                const SizedBox(width: 8),
                Text('Invoice Breakdown',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackgroundLight,
                    )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${summary.invoices.length} invoices',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onPrimaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

          // Table header row
          Container(
            color: AppColors.backgroundLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _TableHeader('Invoice #', flex: 3),
                _TableHeader('Date', flex: 2),
                if (isWide) _TableHeader('Vehicle', flex: 2),
                _TableHeader('Department', flex: 3),
                _TableHeader('Amount', flex: 2, align: TextAlign.right),
                _TableHeader('Status', flex: 2, align: TextAlign.center),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Invoice rows
          ...summary.invoices.asMap().entries.map((entry) {
            final i = entry.key;
            final inv = entry.value;
            final isEven = i % 2 == 0;
            return Column(
              children: [
                Container(
                  color: isEven ? Colors.transparent : AppColors.backgroundLight.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      // Invoice number
                      Expanded(
                        flex: 3,
                        child: Text(
                          inv.invoiceNumber,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                      ),
                      // Date
                      Expanded(
                        flex: 2,
                        child: Text(
                          _shortDate(inv.date),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      // Vehicle (wide only)
                      if (isWide)
                        Expanded(
                          flex: 2,
                          child: Text(
                            inv.vehiclePlate,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.onBackgroundLight,
                            ),
                          ),
                        ),
                      // Department
                      Expanded(
                        flex: 3,
                        child: Text(
                          inv.department,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.onBackgroundLight),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Amount
                      Expanded(
                        flex: 2,
                        child: Text(
                          'SAR ${_fmt(inv.amount)}',
                          textAlign: TextAlign.right,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackgroundLight,
                          ),
                        ),
                      ),
                      // Status chip
                      Expanded(
                        flex: 2,
                        child: Center(child: _InvoiceStatusChip(status: inv.status)),
                      ),
                    ],
                  ),
                ),
                if (entry.key < summary.invoices.length - 1)
                  const Divider(height: 1, color: Color(0xFFF5F5F5)),
              ],
            );
          }),

          // Table footer – total row
          const Divider(height: 1, thickness: 1.5, color: Color(0xFFE0E0E0)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text('Total',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onBackgroundLight,
                      )),
                ),
                Text(
                  'SAR ${_fmt(summary.totalDue)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign align;
  const _TableHeader(this.label,
      {this.flex = 1, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment action buttons
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentActions extends StatelessWidget {
  final MonthlyBillingViewModel vm;
  final MonthlyBillingSummary summary;
  const _PaymentActions({required this.vm, required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.status == BillingPaymentStatus.paid) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                color: Colors.green.shade600, size: 22),
            const SizedBox(width: 10),
            Text('This month has been fully paid',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width > 720;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payment_rounded,
                    size: 16, color: AppColors.secondaryLight),
              ),
              const SizedBox(width: 8),
              Text('Payment Options',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackgroundLight,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),

          // Three buttons – row on wide, column on mobile
          isWide
              ? Row(
            children: [
              Expanded(child: _WalletPayBtn(vm: vm, summary: summary)),
              const SizedBox(width: 10),
              Expanded(child: _BankPayBtn(vm: vm)),
              const SizedBox(width: 10),
              Expanded(child: _PartialPayBtn(vm: vm, summary: summary)),
            ],
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WalletPayBtn(vm: vm, summary: summary),
              const SizedBox(height: 10),
              _BankPayBtn(vm: vm),
              const SizedBox(height: 10),
              _PartialPayBtn(vm: vm, summary: summary),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletPayBtn extends StatelessWidget {
  final MonthlyBillingViewModel vm;
  final MonthlyBillingSummary summary;
  const _WalletPayBtn({required this.vm, required this.summary});

  @override
  Widget build(BuildContext context) {
    final canPay = summary.walletBalance >= summary.totalDue;
    return CustomButton(
      text: 'Pay with Wallet\n(SAR ${_fmt(summary.walletBalance)})',
      isLoading: vm.isProcessing,
      backgroundColor:
      canPay ? AppColors.primaryLight : Colors.grey.shade200,
      textColor:
      canPay ? AppColors.onPrimaryLight : Colors.grey.shade500,
      onPressed: vm.isProcessing || !canPay
          ? () {}
          : () async {
        final ok = await vm.payWithWallet();
        if (!context.mounted) return;
        _showResult(context, ok, 'Wallet payment processed!');
      },
    );
  }
}

class _BankPayBtn extends StatelessWidget {
  final MonthlyBillingViewModel vm;
  const _BankPayBtn({required this.vm});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: vm.isProcessing
          ? null
          : () async {
        final ok = await vm.payWithBank();
        if (!context.mounted) return;
        _showResult(context, ok, 'Bank payment initiated!');
      },
      icon: vm.isProcessing
          ? const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.secondaryLight))
          : const Icon(Icons.account_balance_outlined, size: 18),
      label: Text('Pay with Bank',
          style: AppTextStyles.button.copyWith(
              fontSize: 14, color: AppColors.secondaryLight)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondaryLight,
        side: BorderSide(
            color: AppColors.secondaryLight.withOpacity(0.5), width: 1.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _PartialPayBtn extends StatelessWidget {
  final MonthlyBillingViewModel vm;
  final MonthlyBillingSummary summary;
  const _PartialPayBtn({required this.vm, required this.summary});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: vm.isProcessing
          ? null
          : () => _showPartialDialog(context),
      icon: const Icon(Icons.tune_rounded, size: 18),
      label: Text('Pay Partial',
          style: AppTextStyles.button.copyWith(
              fontSize: 14, color: const Color(0xFF6A1B9A))),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6A1B9A),
        side: const BorderSide(color: Color(0xFF6A1B9A), width: 1.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  void _showPartialDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Partial Payment',
            style: AppTextStyles.h3.copyWith(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Due: SAR ${_fmt(summary.totalDue)}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextFormField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount to Pay (SAR)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primaryLight, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.onPrimaryLight,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final amount = double.tryParse(ctrl.text);
              if (amount == null || amount <= 0) return;
              Navigator.pop(context);
              final ok = await vm.payPartial(amount);
              if (!context.mounted) return;
              _showResult(context, ok,
                  'Partial payment of SAR ${_fmt(amount)} processed!');
            },
            child: Text('Confirm',
                style: AppTextStyles.button
                    .copyWith(fontSize: 14, color: AppColors.onPrimaryLight)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Download all invoices button
// ─────────────────────────────────────────────────────────────────────────────

class _DownloadButton extends StatelessWidget {
  final MonthlyBillingSummary summary;
  const _DownloadButton({required this.summary});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: implement PDF download via document service
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Downloading invoices for ${summary.monthLabel}…'),
            backgroundColor: AppColors.secondaryLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      icon: const Icon(Icons.download_rounded, size: 18),
      label: Text('Download All Invoices',
          style: AppTextStyles.button.copyWith(
              fontSize: 14, color: AppColors.secondaryLight)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondaryLight,
        side: BorderSide(
            color: AppColors.secondaryLight.withOpacity(0.4), width: 1.5),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final BillingPaymentStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;
    switch (status) {
      case BillingPaymentStatus.paid:
        bg = Colors.green.shade600;
        text = Colors.white;
        label = 'Paid';
        break;
      case BillingPaymentStatus.overdue:
        bg = Colors.red.shade600;
        text = Colors.white;
        label = 'Overdue';
        break;
      case BillingPaymentStatus.partial:
        bg = Colors.blue.shade600;
        text = Colors.white;
        label = 'Partial';
        break;
      case BillingPaymentStatus.pending:
      default:
        bg = Colors.orange.shade600;
        text = Colors.white;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: AppTextStyles.bodySmall.copyWith(
              color: text, fontWeight: FontWeight.w700)),
    );
  }
}

class _InvoiceStatusChip extends StatelessWidget {
  final InvoiceStatus status;
  const _InvoiceStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;
    switch (status) {
      case InvoiceStatus.paid:
        bg = Colors.green.shade50;
        text = Colors.green.shade700;
        label = 'Paid';
        break;
      case InvoiceStatus.overdue:
        bg = Colors.red.shade50;
        text = Colors.red.shade700;
        label = 'Overdue';
        break;
      case InvoiceStatus.partial:
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        label = 'Partial';
        break;
      case InvoiceStatus.pending:
      default:
        bg = Colors.orange.shade50;
        text = Colors.orange.shade700;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: AppTextStyles.bodySmall.copyWith(
              color: text, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

void _showResult(BuildContext context, bool success, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(success ? '✅ $msg' : '❌ Something went wrong.'),
    backgroundColor: success ? Colors.green.shade600 : Colors.redAccent,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 3),
  ));
}

String _fmt(double value) {
  final parts = value.toStringAsFixed(0).split('');
  final buf = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
    buf.write(parts[i]);
  }
  return buf.toString();
}

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _shortDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${months[d.month - 1]}';
}