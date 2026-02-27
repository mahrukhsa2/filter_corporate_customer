import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/savings_discount_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import 'savings_discount_view_model.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class SavingsDiscountScreen extends StatelessWidget {
  const SavingsDiscountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SavingsDiscountViewModel(),
      child: const _SDBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _SDBody extends StatelessWidget {
  const _SDBody();

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<SavingsDiscountViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          const CustomAppBar(
              title: 'Savings & Discount Report', showBackButton: true),
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
  final SavingsDiscountViewModel vm;
  const _NarrowLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _sliver(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _FiltersBar(vm: vm)),
        _sliver(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: vm.summary != null
                ? _SummaryCards(summary: vm.summary!)
                : const SizedBox()),
        _sliver(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _VehicleSection(vm: vm)),
        _sliver(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _DepartmentSection(vm: vm)),
        _sliver(padding: const EdgeInsets.fromLTRB(16, 14, 16, 60),
            child: _ExportButton()),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  final SavingsDiscountViewModel vm;
  const _WideLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _sliver(padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: _FiltersBar(vm: vm)),
        _sliver(padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: vm.summary != null
                ? _SummaryCards(summary: vm.summary!)
                : const SizedBox()),
        _sliver(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _VehicleSection(vm: vm)),
              const SizedBox(width: 20),
              Expanded(flex: 4, child: _DepartmentSection(vm: vm)),
            ],
          ),
        ),
        _sliver(padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
            child: _ExportButton()),
      ],
    );
  }
}

SliverPadding _sliver(
    {required EdgeInsets padding, required Widget child}) =>
    SliverPadding(
      padding: padding,
      sliver: SliverToBoxAdapter(child: child),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Filters bar
// ─────────────────────────────────────────────────────────────────────────────

class _FiltersBar extends StatefulWidget {
  final SavingsDiscountViewModel vm;
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
          // Row 1 — date range
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

          // Row 2 — vehicle + department dropdowns
          Row(
            children: [
              Expanded(
                child: _VehicleDropdown(
                  vehicles: vm.vehicleOptions,
                  value: f.vehicleId,
                  onChanged: (id) => vm.updateFilters(id == null
                      ? f.copyWith(clearVehicle: true)
                      : f.copyWith(vehicleId: id)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DepartmentDropdown(
                  departments: vm.departmentOptions,
                  value: f.department,
                  onChanged: (d) => vm.updateFilters(d == null
                      ? f.copyWith(clearDepartment: true)
                      : f.copyWith(department: d)),
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
// Summary stat cards  (3 cards)
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final SavingsSummary summary;
  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(icon: Icons.savings_outlined, title: 'Summary'),
        const SizedBox(height: 10),
        isWide
        // Wide: 3 in a row
            ? Row(
          children: [
            Expanded(child: _SummaryStatCard(
              label: 'Total Market Cost',
              value: 'SAR ${_fmt(summary.totalMarketCost)}',
              icon: Icons.store_outlined,
              color: Colors.grey.shade700,
              bgColor: Colors.grey.shade100,
            )),
            const SizedBox(width: 12),
            Expanded(child: _SummaryStatCard(
              label: 'Total Corporate Cost',
              value: 'SAR ${_fmt(summary.totalCorporateCost)}',
              icon: Icons.business_center_outlined,
              color: Colors.blue.shade700,
              bgColor: Colors.blue.shade50,
            )),
            const SizedBox(width: 12),
            Expanded(child: _SummaryStatCard(
              label: 'Total Savings',
              value:
              'SAR ${_fmt(summary.totalSavings)} (${summary.savingsPercent.toStringAsFixed(1)}%)',
              icon: Icons.trending_down_rounded,
              color: Colors.green.shade700,
              bgColor: Colors.green.shade50,
              highlight: true,
            )),
          ],
        )
        // Mobile: 2 top + 1 full-width bottom
            : Column(
          children: [
            Row(
              children: [
                Expanded(child: _SummaryStatCard(
                  label: 'Total Market Cost',
                  value: 'SAR ${_fmt(summary.totalMarketCost)}',
                  icon: Icons.store_outlined,
                  color: Colors.grey.shade700,
                  bgColor: Colors.grey.shade100,
                )),
                const SizedBox(width: 12),
                Expanded(child: _SummaryStatCard(
                  label: 'Corporate Cost',
                  value: 'SAR ${_fmt(summary.totalCorporateCost)}',
                  icon: Icons.business_center_outlined,
                  color: Colors.blue.shade700,
                  bgColor: Colors.blue.shade50,
                )),
              ],
            ),
            const SizedBox(height: 12),
            _SavingsHighlightCard(summary: summary),
          ],
        ),
      ],
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool highlight;

  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? Colors.green.shade50 : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: highlight
            ? Border.all(color: Colors.green.shade200, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }
}

// Full-width green savings highlight (mobile bottom card)
class _SavingsHighlightCard extends StatelessWidget {
  final SavingsSummary summary;
  const _SavingsHighlightCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.trending_down_rounded,
                size: 22, color: AppColors.primaryLight),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Savings',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70)),
                const SizedBox(height: 2),
                Text(
                  'SAR ${_fmt(summary.totalSavings)}',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${summary.savingsPercent.toStringAsFixed(1)}% saved',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Savings by Vehicle — horizontal-scroll table
// ─────────────────────────────────────────────────────────────────────────────

const double _vColVehicle    = 160.0;
const double _vColPlate      = 100.0;
const double _vColMarket     = 130.0;
const double _vColCorporate  = 130.0;
const double _vColSaved      = 120.0;
const double _vColPct        =  90.0;
const double _vRowHPad       =  16.0;

double get _vTotalWidth =>
    _vRowHPad * 2 +
        _vColVehicle +
        _vColPlate +
        _vColMarket +
        _vColCorporate +
        _vColSaved +
        _vColPct;

class _VehicleSection extends StatelessWidget {
  final SavingsDiscountViewModel vm;
  const _VehicleSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
            icon: Icons.directions_car_outlined,
            title: 'Savings by Vehicle'),
        const SizedBox(height: 10),

        // ── Horizontal bar chart ────────────────────────────────────────
        if (vm.vehicleRows.isNotEmpty) ...[
          _VehicleBarChart(rows: vm.vehicleRows),
          const SizedBox(height: 14),
        ],


      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal bar chart for Savings by Vehicle
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleBarChart extends StatelessWidget {
  final List<VehicleSavingsRow> rows;
  const _VehicleBarChart({required this.rows});

  @override
  Widget build(BuildContext context) {
    // Find max saved value to calculate bar widths proportionally
    final maxSaved = rows.map((r) => r.saved).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart rows
          ...rows.map((row) {
            final fraction = maxSaved > 0 ? row.saved / maxSaved : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label row
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          '${row.vehicleName} ${row.plateNumber}',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey.shade800,
                              fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'SAR ${_fmt(row.saved)} saved',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Bar
                  LayoutBuilder(builder: (ctx, constraints) {
                    final barWidth =
                        constraints.maxWidth * fraction;
                    return Stack(
                      children: [
                        // Background track
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        // Filled bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: 10,
                          width: barWidth,
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            );
          }).toList(),

          // X-axis scale hint
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey.shade700, fontSize: 10)),
                Text('SAR ${_fmt(maxSaved / 2)}',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey.shade700, fontSize: 10)),
                Text('SAR ${_fmt(maxSaved)}',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey.shade700, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Savings by Department — horizontal-scroll table
// ─────────────────────────────────────────────────────────────────────────────

const double _dColDept      = 200.0;
const double _dColSaved     = 150.0;
const double _dRowHPad      =  16.0;

double get _dTotalWidth =>
    _dRowHPad * 2 +
        _dColDept +
        _dColSaved;

class _DepartmentSection extends StatelessWidget {
  final SavingsDiscountViewModel vm;
  const _DepartmentSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
            icon: Icons.category_outlined,
            title: 'Savings by Department'),
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
                width: _dTotalWidth,
                child: Column(
                  children: [
                    _DeptTableHeader(),
                    if (vm.departmentRows.isEmpty)
                      _emptyState('No department data'),
                    ...List.generate(
                      vm.departmentRows.length,
                          (i) => _DeptTableRow(
                        row:    vm.departmentRows[i],
                        isEven: i % 2 == 0,
                        isLast: i == vm.departmentRows.length - 1,
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

class _DeptTableHeader extends StatelessWidget {
  const _DeptTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _dTotalWidth,
      padding: const EdgeInsets.symmetric(
          horizontal: _dRowHPad, vertical: 14),
      color: AppColors.secondaryLight,
      child: Row(
        children: const [
          _TH(label: 'Department',  width: _dColDept),
        //  _TH(label: 'Market Cost', width: _dColMarket),
       //   _TH(label: 'Corp. Cost',  width: _dColCorp),
          _TH(label: 'Saved',       width: _dColSaved),
     //     _TH(label: '% Saved',     width: _dColPct),
        ],
      ),
    );
  }
}

class _DeptTableRow extends StatelessWidget {
  final DepartmentSavingsRow row;
  final bool isEven;
  final bool isLast;
  const _DeptTableRow({
    required this.row,
    required this.isEven,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _dTotalWidth,
      padding: const EdgeInsets.symmetric(
          horizontal: _dRowHPad, vertical: 16),
      decoration: BoxDecoration(
        color: isEven ? AppColors.surfaceLight : const Color(0xFFF7F8FA),
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _dColDept,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.build_outlined,
                      size: 14, color: AppColors.secondaryLight),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(row.department,
                      style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackgroundLight),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          SizedBox(
            width: _dColSaved,
            child: Text('SAR ${_fmt(row.saved)}',
                style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared table header cell
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
// Export button
// ─────────────────────────────────────────────────────────────────────────────

class _ExportButton extends StatelessWidget {
  const _ExportButton();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavingsDiscountViewModel>();
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
// Reusable section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
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
}

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
// Vehicle dropdown  (text color: black)
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleDropdown extends StatelessWidget {
  final List<VehicleSavingsRow> vehicles;
  final String? value;
  final ValueChanged<String?> onChanged;
  const _VehicleDropdown({
    required this.vehicles,
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
        style: AppTextStyles.bodySmall.copyWith(
            color: Colors.black, fontSize: 12),
        dropdownColor: Colors.white,
        decoration: _dropdownDecoration('All Vehicles'),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text('All Vehicles',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.black, fontSize: 12)),
          ),
          ...vehicles.map((v) => DropdownMenuItem(
            value: v.id,
            child: Text('${v.vehicleName} (${v.plateNumber})',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.black, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          )),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Department dropdown  (text color: black)
// ─────────────────────────────────────────────────────────────────────────────

class _DepartmentDropdown extends StatelessWidget {
  final List<String> departments;
  final String? value;
  final ValueChanged<String?> onChanged;
  const _DepartmentDropdown({
    required this.departments,
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
        style: AppTextStyles.bodySmall.copyWith(
            color: Colors.black, fontSize: 12),
        dropdownColor: Colors.white,
        decoration: _dropdownDecoration('All Departments'),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text('All Departments',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.black, fontSize: 12)),
          ),
          ...departments.map((d) => DropdownMenuItem(
            value: d,
            child: Text(d,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.black, fontSize: 12)),
          )),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

InputDecoration _dropdownDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: AppTextStyles.bodySmall.copyWith(
      color: Colors.grey.shade400, fontSize: 12),
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
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

Widget _emptyState(String msg) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 36),
  child: Column(
    children: [
      Icon(Icons.inbox_outlined, size: 36, color: Colors.grey.shade300),
      const SizedBox(height: 8),
      Text(msg,
          style: AppTextStyles.bodySmall
              .copyWith(color: Colors.grey.shade400)),
    ],
  ),
);

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

String _fmt(double v) {
  final parts = v.toStringAsFixed(0).split('');
  final buf   = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
    buf.write(parts[i]);
  }
  return buf.toString();
}