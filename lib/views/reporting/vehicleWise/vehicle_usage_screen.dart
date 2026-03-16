import 'package:filter_corporate_customer/models/vehicle_model.dart';
import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/vehicle_usage_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import 'vehicle_usage_view_model.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class VehicleUsageScreen extends StatelessWidget {
  const VehicleUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VehicleUsageViewModel(),
      child: const _VUBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _VUBody extends StatelessWidget {
  const _VUBody();

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<VehicleUsageViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          const CustomAppBar(
              title: 'Vehicle-wise Usage Report', showBackButton: true),
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
  final VehicleUsageViewModel vm;
  const _NarrowLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _pad(16, child: _FiltersBar(vm: vm)),
        if (vm.summary != null)
          _pad(14, child: _SummaryCards(summary: vm.summary!)),
        _pad(14, child: _VehicleAccordionList(vm: vm)),
        _pad(14, bottom: 32, child: _ExportButton()),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  final VehicleUsageViewModel vm;
  const _WideLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _pad(20, h: 24, child: _FiltersBar(vm: vm)),
        if (vm.summary != null)
          _pad(14, h: 24, child: _SummaryCards(summary: vm.summary!)),
        _pad(14, h: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _VehicleAccordionList(vm: vm)),
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
  final VehicleUsageViewModel vm;
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
      initialDate: current != null && current.isBefore(now) ? current : now,
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

          // Row 2 — vehicle dropdown
          _VehicleDropdown(
            vehicles: vm.dropdownVehicles,
            value: f.vehicleId,
            onChanged: (id) => vm.updateFilters(id == null
                ? f.copyWith(clearVehicle: true)
                : f.copyWith(vehicleId: id)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary stat cards (4 cards in 2×2 grid)
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final VehicleUsageSummary summary;
  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(
            icon: Icons.bar_chart_rounded, title: 'Summary'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Vehicles',
                value: '${summary.totalVehicles}',
                icon: Icons.directions_car_outlined,
                color: Colors.blue.shade700,
                bgColor: Colors.blue.shade50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Total Services',
                value: '${summary.totalServices}',
                icon: Icons.build_outlined,
                color: Colors.orange.shade700,
                bgColor: Colors.orange.shade50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Total spend — full-width dark card
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                    Text('Total Spend',
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
                  Text('Avg / Vehicle',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white54, fontSize: 10)),
                  Text(
                    'SAR ${_fmt(summary.averagePerVehicle)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
// Vehicle accordion list
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleAccordionList extends StatelessWidget {
  final VehicleUsageViewModel vm;
  const _VehicleAccordionList({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(
            icon: Icons.directions_car_outlined,
            title: 'Vehicle List'),
        const SizedBox(height: 10),
        if (vm.isTableLoading)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            ),
          )
        else if (vm.items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.directions_car_outlined,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text('No vehicles match your filters',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.grey.shade400)),
              ],
            ),
          )
        else
          ...vm.items.map((v) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _VehicleCard(vehicle: v, vm: vm),
          )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual vehicle accordion card
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final VehicleUsageItem vehicle;
  final VehicleUsageViewModel vm;
  const _VehicleCard({required this.vehicle, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isOpen = vm.isExpanded(vehicle.id);

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
      child: Column(
        children: [
          // ── Header (always visible) ──────────────────────────────────
          InkWell(
            onTap: () => vm.toggleExpand(vehicle.id),
            borderRadius: isOpen
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Vehicle icon badge
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_car_filled_rounded,
                        size: 22, color: AppColors.secondaryLight),
                  ),
                  const SizedBox(width: 12),

                  // Name + plate
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vehicle.vehicleName,
                            style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.onBackgroundLight)),
                        const SizedBox(height: 2),
                        Text(
                          '${vehicle.totalServices} services · SAR ${_fmt(vehicle.totalSpend)} total',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),

                  // Chevron
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey.shade400, size: 22),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded body ────────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            crossFadeState: isOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _VehicleCardBody(vehicle: vehicle),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expanded body of a vehicle card — 2×2 stat grid matching screenshot
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleCardBody extends StatelessWidget {
  final VehicleUsageItem vehicle;
  const _VehicleCardBody({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: Colors.grey.shade100),

        // ── 2×2 stat grid ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              // Row 1: Total Services | Total Spend
              Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      label: 'Total Services',
                      value: '${vehicle.totalServices}',
                    ),
                  ),
                  Container(
                      width: 1, height: 48, color: Colors.grey.shade100),
                  Expanded(
                    child: _StatCell(
                      label: 'Total Spend',
                      value: 'SAR ${_fmt(vehicle.totalSpend)}',
                      valueColor: AppColors.secondaryLight,
                    ),
                  ),
                ],
              ),
              Divider(height: 16, color: Colors.grey.shade100),
              // Row 2: Avg per Service | Last Service
              Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      label: 'Avg per Service',
                      value: 'SAR ${_fmt(vehicle.averagePerService)}',
                    ),
                  ),
                  Container(
                      width: 1, height: 48, color: Colors.grey.shade100),
                  Expanded(
                    child: _StatCell(
                      label: 'Last Service',
                      value:
                      vehicle.lastServiceDate != null
                          ? '${_shortDate(vehicle.lastServiceDate!)} – ${vehicle.lastServiceType}'
                          : '—',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── View Details button — opens service history popup ─────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showServiceHistorySheet(context, vehicle),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('View Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondaryLight,
                side: BorderSide(
                    color: AppColors.primaryLight.withOpacity(0.6)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stat cell used inside the 2×2 grid ──────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _StatCell({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey.shade500, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.onBackgroundLight,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick stat cell inside expanded card
// ─────────────────────────────────────────────────────────────────────────────

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onBackgroundLight)),
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey.shade500, fontSize: 10)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service history popup (bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────

void _showServiceHistorySheet(BuildContext context, VehicleUsageItem vehicle) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ServiceHistorySheet(vehicle: vehicle),
  );
}

class _ServiceHistorySheet extends StatelessWidget {
  final VehicleUsageItem vehicle;
  const _ServiceHistorySheet({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    // Takes up to 85% of screen height
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ─────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_car_filled_rounded,
                      size: 20, color: AppColors.secondaryLight),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle.vehicleName,
                          style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.onBackgroundLight)),
                      Text(
                        '${vehicle.plateNumber} · ${vehicle.totalServices} services · SAR ${_fmt(vehicle.totalSpend)} total',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.shade100),

          // ── Summary row ─────────────────────────────────────────────
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                _SheetStat(
                  label: 'Total Services',
                  value: '${vehicle.totalServices}',
                  color: Colors.orange.shade700,
                ),
                _SheetStat(
                  label: 'Total Spend',
                  value: 'SAR ${_fmt(vehicle.totalSpend)}',
                  color: AppColors.secondaryLight,
                ),
                _SheetStat(
                  label: 'Avg / Service',
                  value: 'SAR ${_fmt(vehicle.averagePerService)}',
                  color: Colors.blue.shade700,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),

          // ── Section label ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Service History',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onBackgroundLight,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          // ── Scrollable table ─────────────────────────────────────────
          Flexible(
            child: vehicle.serviceHistory.isEmpty
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_outlined,
                      size: 36, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('No service records available',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.grey.shade400)),
                ],
              ),
            )
                : SingleChildScrollView(
              child: _ServiceHistoryTable(
                  records: vehicle.serviceHistory),
            ),
          ),

          // ── Close button ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Close',
                backgroundColor: AppColors.primaryLight,
                textColor: AppColors.onPrimaryLight,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SheetStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey.shade500, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value,
              style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service history — horizontal-scroll table inside the accordion
// ─────────────────────────────────────────────────────────────────────────────

const double _sColDate    = 90.0;
const double _sColType    = 170.0;
const double _sColAmount  = 110.0;
const double _sColBranch  = 140.0;
const double _sRowHPad    = 16.0;

double get _sTotalWidth =>
    _sRowHPad * 2 + _sColDate + _sColType + _sColAmount + _sColBranch;

class _ServiceHistoryTable extends StatelessWidget {
  final List<VehicleServiceRecord> records;
  const _ServiceHistoryTable({required this.records});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _sTotalWidth,
          child: Column(
            children: [
              // Header
              Container(
                width: _sTotalWidth,
                padding: const EdgeInsets.symmetric(
                    horizontal: _sRowHPad, vertical: 10),
                color: AppColors.secondaryLight.withOpacity(0.9),
                child: Row(
                  children: const [
                    _TH(label: 'Date',    width: _sColDate),
                    _TH(label: 'Service', width: _sColType),
                    _TH(label: 'Amount',  width: _sColAmount),
                    _TH(label: 'Branch',  width: _sColBranch),
                  ],
                ),
              ),
              // Rows
              ...List.generate(records.length, (i) {
                final r      = records[i];
                final isEven = i % 2 == 0;
                final isLast = i == records.length - 1;
                return Container(
                  width: _sTotalWidth,
                  padding: const EdgeInsets.symmetric(
                      horizontal: _sRowHPad, vertical: 12),
                  decoration: BoxDecoration(
                    color: isEven
                        ? AppColors.surfaceLight
                        : const Color(0xFFF7F8FA),
                    border: isLast
                        ? null
                        : Border(
                        bottom: BorderSide(
                            color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: _sColDate,
                        child: Text(_shortDate(r.date),
                            style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey.shade600)),
                      ),
                      SizedBox(
                        width: _sColType,
                        child: Text(r.serviceType,
                            style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.onBackgroundLight),
                            overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(
                        width: _sColAmount,
                        child: Text('SAR ${_fmt(r.amount)}',
                            style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onBackgroundLight)),
                      ),
                      SizedBox(
                        width: _sColBranch,
                        child: Text(r.branch,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
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
              fontSize: 12)),
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
    final vm = context.watch<VehicleUsageViewModel>();
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
          if (vm.exportError != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(vm.exportError!),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Report exported successfully'),
              backgroundColor: AppColors.secondaryLight,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
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

class _VehicleDropdown extends StatelessWidget {
  final List<VehicleModel> vehicles;
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
        style: AppTextStyles.bodySmall
            .copyWith(color: Colors.black, fontSize: 12),
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          hintText: 'All Vehicles',
          hintStyle: AppTextStyles.bodySmall
              .copyWith(color: Colors.grey.shade400),
          isDense: true,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
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
            child: Text('All Vehicles',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.black, fontSize: 12)),
          ),
          ...vehicles.map((v) => DropdownMenuItem(
            value: v.id,
            child: Text(
              '${v.make} ${v.model} (${v.plateNumber})',  // ← was v.vehicleName
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.black, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
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

String _fmt(double v) {
  final parts = v.toStringAsFixed(0).split('');
  final buf   = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
    buf.write(parts[i]);
  }
  return buf.toString();
}