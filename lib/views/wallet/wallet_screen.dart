import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../models/wallet_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_alert.dart';
import 'wallet_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/Wallet/wallet_screen.dart
//
// Changes from dummy version:
//   1. onRefresh passes context so AppAlert shows on network errors
//   2. Error state (first load failure) shows retry button instead of
//      blank screen
//   3. processTopUp success/fail uses AppAlert.snackbar for consistency
// ─────────────────────────────────────────────────────────────────────────────

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WalletViewModel(),
      child: const _WalletBody(),
    );
  }
}

class _WalletBody extends StatelessWidget {
  const _WalletBody();

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<WalletViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          const CustomAppBar(title: 'Wallet', showBackButton: true),

          // ── Loading ────────────────────────────────────────────────────
          if (vm.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryLight),
              ),
            )

          // ── Error (first load failed, no stale data) ───────────────────
          else if (vm.loadStatus == WalletLoadStatus.error)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load wallet.\nPull down to retry.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => vm.refresh(context: context),
                      icon:  const Icon(Icons.refresh_rounded, size: 18),
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

          // ── Loaded (or stale data still visible) ───────────────────────
          else
            Expanded(
              child: RefreshIndicator(
                // ← context passed so AppAlert shows on pull-to-refresh errors
                onRefresh: () => vm.refresh(context: context),
                color:     AppColors.primaryLight,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 24 : 16,
                    20,
                    isWide ? 24 : 16,
                    40,
                  ),
                  child: isWide
                      ? _WideLayout(vm: vm)
                      : _NarrowLayout(vm: vm),
                ),
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
  final WalletViewModel vm;
  const _NarrowLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BalanceCard(vm: vm),
        const SizedBox(height: 20),
        _TabSelector(
          currentIndex: vm.currentTabIndex,
          onTabChanged: vm.setTabIndex,
        ),
        const SizedBox(height: 20),
        if (vm.currentTabIndex == 0)
          _TopUpSection(vm: vm)
        else
          _TransactionHistorySection(transactions: vm.transactions),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  final WalletViewModel vm;
  const _WideLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BalanceCard(vm: vm),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _TopUpSection(vm: vm)),
            const SizedBox(width: 24),
            Expanded(
              flex: 6,
              child: _TransactionHistorySection(transactions: vm.transactions),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Balance Card — now shows live API data including total_topups / total_spent
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final WalletViewModel vm;
  const _BalanceCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondaryLight, Color(0xFF2E323A)],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primaryLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Current Balance',
                style: AppTextStyles.bodyMedium.copyWith(
                  color:      Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Balance
          Text(
            '${vm.currency} ${_fmt(vm.balance)}',
            style: AppTextStyles.h1.copyWith(
              color:      AppColors.primaryLight,
              fontWeight: FontWeight.w900,
              fontSize:   36,
            ),
          ),
          const SizedBox(height: 16),

          // Stats row: total topups + total spent
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Total Top-ups',
                  value: '${vm.currency} ${_fmt(vm.totalTopups)}',
                  icon:  Icons.arrow_downward_rounded,
                  color: Colors.greenAccent.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  label: 'Total Spent',
                  value: '${vm.currency} ${_fmt(vm.totalSpent)}',
                  icon:  Icons.arrow_upward_rounded,
                  color: Colors.redAccent.shade200,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color:    Colors.white54,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color:      Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Selector (mobile only)
// ─────────────────────────────────────────────────────────────────────────────

class _TabSelector extends StatelessWidget {
  final int            currentIndex;
  final Function(int)  onTabChanged;
  const _TabSelector({required this.currentIndex, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label:      'Top-up Wallet',
              isSelected: currentIndex == 0,
              onTap:      () => onTabChanged(0),
            ),
          ),
          Expanded(
            child: _TabButton(
              label:      'Transaction History',
              isSelected: currentIndex == 1,
              onTap:      () => onTabChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String       label;
  final bool         isSelected;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:        isSelected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected
                ? AppColors.onPrimaryLight
                : Colors.grey.shade600,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top-up Section (unchanged from dummy — processTopUp is still local)
// ─────────────────────────────────────────────────────────────────────────────

class _TopUpSection extends StatelessWidget {
  final WalletViewModel vm;
  const _TopUpSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Top-up Options',
          icon:  Icons.add_card_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing:    8,
                runSpacing: 8,
                children: vm.topUpOptions.map((option) {
                  final isSelected = vm.selectedTopUpOption?.id == option.id;
                  return _TopUpOptionButton(
                    option:     option,
                    isSelected: isSelected,
                    onTap:      () => vm.selectTopUpOption(option),
                  );
                }).toList(),
              ),
              if (vm.selectedTopUpOption?.isCustom == true) ...[
                const SizedBox(height: 16),
                _CustomAmountInput(
                  value:     vm.customAmount,
                  onChanged: vm.setCustomAmount,
                  onClear:   vm.clearCustomAmount,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Payment Methods for Top-up',
          icon:  Icons.payment_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: vm.paymentMethods.map((method) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PaymentMethodTile(
                  method:    method,
                  isEnabled: vm.canProceedWithTopUp,
                  onTap:     () => _handleTopUp(context, vm, method),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _handleTopUp(
      BuildContext context,
      WalletViewModel vm,
      PaymentMethodModel method,
      ) async {
    if (!vm.canProceedWithTopUp) return;

    final amount = vm.selectedTopUpOption!.isCustom
        ? vm.customAmount!
        : vm.selectedTopUpOption!.amount;

    if (method.id == 'pm1') {
      // Bank Transfer — show bank details + screenshot upload sheet
      await showModalBottomSheet(
        context:          context,
        isScrollControlled: true,
        backgroundColor:  Colors.transparent,
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: _BankTransferSheet(amount: amount, method: method),
        ),
      );
    } else {
      // Other methods not yet available
      showModalBottomSheet(
        context:         context,
        backgroundColor: Colors.transparent,
        builder: (_) => _ComingSoonSheet(method: method),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top-up Option Button
// ─────────────────────────────────────────────────────────────────────────────

class _TopUpOptionButton extends StatelessWidget {
  final TopUpOptionModel option;
  final bool             isSelected;
  final VoidCallback     onTap;
  const _TopUpOptionButton({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color:      AppColors.primaryLight.withOpacity(0.3),
              blurRadius: 8,
              offset:     const Offset(0, 3),
            ),
          ]
              : null,
        ),
        child: Text(
          option.displayAmount,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected
                ? AppColors.onPrimaryLight
                : AppColors.onBackgroundLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Amount Input
// ─────────────────────────────────────────────────────────────────────────────

class _CustomAmountInput extends StatefulWidget {
  final double?          value;
  final Function(String) onChanged;
  final VoidCallback     onClear;
  const _CustomAmountInput({
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_CustomAmountInput> createState() => _CustomAmountInputState();
}

class _CustomAmountInputState extends State<_CustomAmountInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null ? widget.value!.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Custom Amount',
          style: AppTextStyles.bodySmall.copyWith(
            color:      Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller:      _controller,
          keyboardType:    TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged:       widget.onChanged,
          style:           AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText:  'Enter amount in SAR',
            hintStyle: AppTextStyles.bodyMedium
                .copyWith(color: Colors.grey.shade400),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'SAR',
                style: AppTextStyles.bodyMedium.copyWith(
                  color:      AppColors.onBackgroundLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            suffixIcon: widget.value != null
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey.shade500),
              onPressed: () {
                _controller.clear();
                widget.onClear();
              },
            )
                : null,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:   BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: AppColors.primaryLight, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Method Tile
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethodModel method;
  final bool               isEnabled;
  final VoidCallback        onTap;
  const _PaymentMethodTile({
    required this.method,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.backgroundLight
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? Colors.grey.shade300
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width:  40,
              height: 40,
              decoration: BoxDecoration(
                color: isEnabled
                    ? AppColors.primaryLight.withOpacity(0.15)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(method.icon,
                  style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isEnabled
                      ? AppColors.onBackgroundLight
                      : Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isEnabled
                  ? Colors.grey.shade400
                  : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}

// _TopUpConfirmationDialog removed — replaced by _BankTransferSheet and _ComingSoonSheet

class _ConfirmDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool   isHighlight;
  const _ConfirmDetailRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodyMedium.copyWith(
              color:      Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            )),
        Text(value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isHighlight
                  ? AppColors.primaryLight
                  : AppColors.onBackgroundLight,
              fontWeight: FontWeight.w800,
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction History Section
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionHistorySection extends StatelessWidget {
  final List<WalletTransactionModel> transactions;
  const _TransactionHistorySection({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return _SectionCard(
        title: 'Recent Transactions',
        icon:  Icons.receipt_long_outlined,
        child: const _EmptyTransactions(),
      );
    }
    return _SectionCard(
      title: 'Recent Transactions',
      icon:  Icons.receipt_long_outlined,
      child: Column(
        children: transactions
            .map((tx) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child:   _TransactionTile(transaction: tx),
        ))
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction Tile
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final WalletTransactionModel transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width:  40,
              height: 40,
              decoration: BoxDecoration(
                color: isCredit
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isCredit
                    ? Colors.green.shade600
                    : Colors.red.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Description + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color:      AppColors.onBackgroundLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.formattedDate,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Amount + invoice link
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.formattedAmount,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isCredit
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (transaction.status != null)
                  _StatusBadge(status: transaction.status!),
                if (!isCredit && transaction.invoiceNumber != null)
                  Text(
                    '[Invoice]',
                    style: AppTextStyles.bodySmall.copyWith(
                      color:      AppColors.primaryLight,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    color: AppColors.primaryLight, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Transaction Details',
                      style: AppTextStyles.h3
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(label: 'Description', value: transaction.description),
            _DetailRow(label: 'Date',        value: transaction.formattedDate),
            _DetailRow(label: 'Amount',      value: transaction.formattedAmount),
            _DetailRow(
              label: 'Type',
              value: transaction.type == TransactionType.credit
                  ? 'Credit (Added)'
                  : 'Debit (Spent)',
            ),
            if (transaction.invoiceNumber != null)
              _DetailRow(label: 'Invoice', value: transaction.invoiceNumber!),
            if (transaction.referenceNumber != null)
              _DetailRow(label: 'Reference', value: transaction.referenceNumber!),
            if (transaction.status != null)
              _DetailRow(label: 'Status', value: transaction.status!.toUpperCase()),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text:            'Close',
                onPressed:       () => Navigator.pop(context),
                backgroundColor: AppColors.secondaryLight,
                textColor:       Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty Transactions
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No Transactions Yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color:      Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your transaction history will appear here',
            style: AppTextStyles.bodySmall
                .copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String   title;
  final IconData icon;
  final Widget   child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:        AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.secondaryLight),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color:      AppColors.onBackgroundLight,
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                  color:      Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                )),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color:      AppColors.onBackgroundLight,
                )),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// Bank Transfer Sheet
// Shows dummy bank details + screenshot picker + confirms via API
// ─────────────────────────────────────────────────────────────────────────────

class _BankTransferSheet extends StatefulWidget {
  final double             amount;
  final PaymentMethodModel method;
  const _BankTransferSheet({required this.amount, required this.method});

  @override
  State<_BankTransferSheet> createState() => _BankTransferSheetState();
}

class _BankTransferSheetState extends State<_BankTransferSheet> {
  File?  _screenshot;
  bool   _uploading = false;

  // ── Dummy bank details — update when super admin provides real account ──
  static const _bankName    = 'Al Rajhi Bank';
  static const _accountName = 'Filter Auto Services Co.';
  static const _accountNo   = '1234567890';
  static const _iban        = 'SA44 2000 0001 2345 6789 0123';

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source:    ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _screenshot = File(picked.path));
    }
  }

  Future<void> _submit() async {
    final vm = context.read<WalletViewModel>();
    setState(() => _uploading = true);

    final success = await vm.processTopUp(
      amount:        widget.amount,
      paymentMethod: widget.method,
      context:       context,
    );

    if (!mounted) return;
    setState(() => _uploading = false);

    if (success) {
      Navigator.pop(context);
      AppAlert.snackbar(
        context,
        message:   '✅ Top-up of SAR ${_fmt(widget.amount)} submitted! Pending approval.',
        isSuccess: true,
      );
    }
    // Error already shown by VM via AppAlert.apiError
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final vm          = context.watch<WalletViewModel>();
    final isProcessing = vm.isProcessingTopUp || _uploading;

    return Container(
      margin:  const EdgeInsets.symmetric(horizontal: 0),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:        AppColors.primaryLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_outlined,
                        color: AppColors.primaryLight, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bank Transfer Top-up',
                      style: AppTextStyles.h3.copyWith(
                        color:      Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize:   17,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Amount badge ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color:        AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Transfer Amount: SAR ${_fmt(widget.amount)}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color:      Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Bank details card ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:        AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(14),
                      border:       Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_outlined,
                                color: AppColors.primaryLight, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Transfer to this account',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color:      AppColors.onBackgroundLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        const SizedBox(height: 14),
                        _BankDetailRow(label: 'Bank Name',    value: _bankName),
                        _BankDetailRow(label: 'Account Name', value: _accountName),
                        _BankDetailRow(label: 'Account No.',  value: _accountNo, copyable: true),
                        _BankDetailRow(label: 'IBAN',         value: _iban,      copyable: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Screenshot picker ──────────────────────────────────
                  GestureDetector(
                    onTap: _pickScreenshot,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:        _screenshot != null
                            ? Colors.green.shade50
                            : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _screenshot != null
                              ? Colors.green.shade300
                              : Colors.grey.shade300,
                          width: _screenshot != null ? 1.5 : 1,
                        ),
                      ),
                      child: _screenshot != null
                          ? Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _screenshot!,
                              width:  56,
                              height: 56,
                              fit:    BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Screenshot attached',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color:      Colors.green.shade700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Tap to change',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.check_circle_rounded,
                              color: Colors.green.shade500, size: 22),
                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file_outlined,
                              color: Colors.grey.shade400, size: 28),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload Payment Screenshot',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:      AppColors.onBackgroundLight,
                                ),
                              ),
                              Text(
                                'Tap to select from gallery',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Note about approval
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border:       Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your balance will be updated once the transfer is verified.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color:      Colors.amber.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Submit button ──────────────────────────────────────
                  CustomButton(
                    text:            isProcessing
                        ? 'Submitting...'
                        : "I've Made the Transfer",
                    isLoading:       isProcessing,
                    onPressed:       isProcessing ? () {} : _submit,
                    backgroundColor: AppColors.secondaryLight,
                    textColor:       Colors.white,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bank Detail Row with optional copy button
// ─────────────────────────────────────────────────────────────────────────────

class _BankDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool   copyable;
  const _BankDetailRow({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color:      Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color:      AppColors.onBackgroundLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:  Text('$label copied'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Icon(Icons.copy_outlined,
                  size: 16, color: AppColors.primaryLight),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coming Soon Sheet (Credit Card / Apple Pay)
// ─────────────────────────────────────────────────────────────────────────────

class _ComingSoonSheet extends StatelessWidget {
  final PaymentMethodModel method;
  const _ComingSoonSheet({required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(method.icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            method.name,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'This payment method is coming soon. Please use Bank Transfer for now.',
          textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text:            'Got it',
              onPressed:       () => Navigator.pop(context),
              backgroundColor: AppColors.primaryLight,
              textColor:       AppColors.onPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isCompleted = status.toLowerCase() == 'completed';
    final isPending   = status.toLowerCase() == 'pending';
    final color = isCompleted
        ? Colors.green.shade600
        : isPending
        ? Colors.orange.shade600
        : Colors.red.shade600;
    final bg = isCompleted
        ? Colors.green.shade50
        : isPending
        ? Colors.orange.shade50
        : Colors.red.shade50;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.bodySmall.copyWith(
          color:      color,
          fontWeight: FontWeight.w700,
          fontSize:   9,
        ),
      ),
    );
  }
}

String _fmt(double value) {
  final parts = value.toStringAsFixed(0).split('');
  final buf   = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
    buf.write(parts[i]);
  }
  return buf.toString();
}