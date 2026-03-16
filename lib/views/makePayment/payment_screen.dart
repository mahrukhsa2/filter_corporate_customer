import 'dart:io';
import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/payment_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import 'payment_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point – accepts optional route arguments
// ─────────────────────────────────────────────────────────────────────────────

class MakePaymentScreen extends StatelessWidget {
  final double? totalAmount;
  final String? invoiceRef;

  const MakePaymentScreen({
    super.key,
    this.totalAmount,
    this.invoiceRef,
  });

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Display fields
    final amount = totalAmount ?? (args?['totalAmount'] as double?) ?? 0.0;
    final ref    = invoiceRef  ?? (args?['invoiceRef']  as String?) ?? 'Service Booking';

    // Booking context — passed from booking screen, required for payment API body
    final branchId      = (args?['branchId']      as String?) ?? '';
    final vehicleId     = (args?['vehicleId']      as String?) ?? '';
    final departmentId  = (args?['departmentId']   as String?) ?? '';
    final notes         = (args?['notes']          as String?) ?? '';
    final payFromWallet = (args?['payFromWallet']  as bool?)   ?? false;
    final bookedForRaw  =  args?['bookedFor'];
    final bookedFor     = bookedForRaw is DateTime
        ? bookedForRaw
        : (bookedForRaw is String
        ? DateTime.tryParse(bookedForRaw) ?? DateTime.now()
        : DateTime.now());

    return ChangeNotifierProvider(
      create: (_) => MakePaymentViewModel(
        totalAmount:          amount,
        invoiceRef:           ref,
        branchId:             branchId,
        vehicleId:            vehicleId,
        departmentId:         departmentId,
        bookedFor:            bookedFor,
        notes:                notes,
        initialPayFromWallet: payFromWallet,
      ),
      child: const _PaymentBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentBody extends StatelessWidget {
  const _PaymentBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MakePaymentViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          CustomAppBar(title: "Make Payment", showBackButton: true,),
          Expanded(
            child: vm.isLoading
                ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryLight))
                : (vm.isSuccess || vm.isSkipped)
                ? _ReceiptView(vm: vm)
                : isWide
                ? _WideLayout(vm: vm)
                : _NarrowLayout(vm: vm),
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
  final MakePaymentViewModel vm;
  const _NarrowLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AmountSummaryCard(vm: vm),
          const SizedBox(height: 16),
          _PaymentMethodSection(vm: vm),
          const SizedBox(height: 16),
          if (vm.showWalletTopUp) ...[
            _WalletTopUpSection(vm: vm),
            const SizedBox(height: 16),
          ],
          _PaymentBreakdown(vm: vm),
          const SizedBox(height: 24),
          _ConfirmButton(vm: vm),
        ],
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  final MakePaymentViewModel vm;
  const _WideLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left – method selection
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PaymentMethodSection(vm: vm),
                if (vm.showWalletTopUp) ...[
                  const SizedBox(height: 16),
                  _WalletTopUpSection(vm: vm),
                ],
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Right – summary + confirm
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AmountSummaryCard(vm: vm),
                const SizedBox(height: 16),
                _PaymentBreakdown(vm: vm),
                const SizedBox(height: 24),
                _ConfirmButton(vm: vm),

              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Amount summary card (dark)
// ─────────────────────────────────────────────────────────────────────────────

class _AmountSummaryCard extends StatelessWidget {
  final MakePaymentViewModel vm;
  const _AmountSummaryCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final s = vm.summary!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.invoiceRef,
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.white60, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text('Amount to Pay',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white54)),
          const SizedBox(height: 4),
          Text('SAR ${_fmt(s.totalAmount)}',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w900,
                fontSize: 36,
              )),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _DarkInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _DarkInfoTile({
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
          Icon(icon, size: 15, color: Colors.white38),
          const SizedBox(height: 6),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.bodySmall.copyWith(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment method selection
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentMethodSection extends StatelessWidget {
  final MakePaymentViewModel vm;
  const _PaymentMethodSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Available Payment Methods',
      icon: Icons.payment_rounded,
      child: Column(
        children: PaymentMethod.values.map((method) {
          final isSelected = vm.selectedMethod == method;
          final isWalletAndInsufficient = method == PaymentMethod.wallet &&
              (vm.summary?.walletBalance ?? 0) < (vm.summary?.totalAmount ?? 0);
          final isDisabled  = method == PaymentMethod.onlineCard;
          final isMonthly   = method == PaymentMethod.payMonthly;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: isDisabled
                  ? null
                  : isMonthly
                  ? () async {
                // Select it visually first
                vm.selectMethod(method);
              }
                  : () => vm.selectMethod(method),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? Colors.grey.shade50
                      : isSelected
                      ? AppColors.primaryLight.withOpacity(0.12)
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDisabled
                        ? Colors.grey.shade200
                        : isSelected
                        ? AppColors.primaryLight
                        : Colors.grey.shade200,
                    width: isSelected && !isDisabled ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [


                    // Method icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryLight.withOpacity(0.2)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_methodIcon(method),
                          size: 18,
                          color: isSelected
                              ? AppColors.secondaryLight
                              : Colors.grey.shade600),
                    ),
                    const SizedBox(width: 12),

                    // Label + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Title ─────────────────────────────
                                    Text(
                                      method == PaymentMethod.wallet
                                          ? '${method.label} (SAR ${_fmt(vm.summary?.walletBalance ?? 0)})'
                                          : method.label,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onBackgroundLight,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    // ── Badges (stacked vertically) ───────
                                    if (method.isRecommended)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: _Badge(
                                          label: '★ Recommended',
                                          bg: AppColors.primaryLight,
                                          text: AppColors.onPrimaryLight,
                                        ),
                                      ),

                                    if (isDisabled)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: _Badge(
                                          label: 'Coming Soon',
                                          bg: Colors.grey.shade200,
                                          text: Colors.grey.shade600,
                                        ),
                                      ),

                                    if (isWalletAndInsufficient)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: _Badge(
                                          label: 'Insufficient',
                                          bg: Colors.orange.shade50,
                                          text: Colors.orange.shade700,
                                        ),
                                      ),

                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(method.subtitle,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Radio circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primaryLight
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryLight
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                          size: 13, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _methodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_outlined;
      case PaymentMethod.onlineCard:
        return Icons.credit_card_outlined;
      case PaymentMethod.cashAtBranch:
        return Icons.store_outlined;
      case PaymentMethod.payMonthly:
        return Icons.receipt_long;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wallet top-up section (shown for non-wallet methods)
// ─────────────────────────────────────────────────────────────────────────────

class _WalletTopUpSection extends StatefulWidget {
  final MakePaymentViewModel vm;
  const _WalletTopUpSection({required this.vm});

  @override
  State<_WalletTopUpSection> createState() => _WalletTopUpSectionState();
}

class _WalletTopUpSectionState extends State<_WalletTopUpSection> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.vm.walletAmountUsed > 0
            ? widget.vm.walletAmountUsed.toStringAsFixed(0)
            : '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final s = vm.summary!;

    return _SectionCard(
      title: 'Use Wallet for Partial Payment',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use SAR ${_fmt(s.maxWalletUsable)} from wallet',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onBackgroundLight,
                      ),
                    ),
                    Text(
                      'Remaining SAR ${_fmt(vm.remainingAmount)} via ${vm.selectedMethod.label}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              // Custom toggle
              GestureDetector(
                onTap: () {
                  vm.toggleWalletForPartial();
                  if (!vm.useWalletForPartial) {
                    _ctrl.clear();
                  } else {
                    _ctrl.text =
                        s.maxWalletUsable.toStringAsFixed(0);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 26,
                  decoration: BoxDecoration(
                    color: vm.useWalletForPartial
                        ? AppColors.primaryLight
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: vm.useWalletForPartial
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Editable amount (shown when toggle ON)
          if (vm.useWalletForPartial) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 14),
            Text('Wallet amount to use',
                style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ctrl,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'))
              ],
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) vm.setWalletAmount(parsed);
              },
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                prefixText: 'SAR  ',
                prefixStyle: AppTextStyles.bodyMedium
                    .copyWith(color: Colors.grey.shade600),
                suffixText: '/ ${_fmt(s.maxWalletUsable)} max',
                suffixStyle: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey.shade400),
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
              ),
            ),
            const SizedBox(height: 10),

            // Remaining highlight
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Remaining SAR ${_fmt(vm.remainingAmount)} will be paid via ${vm.selectedMethod.label}',
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment breakdown summary
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentBreakdown extends StatelessWidget {
  final MakePaymentViewModel vm;
  const _PaymentBreakdown({required this.vm});

  @override
  Widget build(BuildContext context) {
    final s = vm.summary!;
    final isWalletOnly = vm.selectedMethod == PaymentMethod.wallet;
    final walletUsed = isWalletOnly ? s.maxWalletUsable : vm.walletAmountUsed;
    final remaining = s.remaining(walletUsed);

    return _SectionCard(
      title: 'Payment Breakdown',
      icon: Icons.receipt_outlined,
      child: Column(
        children: [
          _BreakdownRow(
            label: 'Total Amount',
            value: 'SAR ${_fmt(s.totalAmount)}',
            bold: true,
          ),
          const Divider(height: 20, color: Color(0xFFF0F0F0)),
          if (walletUsed > 0)
            _BreakdownRow(
              label: '– Wallet Deduction',
              value: '- SAR ${_fmt(walletUsed)}',
              valueColor: Colors.green.shade600,
            ),
          if (!isWalletOnly && remaining > 0)
            _BreakdownRow(
              label: 'Via ${vm.selectedMethod.label}',
              value: 'SAR ${_fmt(remaining)}',
              valueColor: Colors.blue.shade700,
            ),
          const Divider(height: 20, color: Color(0xFFF0F0F0)),
          _BreakdownRow(
            label: 'You Pay Now',
            value: 'SAR ${_fmt(s.totalAmount)}',
            bold: true,
            valueColor: AppColors.secondaryLight,
          ),
          if (vm.selectedMethod == PaymentMethod.cashAtBranch) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A reference code will be generated after confirmation. Present it at any Filter branch to complete payment.',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (vm.selectedMethod == PaymentMethod.bankTransfer) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bank Transfer Details',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  _IBANRow('Bank', 'Al Rajhi Bank'),
                  _IBANRow('Account Name', 'Filter Auto Services Co.'),
                  _IBANRow('IBAN', 'SA03 8000 0000 6080 1016 7519'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: bold
                    ? AppColors.onBackgroundLight
                    : Colors.grey.shade600,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              )),
        ),
        Text(value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor ?? AppColors.onBackgroundLight,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}

class _IBANRow extends StatelessWidget {
  final String label;
  final String value;
  const _IBANRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:',
                style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirm button
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmButton extends StatefulWidget {
  final MakePaymentViewModel vm;
  const _ConfirmButton({required this.vm});

  @override
  State<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<_ConfirmButton> {
  // Payment proof — picked from gallery via image_picker
  File?   _proofFile;
  String? _proofFileName;

  Future<void> _pickProof() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked == null) return;
      setState(() {
        _proofFile     = File(picked.path);
        _proofFileName = picked.name;
      });
    } catch (e) {
      debugPrint('[PaymentScreen] image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open gallery: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeProof() => setState(() {
    _proofFile     = null;
    _proofFileName = null;
  });

  bool get _proofRequired =>
      widget.vm.selectedMethod == PaymentMethod.bankTransfer;

  bool get _canConfirm =>
      widget.vm.canConfirm && (!_proofRequired || _proofFile != null);

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Proof upload (bank transfer only) ──────────────────────────────
        if (_proofRequired) ...[
          _ProofUploadCard(
            file:       _proofFile,
            fileName:   _proofFileName,
            onPick:     _pickProof,
            onRemove:   _removeProof,
          ),
          const SizedBox(height: 12),
        ],

        // ── Confirm button ────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: vm.selectedMethod == PaymentMethod.payMonthly
                ? 'Place Order (Pay Monthly)'
                : 'Confirm Payment',
            isLoading: vm.isProcessing,
            backgroundColor: _canConfirm
                ? AppColors.primaryLight
                : Colors.grey.shade300,
            textColor: _canConfirm
                ? AppColors.onPrimaryLight
                : Colors.grey.shade500,
            onPressed: vm.isProcessing || !_canConfirm
                ? () {}
                : () async {
              if (vm.selectedMethod == PaymentMethod.payMonthly) {
                // skipPayment sets isSkipped=true → _ReceiptView renders
                // the order confirmation screen. No navigation here.
                await vm.skipPayment(context: context);
              } else {
                await vm.confirmPayment(context: context);
              }
            },
          ),
        ),

        // ── Hint if proof missing ─────────────────────────────────────────
        if (_proofRequired && _proofFileName == null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 13, color: Colors.orange.shade600),
              const SizedBox(width: 5),
              Text(
                'Please attach your payment proof to continue',
                style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.orange.shade600, fontSize: 11),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Proof upload card
// ─────────────────────────────────────────────────────────────────────────────

class _ProofUploadCard extends StatelessWidget {
  final File?        file;
  final String?      fileName;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  const _ProofUploadCard({
    required this.file,
    required this.fileName,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return GestureDetector(
      onTap: hasFile ? null : onPick,
      child: Container(
        decoration: BoxDecoration(
          color: hasFile ? Colors.green.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile ? Colors.green.shade300 : Colors.blue.shade200,
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hasFile
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      hasFile
                          ? Icons.check_circle_outline_rounded
                          : Icons.upload_file_outlined,
                      size: 18,
                      color: hasFile
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasFile ? 'Proof Attached' : 'Attach Payment Proof *',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: hasFile
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasFile
                              ? fileName!
                              : 'Tap to upload screenshot or receipt',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: hasFile
                                ? Colors.green.shade600
                                : Colors.blue.shade500,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (hasFile)
                    GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 14, color: Colors.red.shade400),
                      ),
                    )
                  else
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: Colors.blue.shade400),
                ],
              ),
            ),

            // ── Image thumbnail preview ───────────────────────────────────
            if (hasFile) ...[
              const Divider(height: 1, color: Color(0xFFD0EED4)),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(13)),
                child: Image.file(
                  file!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Receipt view – shown after success
// ─────────────────────────────────────────────────────────────────────────────

class _ReceiptView extends StatelessWidget {
  final MakePaymentViewModel vm;
  const _ReceiptView({required this.vm});

  @override
  Widget build(BuildContext context) {
    final r = vm.receipt!;
    if (r.isMonthlyBilling) return _MonthlyOrderConfirmation(receipt: r);
    return _PaymentReceipt(receipt: r);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Monthly billing — order placed confirmation
// ─────────────────────────────────────────────────────────────────────────────

class _MonthlyOrderConfirmation extends StatelessWidget {
  final PaymentReceiptModel receipt;
  const _MonthlyOrderConfirmation({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
      child: Column(
        children: [
          // ── Icon ────────────────────────────────────────────────────────
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 3),
            ),
            child: const Icon(Icons.pending_actions_rounded,
                size: 52, color: AppColors.secondaryLight),
          ),
          const SizedBox(height: 24),

          Text('Order Placed!',
              style: AppTextStyles.h1.copyWith(
                  color: AppColors.onBackgroundLight,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
            'Your order has been placed successfully.\nWaiting for approval.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // ── Order details card ───────────────────────────────────────────
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card header
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        size: 20, color: AppColors.secondaryLight),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Order Details',
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackgroundLight)),
                  ),
                  // Pending approval badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.schedule_rounded,
                          size: 12, color: AppColors.secondaryLight),
                      const SizedBox(width: 4),
                      Text('Pending Approval',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 16),

                _ReceiptRow('Payment Method', 'Monthly Billing'),
                _ReceiptRow('Billing Cycle',  'Added to current month'),
                _ReceiptRow('Submitted At',   _formatDt(receipt.timestamp)),

                const SizedBox(height: 16),

                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primaryLight.withOpacity(0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.secondaryLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your order is awaiting approval from Filter. '
                              'You will be notified once confirmed. '
                              'The amount will be added to your monthly billing statement.',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.secondaryLight,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Back to Home ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Back to Home',
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (r) => false),
              backgroundColor: AppColors.primaryLight,
              textColor: AppColors.onPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Regular payment — receipt screen
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentReceipt extends StatelessWidget {
  final PaymentReceiptModel receipt;
  const _PaymentReceipt({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        children: [
          // ── Success icon ──────────────────────────────────────────────────
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade300, width: 3),
            ),
            child: Icon(Icons.check_rounded,
                size: 48, color: Colors.green.shade600),
          ),
          const SizedBox(height: 20),
          Text('Payment Confirmed!',
              style: AppTextStyles.h2
                  .copyWith(color: AppColors.onBackgroundLight)),
          const SizedBox(height: 6),
          Text('Your payment has been processed successfully.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: Colors.grey.shade500),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),

          // ── Receipt card ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        size: 20, color: AppColors.secondaryLight),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Payment Receipt',
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackgroundLight)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(r.status,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 16),
                _ReceiptRow('Receipt #',      r.receiptNumber),
                _ReceiptRow('Payment Method', r.method),
                _ReceiptRow('Amount Paid',    'SAR ${_fmt(r.amountPaid)}'),
                if (r.walletUsed > 0)
                  _ReceiptRow('Wallet Used',  'SAR ${_fmt(r.walletUsed)}'),
                _ReceiptRow('Date & Time',    _formatDt(r.timestamp)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Back to Home',
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/', (r) => false),
                    backgroundColor: AppColors.primaryLight,
                    textColor: AppColors.onPrimaryLight,
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

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReceiptRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
// Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard(
      {required this.title, required this.icon, required this.child});

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

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color text;
  const _Badge({required this.label, required this.bg, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: AppTextStyles.bodySmall
              .copyWith(color: text, fontWeight: FontWeight.w700, fontSize: 9)),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmt(double v) {
  final parts = v.toStringAsFixed(0).split('');
  final buf = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
    buf.write(parts[i]);
  }
  return buf.toString();
}

String _formatDt(DateTime d) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  final amPm = d.hour < 12 ? 'AM' : 'PM';
  final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
  return '${d.day} ${months[d.month - 1]} ${d.year}  $hour:$m $amPm';
}