import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/vehicle_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/app_alert.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'vehicle_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VehicleViewModel(),
      child: const _VehicleBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main body
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleBody extends StatelessWidget {
  const _VehicleBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VehicleViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          const CustomAppBar(title: "My Vehicles", showBackButton: true),
          Expanded(
            child: vm.isLoading
                ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryLight),
            )
            // ── Error state (network/timeout/server) ─────────────────
                : vm.hasError
                ? _ErrorState(vm: vm)
            // ── Loaded ───────────────────────────────────────────────
                : RefreshIndicator(
              color: AppColors.primaryLight,
              onRefresh: () => vm.refresh(context: context),
              // ── Empty — only when API succeeded with 0 results ───
              child: vm.vehicles.isEmpty
                  ? const _EmptyState()
                  : isWide
                  ? _WideGrid(vm: vm)
                  : _NarrowList(vm: vm),
            ),
          ),
        ],
      ),
      floatingActionButton: vm.isLoading
          ? null
          : FloatingActionButton.extended(
        onPressed: () => _openForm(context, vm: vm),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.onPrimaryLight,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Vehicle',
          style: AppTextStyles.button
              .copyWith(fontSize: 14, color: AppColors.onPrimaryLight),
        ),
      ),
    );
  }

  static void _openForm(BuildContext context,
      {required VehicleViewModel vm, VehicleModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _VehicleFormSheet(existing: existing),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error State
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VehicleViewModel vm;
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
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 60, color: Colors.red.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              'Could not load vehicles',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onBackgroundLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
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
// Narrow list
// ─────────────────────────────────────────────────────────────────────────────

class _NarrowList extends StatelessWidget {
  final VehicleViewModel vm;
  const _NarrowList({required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: vm.vehicles.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _VehicleCard(vehicle: vm.vehicles[i], vm: vm),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wide grid
// ─────────────────────────────────────────────────────────────────────────────

class _WideGrid extends StatelessWidget {
  final VehicleViewModel vm;
  const _WideGrid({required this.vm});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.65,
      ),
      itemCount: vm.vehicles.length,
      itemBuilder: (ctx, i) => _VehicleCard(vehicle: vm.vehicles[i], vm: vm),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle card — unchanged from original
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VehicleViewModel vm;
  const _VehicleCard({required this.vehicle, required this.vm});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: vehicle.isDefault
            ? Border.all(color: AppColors.primaryLight, width: 2.5)
            : Border.all(color: Colors.transparent, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_car_filled_rounded,
                      color: AppColors.secondaryLight, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle.make} ${vehicle.model}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackgroundLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.plateNumber,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (vehicle.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Default',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoPill(
                      icon: Icons.calendar_today_outlined,
                      value: vehicle.year.toString()),
                  Container(width: 1, height: 24, color: Colors.grey.shade300),
                  _InfoPill(
                      icon: Icons.speed_outlined,
                      value: '${_fmt(vehicle.odometer.toDouble())} km'),
                  Container(width: 1, height: 24, color: Colors.grey.shade300),
                  _InfoPill(
                      icon: Icons.palette_outlined, value: vehicle.color),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CardActionBtn(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    fgColor: AppColors.secondaryLight,
                    bgColor: AppColors.backgroundLight,
                    onTap: () => _VehicleBody._openForm(context,
                        vm: vm, existing: vehicle),
                  ),
                ),
                const SizedBox(width: 8),
                if (!vehicle.isDefault) ...[
                  Expanded(
                    child: _CardActionBtn(
                      icon: Icons.star_outline_rounded,
                      label: 'Set Default',
                      fgColor: AppColors.onBackgroundLight,
                      bgColor: AppColors.primaryLight,
                      onTap: () => vm.setDefault(vehicle.id),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _CardActionBtn(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    fgColor: AppColors.onBackgroundDark,
                    bgColor: AppColors.secondaryDark,
                    onTap: () => _showDeleteDialog(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Vehicle',
            style: AppTextStyles.h3.copyWith(fontSize: 18)),
        content: Text(
          'Are you sure you want to remove ${vehicle.make} ${vehicle.model} (${vehicle.plateNumber})?',
          style: AppTextStyles.bodyMedium,
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
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final deleted =
              await vm.deleteVehicle(vehicle.id, context: context);
              // Error shown by VM via AppAlert; show success snackbar only
              if (deleted && context.mounted) {
                AppAlert.snackbar(
                    context, message: 'Vehicle deleted.', isSuccess: true);
              }
            },
            child: Text('Delete',
                style: AppTextStyles.button
                    .copyWith(fontSize: 14, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit form — unchanged from original
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleFormSheet extends StatefulWidget {
  final VehicleModel? existing;
  const _VehicleFormSheet({this.existing});

  @override
  State<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<_VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _plateCtrl;
  late final TextEditingController _odoCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _colorCtrl;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _makeCtrl  = TextEditingController(text: v?.make ?? '');
    _modelCtrl = TextEditingController(text: v?.model ?? '');
    _plateCtrl = TextEditingController(text: v?.plateNumber ?? '');
    _odoCtrl   = TextEditingController(text: v != null ? v.odometer.toString() : '');
    _yearCtrl  = TextEditingController(text: v != null ? v.year.toString() : '');
    _colorCtrl = TextEditingController(text: v?.color ?? '');
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _odoCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(VehicleViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final success = _isEdit
        ? await vm.editVehicle(
      context:     context,
      id:          widget.existing!.id,
      make:        _makeCtrl.text,
      model:       _modelCtrl.text,
      plateNumber: _plateCtrl.text,
      odometer:    int.parse(_odoCtrl.text),
      year:        int.parse(_yearCtrl.text),
      color:       _colorCtrl.text,
    )
        : await vm.addVehicle(
      context:     context,
      make:        _makeCtrl.text,
      model:       _modelCtrl.text,
      plateNumber: _plateCtrl.text,
      odometer:    int.parse(_odoCtrl.text),
      year:        int.parse(_yearCtrl.text),
      color:       _colorCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'Vehicle updated successfully.'
              : 'Vehicle added successfully.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm         = context.watch<VehicleViewModel>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isWide     = MediaQuery.of(context).size.width > 720;

    return Center(
      child: Container(
        width: isWide ? 560.0 : double.infinity,
        margin: isWide
            ? const EdgeInsets.symmetric(horizontal: 24, vertical: 32)
            : EdgeInsets.zero,
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: isWide
              ? BorderRadius.circular(20)
              : const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: isWide
                      ? const BorderRadius.vertical(top: Radius.circular(20))
                      : const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isEdit
                          ? Icons.edit_rounded
                          : Icons.add_circle_outline_rounded,
                      color: AppColors.onPrimaryLight,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isEdit ? 'Edit Vehicle' : 'Add New Vehicle',
                        style: AppTextStyles.h3.copyWith(
                          fontSize: 17,
                          color: AppColors.onPrimaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.onPrimaryLight),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      isWide
                          ? Row(children: [
                        Expanded(child: _buildMake()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildModel()),
                      ])
                          : Column(children: [
                        _buildMake(),
                        const SizedBox(height: 14),
                        _buildModel(),
                      ]),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Plate Number *',
                        hint: 'e.g. ABC-123',
                        controller: _plateCtrl,
                        prefixIcon: const Icon(Icons.credit_card_outlined),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Plate number is required' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Odometer (km) *',
                              hint: '45200',
                              controller: _odoCtrl,
                              keyboardType: TextInputType.number,
                              prefixIcon: const Icon(Icons.speed_outlined),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                if (int.tryParse(v) == null) return 'Numbers only';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: 'Year *',
                              hint: '2022',
                              controller: _yearCtrl,
                              keyboardType: TextInputType.number,
                              prefixIcon: const Icon(Icons.calendar_today_outlined),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                final y = int.tryParse(v);
                                if (y == null || y < 1990 || y > 2030) return 'Invalid year';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Color *',
                        hint: 'e.g. White',
                        controller: _colorCtrl,
                        prefixIcon: const Icon(Icons.palette_outlined),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Color is required' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: _isEdit ? 'Update Vehicle' : 'Add Vehicle',
                          isLoading: vm.isSaving,
                          onPressed: vm.isSaving ? () {} : () => _onSubmit(vm),
                          backgroundColor: AppColors.primaryLight,
                          textColor: AppColors.onPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMake() => CustomTextField(
    label: 'Make *',
    hint: 'e.g. Toyota',
    controller: _makeCtrl,
    prefixIcon: const Icon(Icons.directions_car_outlined),
    validator: (v) =>
    (v == null || v.trim().isEmpty) ? 'Make is required' : null,
  );

  Widget _buildModel() => CustomTextField(
    label: 'Model *',
    hint: 'e.g. Camry',
    controller: _modelCtrl,
    prefixIcon: const Icon(Icons.car_repair_outlined),
    validator: (v) =>
    (v == null || v.trim().isEmpty) ? 'Model is required' : null,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — unchanged
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No Vehicles Yet',
              style: AppTextStyles.h3
                  .copyWith(fontSize: 18, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text(
            'Tap "+ Add Vehicle" to register\nyour first vehicle.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers — unchanged
// ─────────────────────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String value;
  const _InfoPill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onBackgroundLight,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

class _CardActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fgColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _CardActionBtn({
    required this.icon,
    required this.label,
    required this.fgColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: fgColor),
            const SizedBox(width: 5),
            Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
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