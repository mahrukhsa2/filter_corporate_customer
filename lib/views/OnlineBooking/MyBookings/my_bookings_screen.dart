import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/app_cache.dart';
import '../../../data/network/api_response.dart';
import '../../../data/repositories/orders_repository.dart';
import '../../../models/booking_model.dart';
import '../../../services/invoice_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/custom_button.dart';
import 'my_bookings_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyBookingsViewModel(),
      child: const _MyBookingsBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _MyBookingsBody extends StatefulWidget {
  const _MyBookingsBody();

  @override
  State<_MyBookingsBody> createState() => _MyBookingsBodyState();
}

class _MyBookingsBodyState extends State<_MyBookingsBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<MyBookingsViewModel>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<MyBookingsViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;
    final hPad   = isWide ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          const CustomAppBar(title: 'My Bookings', showBackButton: true),

          // ── Filter bar ───────────────────────────────────────────────────
          _FilterBar(vm: vm),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: vm.isLoading
                ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryLight))
                : vm.hasError
                ? _ErrorState(vm: vm)
                : vm.bookings.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              color: AppColors.primaryLight,
              onRefresh: () => vm.refresh(context: context),
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                    hPad, 16, hPad, 24),
                // +1 for load-more indicator
                itemCount: vm.bookings.length +
                    (vm.isLoadingMore ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == vm.bookings.length) {
                    // Load-more spinner at bottom
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryLight),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _BookingCard(
                        booking: vm.bookings[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Bar  — Status dropdown + Branch dropdown + Date range + Clear
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final MyBookingsViewModel vm;
  const _FilterBar({required this.vm});

  static const _statusOptions = [
    (label: 'All Statuses',  value: null),
    (label: 'Submitted',      value: 'submitted'),
    (label: 'Approved',      value: 'approved'),
    (label: 'In Progress',   value: 'in_progress'),
    (label: 'Completed',     value: 'completed'),
    (label: 'Cancelled',     value: 'cancelled'),
    (label: 'Rejected',     value: 'rejected'),

  ];

  static InputDecoration _deco(String hint) => InputDecoration(
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

  @override
  Widget build(BuildContext context) {
    final branches = AppCache.allowedBranches;

    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: Status + Branch dropdowns ─────────────────────────────
          Row(
            children: [
              // Status dropdown
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: vm.filterStatus,
                  isExpanded: true,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.black, fontSize: 12),
                  dropdownColor: Colors.white,
                  decoration: _deco('Status'),
                  items: _statusOptions
                      .map((s) => DropdownMenuItem<String?>(
                    value: s.value,
                    child: Text(s.label,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.black, fontSize: 12)),
                  ))
                      .toList(),
                  onChanged: (val) => vm.applyFilters(
                    status:    val,
                    startDate: vm.filterStartDate,
                    endDate:   vm.filterEndDate,
                    branchId:  vm.filterBranchId,
                    context:   context,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Branch dropdown
              Expanded(
                child: branches.isEmpty
                    ? const SizedBox.shrink()
                    : DropdownButtonFormField<String?>(
                  value: vm.filterBranchId,
                  isExpanded: true,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.black, fontSize: 12),
                  dropdownColor: Colors.white,
                  decoration: _deco('All Branches'),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Branches',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.black, fontSize: 12)),
                    ),
                    ...branches.map((b) => DropdownMenuItem<String?>(
                      value: b.id,
                      child: Text(b.name,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.black, fontSize: 12)),
                    )),
                  ],
                  onChanged: (val) => vm.applyFilters(
                    status:    vm.filterStatus,
                    startDate: vm.filterStartDate,
                    endDate:   vm.filterEndDate,
                    branchId:  val,
                    context:   context,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Row 2: Date range + Clear ─────────────────────────────────────
          Row(
            children: [
              // From date
              Expanded(child: _DateChip(
                label: vm.filterStartDate != null
                    ? _fmt(vm.filterStartDate!) : 'From date',
                icon: Icons.calendar_today_outlined,
                isActive: vm.filterStartDate != null,
                onTap: () async {
                  final d = await _pickDate(context,
                      initial: vm.filterStartDate);
                  if (d != null) vm.applyFilters(
                      status: vm.filterStatus, startDate: d,
                      endDate: vm.filterEndDate,
                      branchId: vm.filterBranchId, context: context);
                },
              )),
              const SizedBox(width: 10),
              // To date
              Expanded(child: _DateChip(
                label: vm.filterEndDate != null
                    ? _fmt(vm.filterEndDate!) : 'To date',
                icon: Icons.calendar_month_outlined,
                isActive: vm.filterEndDate != null,
                onTap: () async {
                  final d = await _pickDate(context,
                      initial: vm.filterEndDate);
                  if (d != null) vm.applyFilters(
                      status: vm.filterStatus,
                      startDate: vm.filterStartDate, endDate: d,
                      branchId: vm.filterBranchId, context: context);
                },
              )),
              // Clear button
              if (vm.hasActiveFilters) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => vm.clearFilters(context: context),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Icon(Icons.filter_alt_off_rounded,
                        size: 16, color: Colors.red.shade400),
                  ),
                ),
              ],
            ],
          ),

          // ── Results count ─────────────────────────────────────────────────
          if (!vm.isLoading && !vm.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                Text(
                  '${vm.total} booking${vm.total == 1 ? "" : "s"}',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
                if (vm.hasActiveFilters) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Filtered',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryLight,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
            ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2,'0')} ${m[d.month-1]}';
  }

  static Future<DateTime?> _pickDate(BuildContext context,
      {DateTime? initial}) =>
      showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.secondaryLight,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Date chip button
// ─────────────────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     isActive;
  final VoidCallback onTap;
  const _DateChip({required this.label, required this.icon,
    required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryLight.withOpacity(0.12)
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.primaryLight : Colors.grey.shade300,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 13,
              color: isActive
                  ? AppColors.secondaryLight : Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: AppTextStyles.caption.copyWith(
                  color: isActive
                      ? AppColors.secondaryLight : Colors.grey.shade600,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error State
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final MyBookingsViewModel vm;
  const _ErrorState({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.wifi_off_rounded,
                  size: 60, color: Colors.red.shade300),
            ),
            const SizedBox(height: 24),
            Text('Could not load bookings',
                style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackgroundLight)),
            const SizedBox(height: 8),
            Text(vm.errorMessage,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            CustomButton(
              text: 'Retry',
              onPressed: () => vm.refresh(context: context),
              backgroundColor: AppColors.primaryLight,
              textColor: AppColors.onPrimaryLight,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking Card  — wireframe style
// ─────────────────────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final BookingHistoryModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _viewDetails(context, booking),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05),
                  blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Line 1: Service name + status badge ───────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        booking.serviceName,
                        style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackgroundLight),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: booking.status),
                  ],
                ),

                const SizedBox(height: 4),

                // ── Line 2: bookedFor · branch ────────────────────────────────────
                Text(
                  '${booking.bookedFor != null ? booking.formattedBookedFor : booking.formattedDate}  ·  ${booking.branchName}',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade600),
                ),

                // ── Line 3: vehicle (if present) ──────────────────────────────────
                if (booking.vehicleInfo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    booking.vehicleInfo!,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey.shade500),
                  ),
                ],

                // ── Line 4: Invoice + amount (Completed) ──────────────────────────
                if (booking.invoiceNumber != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('Invoice ${booking.invoiceNumber}',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600)),
                    if (booking.amount != null) ...[
                      const SizedBox(width: 8),
                      Text('·', style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.grey.shade400)),
                      const SizedBox(width: 8),
                      Text('SAR ${_fmt(booking.amount!)}',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.onBackgroundLight,
                              fontWeight: FontWeight.w700)),
                    ],
                  ]),
                ],

                // ── Actions ───────────────────────────────────────────────────────
                const SizedBox(height: 12),
                _buildActions(context, booking),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, BookingHistoryModel b) {
    if (b.status == 'Completed') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: _ActionBtn('View Invoice', Icons.visibility_outlined,
                    () => _showInvoice(context, b), isPrimary: true)),
            const SizedBox(width: 8),
            Expanded(child: _ActionBtn('Pay from Wallet',
                Icons.account_balance_wallet_outlined,
                    () => _payFromWallet(context, b), isPrimary: true)),
          ]),
          const SizedBox(height: 8),
          _ActionBtn('Download', Icons.download_rounded,
                  () => _downloadInvoice(context, b),
              isPrimary: true, fullWidth: true),
        ],
      );
    }
    else if (b.status == 'In Progress') {
      return _ActionBtn('Track Status', Icons.track_changes_outlined,
              () => _trackStatus(context, b),
          isPrimary: true, fullWidth: true);
    }
    else if (b.status == 'Submitted' || b.status == 'Approved')
    {
      return _ActionBtn('Cancel', Icons.cancel_outlined,
              () => _cancelBooking(context, b), isDestructive: true, fullWidth: true,);
    }
    return const SizedBox.shrink();
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

  void _showInvoice(BuildContext context, BookingHistoryModel b) {

    InvoiceService.showInvoiceDetails(context: context, invoiceId: booking.invoiceNumber.toString());

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Opening invoice ${b.invoiceNumber}...'),
      backgroundColor: AppColors.successGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _payFromWallet(BuildContext context, BookingHistoryModel b) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Pay from Wallet',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
      content: Text('Pay SAR ${_fmt(b.amount ?? 0)} for invoice ${b.invoiceNumber}?',
          style: AppTextStyles.bodyMedium),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.bodyMedium
                .copyWith(color: Colors.grey.shade600))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✅ Payment processed successfully!'),
              backgroundColor: AppColors.successGreen,
              behavior: SnackBarBehavior.floating,
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.onPrimaryLight,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Pay', style: AppTextStyles.button.copyWith(fontSize: 14)),
        ),
      ],
    ));
  }

  void _downloadInvoice(BuildContext context, BookingHistoryModel b) {

    InvoiceService.downloadInvoiceWithUI(context: context, invoiceId: booking.invoiceNumber.toString());

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('📥 Downloading invoice...'),
      backgroundColor: AppColors.successGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _trackStatus(BuildContext context, BookingHistoryModel b) {
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.track_changes_outlined,
                    color: AppColors.primaryLight, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text('Tracking: ${b.serviceName}',
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 20),
              _TrackingStep(title: 'Booking Confirmed',
                  subtitle: b.formattedDate, isCompleted: true),
              _TrackingStep(title: 'Service In Progress',
                  subtitle: 'Technician assigned',
                  isCompleted: true, isCurrent: true),
              _TrackingStep(title: 'Quality Check',
                  subtitle: 'Pending', isCompleted: false),
              _TrackingStep(title: 'Ready for Pickup',
                  subtitle: 'Pending', isCompleted: false, isLast: true),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: CustomButton(
                text: 'Close', onPressed: () => Navigator.pop(ctx),
                backgroundColor: AppColors.secondaryLight, textColor: Colors.white,
              )),
            ]),
      ),
    );
  }

  void _viewDetails(BuildContext context, BookingHistoryModel b) {
    showModalBottomSheet(context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.primaryLight, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text('Booking Details',
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 20),
              _DetailRow(label: 'Service',   value: b.serviceName),
              if (b.bookingCode != null)
                _DetailRow(label: 'Code',    value: b.bookingCode!),
              _DetailRow(label: 'Submitted', value: b.formattedDate),
              if (b.bookedFor != null)
                _DetailRow(label: 'Booked For', value: b.formattedBookedFor),
              _DetailRow(label: 'Branch',    value: b.branchName),
              _DetailRow(label: 'Status',    value: b.status),
              if (b.vehicleInfo != null)
                _DetailRow(label: 'Vehicle', value: b.vehicleInfo!),
              if (b.paymentMethod != null)
                _DetailRow(label: 'Payment', value: b.paymentMethod!),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: CustomButton(
                text: 'Close', onPressed: () => Navigator.pop(ctx),
                backgroundColor: AppColors.primaryLight, textColor: Colors.black,
              )),
            ]),
      ),
    );
  }

  void _cancelBooking(BuildContext context, BookingHistoryModel b) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: Colors.red.shade600, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Cancel Booking?',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(' Are you sure you want to cancel ? This action cannot be undone.',
                style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          CustomButton(
            height: 40,
            width: 135,
            onPressed: () => Navigator.pop(ctx),
             text: 'Keep',
          ),

          CustomButton(
              height: 40,
              width: 135,
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog

              // ✅ Call cancel API
              await _performCancelOrder(context, b);
            },
            backgroundColor: AppColors.secondaryDark,
            textColor: AppColors.onBackgroundDark,
           text: 'Cancel',
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Actual cancel order API call
  Future<void> _performCancelOrder(
      BuildContext context,
      BookingHistoryModel booking,
      ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryLight,
        ),
      ),
    );

    // Call repository
    final result = await OrdersRepository.cancelOrder(booking.id);

    // Hide loading
    if (context.mounted) Navigator.pop(context);

    if (result.success) {
      // Success - show message and refresh list
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result.data?.message ?? "Booking cancelled"}'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refresh bookings list
        context.read<MyBookingsViewModel>().refresh(context: context);
      }
    } else {
      // Error - show error dialog with retry option
      if (context.mounted) {
        await AppAlert.apiError(
          context,
          errorType: result.errorType,
          message: result.message,
          onRetry: result.errorType == ApiErrorType.noInternet ||
              result.errorType == ApiErrorType.timeout
              ? () => _performCancelOrder(context, booking)
              : null,
        );
      }
    }
  }}

// ─────────────────────────────────────────────────────────────────────────────
// Status Badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color => switch (status) {
    'Completed'   => Colors.green.shade600,
    'In Progress' => Colors.blue.shade600,
    'Approved'    => Colors.teal.shade600,
    'Cancelled'   => Colors.red.shade600,
    _             => Colors.grey.shade600,
  };

  IconData get _icon => switch (status) {
    'Completed'   => Icons.check_circle_outline,
    'In Progress' => Icons.pending_outlined,
    'Approved'    => Icons.thumb_up_outlined,
    'Cancelled'   => Icons.cancel_outlined,
    _             => Icons.info_outline,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.30)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_icon, size: 11, color: _color),
        const SizedBox(width: 4),
        Text(status,
            style: AppTextStyles.caption
                .copyWith(color: _color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String     label;
  final IconData   icon;
  final VoidCallback onTap;
  final bool isPrimary, isDestructive, fullWidth;

  const _ActionBtn(this.label, this.icon, this.onTap, {
    this.isPrimary    = false,
    this.isDestructive = false,
    this.fullWidth    = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg   = isDestructive ? AppColors.secondaryDark
        : isPrimary ? AppColors.primaryLight : AppColors.backgroundLight;
    final fg   = isDestructive ? AppColors.onBackgroundDark
        : isPrimary ? AppColors.onPrimaryLight : AppColors.onBackgroundLight;
    final bord = isDestructive ? AppColors.secondaryDark
        : isPrimary ? AppColors.primaryLight : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bord, width: isPrimary ? 0 : 1),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: fg, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tracking Step
// ─────────────────────────────────────────────────────────────────────────────

class _TrackingStep extends StatelessWidget {
  final String title, subtitle;
  final bool   isCompleted, isCurrent, isLast;

  const _TrackingStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    this.isCurrent = false,
    this.isLast    = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: isCompleted || isCurrent
                ? AppColors.primaryLight : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent || isCompleted
                  ? AppColors.primaryLight : Colors.grey.shade300,
              width: isCurrent ? 3 : 1,
            ),
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 16,
              color: AppColors.onPrimaryLight)
              : null,
        ),
        if (!isLast)
          Container(width: 2, height: 40,
              color: isCompleted
                  ? AppColors.primaryLight.withOpacity(0.3)
                  : Colors.grey.shade300),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isCompleted || isCurrent
                  ? AppColors.onBackgroundLight : Colors.grey.shade500)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.bodySmall
              .copyWith(color: Colors.grey.shade600)),
          if (!isLast) const SizedBox(height: 16),
        ],
      )),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Row
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 88,
            child: Text(label, style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey.shade600, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.onBackgroundLight))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy_rounded,
                  size: 80,
                  color: AppColors.primaryLight.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            Text('No Bookings Found',
                style: AppTextStyles.h2.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackgroundLight)),
            const SizedBox(height: 8),
            Text('Try adjusting your filters or book a new service.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Book a Service',
              onPressed: () => Navigator.pop(context),
              backgroundColor: AppColors.primaryLight,
              textColor: AppColors.onPrimaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
