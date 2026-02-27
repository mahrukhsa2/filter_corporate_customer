import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/wallet_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/app_formatters.dart';
import '../../widgets/custom_button.dart';
import 'wallet_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
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

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _WalletBody extends StatelessWidget {
  const _WalletBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WalletViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          const CustomAppBar(title: "Wallet", showBackButton: true,),
          if (vm.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryLight,
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: vm.refresh,
                color: AppColors.primaryLight,
                child: SingleChildScrollView(
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
        _BalanceCard(balance: vm.balance),
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
        _BalanceCard(balance: vm.balance),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _TopUpSection(vm: vm),
            ),
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
// Balance Card
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.secondaryLight,
            Color(0xFF2E323A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'SAR ${_formatAmount(balance)}',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w900,
              fontSize: 36,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    final parts = value.toStringAsFixed(0).split('');
    final buf = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Selector (Mobile only)
// ─────────────────────────────────────────────────────────────────────────────

class _TabSelector extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const _TabSelector({
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Top-up Wallet',
              isSelected: currentIndex == 0,
              onTap: () => onTabChanged(0),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Transaction History',
              isSelected: currentIndex == 1,
              onTap: () => onTabChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
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
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
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
// Top-up Section
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
          icon: Icons.add_card_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick amount buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vm.topUpOptions.map((option) {
                  final isSelected = vm.selectedTopUpOption?.id == option.id;
                  return _TopUpOptionButton(
                    option: option,
                    isSelected: isSelected,
                    onTap: () => vm.selectTopUpOption(option),
                  );
                }).toList(),
              ),

              // Custom amount input (shown when custom option selected)
              if (vm.selectedTopUpOption?.isCustom == true) ...[
                const SizedBox(height: 16),
                _CustomAmountInput(
                  value: vm.customAmount,
                  onChanged: vm.setCustomAmount,
                  onClear: vm.clearCustomAmount,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Payment Methods for Top-up',
          icon: Icons.payment_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: vm.paymentMethods.map((method) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PaymentMethodTile(
                  method: method,
                  isEnabled: vm.canProceedWithTopUp,
                  onTap: () => _handleTopUp(context, vm, method),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _TopUpConfirmationDialog(
        amount: amount,
        paymentMethod: method,
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await vm.processTopUp(method);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Top-up of SAR ${_formatAmount(amount)} successful!'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage.isEmpty 
                ? '❌ Top-up failed' 
                : '❌ ${vm.errorMessage}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatAmount(double value) {
    final parts = value.toStringAsFixed(0).split('');
    final buf = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top-up Option Button
// ─────────────────────────────────────────────────────────────────────────────

class _TopUpOptionButton extends StatelessWidget {
  final TopUpOptionModel option;
  final bool isSelected;
  final VoidCallback onTap;

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
          color: isSelected
              ? AppColors.primaryLight
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryLight
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
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
  final double? value;
  final Function(String) onChanged;
  final VoidCallback onClear;

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
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            EnglishNumberFormatter(),
          ],
          onChanged: widget.onChanged,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Enter amount in SAR',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey.shade400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'SAR',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onBackgroundLight,
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
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryLight,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
  final bool isEnabled;
  final VoidCallback onTap;

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
            color: isEnabled ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isEnabled
                    ? AppColors.primaryLight.withOpacity(0.15)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                method.icon,
                style: const TextStyle(fontSize: 20),
              ),
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
              color: isEnabled ? Colors.grey.shade400 : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top-up Confirmation Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _TopUpConfirmationDialog extends StatelessWidget {
  final double amount;
  final PaymentMethodModel paymentMethod;

  const _TopUpConfirmationDialog({
    required this.amount,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primaryLight,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Confirm Top-up',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConfirmDetailRow(
            label: 'Amount',
            value: 'SAR ${_formatAmount(amount)}',
            isHighlight: true,
          ),
          const SizedBox(height: 12),
          _ConfirmDetailRow(
            label: 'Payment Method',
            value: paymentMethod.name,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You will be redirected to complete the payment',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.onPrimaryLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Confirm',
            style: AppTextStyles.button.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _formatAmount(double value) {
    final parts = value.toStringAsFixed(0).split('');
    final buf = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }
}

class _ConfirmDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

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
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isHighlight
                ? AppColors.primaryLight
                : AppColors.onBackgroundLight,
            fontWeight: FontWeight.w800,
          ),
        ),
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
        icon: Icons.receipt_long_outlined,
        child: const _EmptyTransactions(),
      );
    }

    return _SectionCard(
      title: 'Recent Transactions',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: transactions.map((transaction) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TransactionTile(transaction: transaction),
          );
        }).toList(),
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
      onTap: () => _showTransactionDetails(context, transaction),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCredit
                    ? AppColors.successGreen.withOpacity(0.15)
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isCredit ? AppColors.successGreen : Colors.red.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Description & Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackgroundLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.formattedDate,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.formattedAmount,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isCredit
                        ? AppColors.successGreen
                        : Colors.red.shade600,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!isCredit && transaction.invoiceNumber != null)
                  Text(
                    '[View]',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryLight,
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

  void _showTransactionDetails(
    BuildContext context,
    WalletTransactionModel transaction,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primaryLight,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Transaction Details',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(label: 'Description', value: transaction.description),
            _DetailRow(label: 'Date', value: transaction.formattedDate),
            _DetailRow(label: 'Amount', value: transaction.formattedAmount),
            _DetailRow(
              label: 'Type',
              value: transaction.type == TransactionType.credit
                  ? 'Credit (Added)'
                  : 'Debit (Spent)',
            ),
            if (transaction.invoiceNumber != null)
              _DetailRow(label: 'Invoice', value: transaction.invoiceNumber!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Close',
                onPressed: () => Navigator.pop(ctx),
                backgroundColor: AppColors.secondaryLight,
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty Transactions State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No Transactions Yet',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your transaction history will appear here',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────────────────────────────────────

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
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onBackgroundLight,
                ),
              ),
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
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onBackgroundLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
