import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import 'price_quotation_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class PriceQuotationScreen extends StatelessWidget {
  const PriceQuotationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PriceQuotationViewModel(),
      child: const _PriceQuotationBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _PriceQuotationBody extends StatelessWidget {
  const _PriceQuotationBody();

  @override
  Widget build(BuildContext context) {
    final vm    = context.watch<PriceQuotationViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          const CustomAppBar(
            title: 'New Price Quotation',
            showBackButton: true,
          ),
          Expanded(
            child: vm.isLoadingProducts
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryLight))
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
  final PriceQuotationViewModel vm;
  const _NarrowLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchBar(vm: vm),
          const SizedBox(height: 16),
          _QuotationTable(vm: vm),
          if (vm.hasItems) ...[
            const SizedBox(height: 16),
            _SavingsSummary(vm: vm),
            const SizedBox(height: 12),
            _WalletLine(balance: vm.walletBalance),
            const SizedBox(height: 20),
            _ActionButtons(vm: vm),
          ],
        ],
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  final PriceQuotationViewModel vm;
  const _WideLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchBar(vm: vm),
          const SizedBox(height: 16),
          if (vm.hasItems)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: _QuotationTable(vm: vm)),
                const SizedBox(width: 20),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SavingsSummary(vm: vm),
                      const SizedBox(height: 12),
                      _WalletLine(balance: vm.walletBalance),
                      const SizedBox(height: 20),
                      _ActionButtons(vm: vm),
                    ],
                  ),
                ),
              ],
            )
          else
            _QuotationTable(vm: vm),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar with dropdown suggestions
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  final PriceQuotationViewModel vm;
  const _SearchBar({required this.vm});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl   = TextEditingController();
  final _focus  = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Search field ─────────────────────────────────────────────────
        TextFormField(
          controller: _ctrl,
          focusNode:  _focus,
          onChanged:  vm.onSearchChanged,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search & Add Product / Service',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
            suffixIcon: vm.searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _ctrl.clear();
                      vm.onSearchChanged('');
                      _focus.unfocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryLight, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),

        // ── Dropdown suggestions ─────────────────────────────────────────
        if (vm.showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: vm.searchResults.map((product) {
                  final isLast = product == vm.searchResults.last;
                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          _ctrl.clear();
                          _focus.unfocus();
                          vm.addProduct(product);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.inventory_2_outlined,
                                    size: 16, color: AppColors.secondaryLight),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        )),
                                    Text('per ${product.unit}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                            color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                              Text(
                                'SAR ${product.marketPrice.toStringAsFixed(2)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SAR ${product.corporatePrice.toStringAsFixed(2)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                            height: 1,
                            color: Colors.grey.shade100,
                            indent: 16,
                            endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quotation table  (header + rows)
// ─────────────────────────────────────────────────────────────────────────────

class _QuotationTable extends StatelessWidget {
  final PriceQuotationViewModel vm;
  const _QuotationTable({required this.vm});

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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header row ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text('Product',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w700)),
                ),
                SizedBox(
                  width: 48,
                  child: Text('Qty',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w700)),
                ),
                SizedBox(
                  width: 80,
                  child: Text('Market\nPrice',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w700)),
                ),
                SizedBox(
                  width: 72,
                  child: Text('Your\nPrice',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 28), // space for ✕
              ],
            ),
          ),

          // ── Empty state ────────────────────────────────────────────────
          if (!vm.hasItems)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.playlist_add_rounded,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text('Search and add products above',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.grey.shade400)),
                ],
              ),
            ),

          // ── Line item rows ──────────────────────────────────────────────
          ...List.generate(vm.lineItems.length, (i) {
            final item = vm.lineItems[i];
            final isLast = i == vm.lineItems.length - 1;
            return Column(
              children: [
                _LineItemRow(
                  item: item,
                  index: i,
                  vm: vm,
                ),
                if (!isLast)
                  Divider(height: 1, color: Colors.grey.shade100),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single line item row
// ─────────────────────────────────────────────────────────────────────────────

class _LineItemRow extends StatefulWidget {
  final QuotationLineItem item;
  final int index;
  final PriceQuotationViewModel vm;

  const _LineItemRow({
    required this.item,
    required this.index,
    required this.vm,
  });

  @override
  State<_LineItemRow> createState() => _LineItemRowState();
}

class _LineItemRowState extends State<_LineItemRow> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl   = TextEditingController(
        text: widget.item.quantity.toString());
    _priceCtrl = TextEditingController(
        text: widget.item.offeredPrice.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // Keep controllers in sync if vm updates externally
  @override
  void didUpdateWidget(_LineItemRow old) {
    super.didUpdateWidget(old);
    final qtyStr = widget.item.quantity.toString();
    if (_qtyCtrl.text != qtyStr) _qtyCtrl.text = qtyStr;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final i    = widget.index;
    final vm   = widget.vm;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product name + unit
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackgroundLight)),
                Text(item.product.unit,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey.shade400, fontSize: 10)),
              ],
            ),
          ),

          // Qty field
          SizedBox(
            width: 48,
            child: _CompactField(
              controller: _qtyCtrl,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null) vm.setQuantity(i, parsed);
              },
            ),
          ),
          const SizedBox(width: 6),

          // Market price (read-only)
          SizedBox(
            width: 80,
            child: Text(
              'SAR ${item.product.marketPrice.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey.shade500),
            ),
          ),

          // Your price (editable) — red border if out of range
          SizedBox(
            width: 72,
            child: _CompactField(
              controller: _priceCtrl,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              isError: !item.isPriceValid,
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) vm.setOfferedPrice(i, parsed);
              },
            ),
          ),
          const SizedBox(width: 4),

          // Remove ✕
          GestureDetector(
            onTap: () => vm.removeItem(i),
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: Icon(Icons.close_rounded,
                  size: 16, color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact inline text field for table cells
// ─────────────────────────────────────────────────────────────────────────────

class _CompactField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final bool isError;

  const _CompactField({
    required this.controller,
    required this.onChanged,
    this.inputFormatters,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: inputFormatters,
      textAlign: TextAlign.center,
      style: AppTextStyles.bodySmall
          .copyWith(fontWeight: FontWeight.w700, fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isError ? Colors.red.shade400 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isError ? Colors.red.shade400 : AppColors.primaryLight,
            width: 2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Savings Summary card
// ─────────────────────────────────────────────────────────────────────────────

class _SavingsSummary extends StatelessWidget {
  final PriceQuotationViewModel vm;
  const _SavingsSummary({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Savings Summary',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Normal Total:',
            value: 'SAR ${vm.normalTotal.toStringAsFixed(2)}',
            valueColor: Colors.grey.shade700,
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Your Total:',
            value: 'SAR ${vm.offeredTotal.toStringAsFixed(2)}',
            valueColor: AppColors.onBackgroundLight,
          ),
          const Divider(height: 16, color: Colors.transparent),
          _SummaryRow(
            label: 'You Save:',
            value:
                'SAR ${vm.totalSavings.toStringAsFixed(2)} (${vm.savingsPercent.toStringAsFixed(1)}%) ✓',
            valueColor: Colors.green.shade700,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: Colors.grey.shade600)),
        Text(value,
            style: AppTextStyles.bodySmall.copyWith(
              color: valueColor,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wallet balance line (simple text, matching image)
// ─────────────────────────────────────────────────────────────────────────────

class _WalletLine extends StatelessWidget {
  final double balance;
  const _WalletLine({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Wallet Balance: SAR ${_fmt(balance)}',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primaryLight,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cancel + Submit buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final PriceQuotationViewModel vm;
  const _ActionButtons({required this.vm});

  // Show price-out-of-range alert for the first offending item
  void _showOutOfRangeAlert(BuildContext context, QuotationLineItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    size: 36, color: AppColors.primaryLight),
              ),
              const SizedBox(height: 16),

              Text('Price Out of Range',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackgroundLight,
                  )),
              const SizedBox(height: 10),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.grey.shade600, height: 1.5),
                  children: [
                    const TextSpan(text: 'Your offered price for '),
                    TextSpan(
                      text: item.product.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.onBackgroundLight),
                    ),
                    const TextSpan(
                        text: ' is outside the allowed range. Please '
                            'adjust the price before submitting.'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Range hint
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
              
              ),
              const SizedBox(height: 22),

              // OK button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'OK, Got it',
                  backgroundColor: AppColors.primaryLight,
                  textColor: AppColors.onPrimaryLight,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmit(BuildContext context) async {
    // Validate price ranges first
    final invalid = vm.firstInvalidItem;
    if (invalid != null) {
      _showOutOfRangeAlert(context, invalid);
      return;
    }

    final success = await vm.submitQuotation();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Quotation submitted! Awaiting approval.'
          : 'Failed to submit. Please try again.'),
      backgroundColor:
          success ? Colors.green.shade600 : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));

    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Cancel
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Cancel',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 12),

        // Submit
        Expanded(
          flex: 2,
          child: CustomButton(
            text: 'Submit Quotation for Approval',
            isLoading: vm.isSubmitting,
            backgroundColor: AppColors.primaryLight,
            textColor: AppColors.onPrimaryLight,
            onPressed:
                vm.isSubmitting ? () {} : () => _onSubmit(context),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────

String _fmt(double v) {
  final parts = v.toStringAsFixed(0).split('');
  final buf   = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
    buf.write(parts[i]);
  }
  return buf.toString();
}
