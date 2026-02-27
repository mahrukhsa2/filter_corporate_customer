import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/booking_service_report_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_button.dart';
import 'booking_service_report_view_model.dart';
import 'package:flutter/material.dart';

class BookingServiceReportScreen extends StatelessWidget {
  const BookingServiceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingServiceReportViewModel(),
      child: const _BSBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _BSBody extends StatelessWidget {
  const _BSBody();

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<BookingServiceReportViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          const CustomAppBar(
              title: 'Booking & Service History', showBackButton: true),
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
  final BookingServiceReportViewModel vm;
  const _NarrowLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _pad(16, child: _FiltersBar(vm: vm)),
        _pad(14, child: _BookingList(vm: vm)),
        if (vm.summary != null)
          _pad(14, child: _SummarySection(summary: vm.summary!)),
        _pad(14, bottom: 32, child: _ExportButton()),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  final BookingServiceReportViewModel vm;
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
                Expanded(flex: 7, child: _BookingList(vm: vm)),
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
  final BookingServiceReportViewModel vm;
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
    final picked = await showDatePicker(
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

          // Row 2 — Status + Branch dropdowns
          Row(
            children: [
              Expanded(
                child: _StatusDropdown(
                  value: f.status,
                  onChanged: (s) => vm.updateFilters(s == null
                      ? f.copyWith(clearStatus: true)
                      : f.copyWith(status: s)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BranchDropdown(
                  value: f.branch,
                  branches: vm.branches,
                  onChanged: (b) => vm.updateFilters(b == null
                      ? f.copyWith(clearBranch: true)
                      : f.copyWith(branch: b)),
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
// Fixed column widths — header + rows share the same values
// ─────────────────────────────────────────────────────────────────────────────

const double _colBookingId  = 110.0;
const double _colDate       =  90.0;
const double _colVehicle    = 100.0;
const double _colDept       = 150.0;
const double _colStatus     = 110.0;
const double _colAmount     = 110.0;
const double _colAction     = 110.0;
const double _rowHPad       =  16.0;

double get _totalTableWidth =>
    _rowHPad * 2 +
        _colBookingId + _colDate + _colVehicle +
        _colDept + _colStatus + _colAmount + _colAction;

// ─────────────────────────────────────────────────────────────────────────────
// Booking list — horizontally scrollable, fixed columns, dark header
// ─────────────────────────────────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  final BookingServiceReportViewModel vm;
  const _BookingList({required this.vm});

  @override
  Widget build(BuildContext context) {
    final items = vm.items;

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
                // ── Dark header (gets rounded corners from ClipRRect) ────
                _TableHeader(itemCount: items.length),

                // ── Empty state ──────────────────────────────────────────
                if (items.isEmpty)
                  SizedBox(
                    width: _totalTableWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text('No bookings match your filters',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ),

                // ── Data rows ────────────────────────────────────────────
                ...List.generate(
                  items.length,
                      (i) => _BookingRow(
                    item:   items[i],
                    isEven: i % 2 == 0,
                    isLast: i == items.length - 1,
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

// ─────────────────────────────────────────────────────────────────────────────
// Dark table header (matches quotation history style)
// ─────────────────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final int itemCount;
  const _TableHeader({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _totalTableWidth,
      color: AppColors.secondaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Column labels row ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(_rowHPad, 14, _rowHPad, 14),
            child: Row(
              children: const [
                _TH(label: 'Booking ID',  width: _colBookingId),
                _TH(label: 'Date',        width: _colDate),
                _TH(label: 'Vehicle',     width: _colVehicle),
                _TH(label: 'Department',  width: _colDept),
                _TH(label: 'Status',      width: _colStatus),
                _TH(label: 'Amount',      width: _colAmount),
                _TH(label: 'Action',      width: _colAction),
              ],
            ),
          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Single flat booking row
// ─────────────────────────────────────────────────────────────────────────────

class _BookingRow extends StatelessWidget {
  final BookingServiceItem item;
  final bool isEven;
  final bool isLast;
  const _BookingRow({
    required this.item,
    required this.isEven,
    required this.isLast,
  });

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _BookingDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = item.status;

    return Container(
      width: _totalTableWidth,
      padding: const EdgeInsets.symmetric(
          horizontal: _rowHPad, vertical: 14),
      decoration: BoxDecoration(
        color: isEven ? AppColors.surfaceLight : const Color(0xFFF7F8FA),
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Booking ID
          SizedBox(
            width: _colBookingId,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.serviceType.icon,
                      size: 14,
                      color: AppColors.secondaryLight),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.bookingId,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Date
          SizedBox(
            width: _colDate,
            child: Text(
              _shortDate(item.date),
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.grey.shade600),
            ),
          ),

          // Vehicle
          SizedBox(
            width: _colVehicle,
            child: Text(
              item.vehiclePlate,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onBackgroundLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Department
          SizedBox(
            width: _colDept,
            child: Text(
              item.department,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.onBackgroundLight),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Status chip
          SizedBox(
            width: _colStatus,
            child: _StatusChip(status: s),
          ),

          // Amount
          SizedBox(
            width: _colAmount,
            child: Text(
              item.formattedAmount,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: item.amount != null
                    ? AppColors.onBackgroundLight
                    : Colors.grey.shade400,
              ),
            ),
          ),

          // Action — View Invoice button
          SizedBox(
            width: _colAction,
            child: GestureDetector(
              onTap: () => _showDetail(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'View Invoice',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryLight,
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
// Bottom sheet detail view
// ─────────────────────────────────────────────────────────────────────────────

class _BookingDetailSheet extends StatelessWidget {
  final BookingServiceItem item;
  const _BookingDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final s = item.status;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: s.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.serviceType.icon, size: 22, color: s.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.bookingId,
                        style: AppTextStyles.h3.copyWith(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(item.serviceType.label,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item.formattedAmount,
                      style: AppTextStyles.h3.copyWith(
                          color: AppColors.secondaryLight,
                          fontWeight: FontWeight.w800,
                          fontSize: 20)),
                  const SizedBox(height: 4),
                  _StatusChip(status: s),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 16),

          _DetailRow('Date',       _shortDate(item.date)),
          _DetailRow('Vehicle',    item.vehiclePlate),
          _DetailRow('Department', item.department),
          _DetailRow('Branch',     item.branch),
          _DetailRow('Status',     s.label),
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
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
  final BookingServiceSummary summary;
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

        // 2×2 status breakdown cards
        Row(
          children: [
            Expanded(child: _StatCard(
              label: 'Completed',
              value: '${summary.completed}',
              icon: BookingStatus.completed.icon,
              color: BookingStatus.completed.color,
              bgColor: BookingStatus.completed.bgColor,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              label: 'In Progress',
              value: '${summary.inProgress}',
              icon: BookingStatus.inProgress.icon,
              color: BookingStatus.inProgress.color,
              bgColor: BookingStatus.inProgress.bgColor,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(
              label: 'Cancelled',
              value: '${summary.cancelled}',
              icon: BookingStatus.cancelled.icon,
              color: BookingStatus.cancelled.color,
              bgColor: BookingStatus.cancelled.bgColor,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              label: 'Pending',
              value: '${summary.pending}',
              icon: BookingStatus.pending.icon,
              color: BookingStatus.pending.color,
              bgColor: BookingStatus.pending.bgColor,
            )),
          ],
        ),
        const SizedBox(height: 12),

        // Total spend — full-width dark card (mirrors payment history style)
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
                child: const Icon(Icons.local_car_wash_rounded,
                    size: 20, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Service Spend',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white60)),
                    const SizedBox(height: 2),
                    Text('SAR ${_fmt(summary.totalSpend)}',
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
                  Text('Total',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white54, fontSize: 10)),
                  Text('${summary.totalBookings}',
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

// ─────────────────────────────────────────────────────────────────────────────
// Export button
// ─────────────────────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  const _ExportButton();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingServiceReportViewModel>();
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

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final BookingStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: status.bgColor,
          borderRadius: BorderRadius.circular(20)),
      child: Text(status.label,
          style: AppTextStyles.bodySmall.copyWith(
              color: status.color,
              fontWeight: FontWeight.w700,
              fontSize: 10)),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: AppTextStyles.h2.copyWith(
                        color: color, fontWeight: FontWeight.w600, fontSize: 22)),
                Text(label,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Dropdowns
// ─────────────────────────────────────────────────────────────────────────────

class _StatusDropdown extends StatelessWidget {
  final BookingStatus? value;
  final ValueChanged<BookingStatus?> onChanged;
  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: DropdownButtonFormField<BookingStatus?>(
        value: value,
        isExpanded: true,
        style: AppTextStyles.bodySmall
            .copyWith(color: Colors.black, fontSize: 12),
        dropdownColor: Colors.white,
        decoration: _dropdownDeco('All Statuses'),
        items: [
          _ddItem(null, 'All Statuses'),
          ...BookingStatus.values.map((s) => _ddItem(s, s.label)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _BranchDropdown extends StatelessWidget {
  final String? value;
  final List<String> branches;
  final ValueChanged<String?> onChanged;
  const _BranchDropdown({
    required this.value,
    required this.branches,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: DropdownButtonFormField<String?>(
        value: value,
        isExpanded: true,
        style: AppTextStyles.bodySmall
            .copyWith(color: Colors.black, fontSize: 12),
        dropdownColor: Colors.white,
        decoration: _dropdownDeco('All Branches'),
        items: [
          _ddItem<String?>(null, 'All Branches'),
          ...branches.map((b) => _ddItem<String?>(b, b)),
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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]}';
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