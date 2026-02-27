import 'package:filter_corporate_customer/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import 'booking_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingViewModel(),
      child: const _BookingBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _BookingBody extends StatelessWidget {
  const _BookingBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          //const _BookingHeader(),
          const CustomAppBar(title: "Book Service Appoinment", showBackButton: true,),
          Expanded(
            child: vm.isLoading
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
  final BookingViewModel vm;
  const _NarrowLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _formSections(context, vm),
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  final BookingViewModel vm;
  const _WideLayout({required this.vm});

  @override
  Widget build(BuildContext context) {
    final sections = _formSections(context, vm);
    // Split sections between two columns
    // Left: dept, vehicle, branch (0,1,2)
    // Right: date+slots, notes, wallet, submit (3,4,5,6)
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sections[0], const SizedBox(height: 16),
                sections[1], const SizedBox(height: 16),
                sections[2],
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sections[3], const SizedBox(height: 16),
                sections[4], const SizedBox(height: 16),
                sections[5], const SizedBox(height: 24),
                sections[6],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Returns all form section widgets in order
List<Widget> _formSections(BuildContext context, BookingViewModel vm) => [
  _DepartmentSection(vm: vm),               // 0
  SizedBox(height: 12,),
  _VehicleSection(vm: vm),
  SizedBox(height: 12,),                     // 1
  _BranchSection(vm: vm),                    // 2
  SizedBox(height: 12,),
  _DateTimeSection(vm: vm),                  // 3
  SizedBox(height: 12,),
  _NotesSection(vm: vm),                     // 4
  SizedBox(height: 12,),
  _WalletSection(vm: vm),                    // 5
  SizedBox(height: 12,),
  _SubmitSection(vm: vm),                    // 6
    ];


// ─────────────────────────────────────────────────────────────────────────────
// 1. Department selector – horizontal scrolling chips
// ─────────────────────────────────────────────────────────────────────────────

class _DepartmentSection extends StatelessWidget {
  final BookingViewModel vm;
  const _DepartmentSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Select Department',
      icon: Icons.build_outlined,
      child: _StyledDropdown<DepartmentModel>(
        value: vm.selectedDepartment,
        hint: 'Choose a department',
        items: vm.departments,
        labelBuilder: (d) => d.name,
        leadingBuilder: (d) => Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(d.icon, style: const TextStyle(fontSize: 16)),
        ),
        onChanged: vm.selectDepartment,
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// 2. Vehicle dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleSection extends StatelessWidget {
  final BookingViewModel vm;
  const _VehicleSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Select Vehicle',
      icon: Icons.directions_car_outlined,
      child: _StyledDropdown<BookingVehicleModel>(
        value: vm.selectedVehicle,
        hint: 'Choose a vehicle',
        items: vm.vehicles,
        labelBuilder: (v) => v.displayName,
        leadingBuilder: (v) => Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.directions_car_filled_rounded,
              size: 16, color: AppColors.secondaryLight),
        ),
        onChanged: vm.selectVehicle,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Branch dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _BranchSection extends StatelessWidget {
  final BookingViewModel vm;
  const _BranchSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Select Branch',
      icon: Icons.store_outlined,
      child: _StyledDropdown<BranchModel>(
        value: vm.selectedBranch,
        hint: 'Choose a branch',
        items: vm.branches,
        labelBuilder: (b) => b.displayName,
        leadingBuilder: (b) => Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.location_on_outlined,
              size: 16, color: AppColors.secondaryLight),
        ),
        onChanged: vm.selectBranch,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Date + Time slot picker
// ─────────────────────────────────────────────────────────────────────────────

class _DateTimeSection extends StatelessWidget {
  final BookingViewModel vm;
  const _DateTimeSection({required this.vm});

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryLight,
            onPrimary: AppColors.onPrimaryLight,
            surface: AppColors.surfaceLight,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) await vm.selectDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Date & Time',
      icon: Icons.calendar_today_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date picker button ───────────────────────────────────────
          GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: vm.selectedDate != null
                      ? AppColors.primaryLight
                      : Colors.grey.shade300,
                  width: vm.selectedDate != null ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded,
                      size: 20,
                      color: vm.selectedDate != null
                          ? AppColors.secondaryLight
                          : Colors.grey.shade500),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      vm.selectedDate != null
                          ? _formatDate(vm.selectedDate!)
                          : 'Tap to select a date',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: vm.selectedDate != null
                            ? AppColors.onBackgroundLight
                            : Colors.grey.shade500,
                        fontWeight: vm.selectedDate != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade400),
                ],
              ),
            ),
          ),

          // ── Time slots grid ──────────────────────────────────────────
          if (vm.selectedDate != null) ...[
            const SizedBox(height: 16),
            if (vm.timeSlots.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryLight)),
                      const SizedBox(width: 10),
                      Text('Loading slots…',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              )
            else ...[
              Text('Available Slots',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  )),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vm.timeSlots.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // ✅ 3 per row
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.2, // controls height
                ),
                itemBuilder: (context, index) {
                  final slot = vm.timeSlots[index];
                  final isSelected = vm.selectedSlot?.id == slot.id;

                  return GestureDetector(
                    onTap: () => vm.selectSlot(slot),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: !slot.available
                            ? Colors.grey.shade100
                            : isSelected
                            ? AppColors.primaryLight
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !slot.available
                              ? Colors.grey.shade200
                              : isSelected
                              ? AppColors.primaryLight
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        slot.label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: !slot.available
                              ? Colors.grey.shade400
                              : isSelected
                              ? AppColors.onPrimaryLight
                              : AppColors.onBackgroundLight,
                          fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                          decoration: !slot.available
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              // Legend
              Row(
                children: [
                  _LegendDot(color: AppColors.primaryLight, label: 'Selected'),
                  const SizedBox(width: 14),
                  _LegendDot(
                      color: Colors.grey.shade200, label: 'Unavailable'),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Notes
// ─────────────────────────────────────────────────────────────────────────────

class _NotesSection extends StatefulWidget {
  final BookingViewModel vm;
  const _NotesSection({required this.vm});

  @override
  State<_NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<_NotesSection> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.vm.notes);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Notes',
      icon: Icons.notes_rounded,
      child: TextFormField(
        controller: _ctrl,
        maxLines: 3,
        onChanged: widget.vm.setNotes,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Any special instructions or notes for the technician…',
          hintStyle:
              AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade400),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primaryLight, width: 2),
          ),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Wallet balance + pay from wallet toggle
// ─────────────────────────────────────────────────────────────────────────────

class _WalletSection extends StatelessWidget {
  final BookingViewModel vm;
  const _WalletSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Wallet info
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.primaryLight, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wallet Balance',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70)),
                Text(
                  'SAR ${_fmt(vm.walletBalance)}',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // Pay from wallet toggle
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Pay from Wallet',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white70)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: vm.togglePayFromWallet,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 26,
                  decoration: BoxDecoration(
                    color: vm.payFromWallet
                        ? AppColors.primaryLight
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: vm.payFromWallet
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
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
// 7. Submit button + validation summary
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitSection extends StatelessWidget {
  final BookingViewModel vm;
  const _SubmitSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    // Show which required fields are still missing
    final missing = <String>[];
    if (vm.selectedDepartment == null) missing.add('Department');
    if (vm.selectedVehicle == null) missing.add('Vehicle');
    if (vm.selectedBranch == null) missing.add('Branch');
    if (vm.selectedDate == null) missing.add('Date');
    if (vm.selectedSlot == null) missing.add('Time Slot');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Validation hint
        if (missing.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.orange.shade600, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please complete: ${missing.join(', ')}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Submit Booking',
            isLoading: vm.isSubmitting,
            backgroundColor: vm.canSubmit
                ? AppColors.primaryLight
                : Colors.grey.shade300,
            textColor: vm.canSubmit
                ? AppColors.onPrimaryLight
                : Colors.grey.shade500,
            onPressed: vm.isSubmitting || !vm.canSubmit
                ? () {}
                : () async {
                    final success = await vm.submitBooking(context);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? '✅ Booking submitted! You will receive a confirmation shortly.'
                              : '❌ ${vm.errorMessage.isEmpty ? 'Something went wrong.' : vm.errorMessage}',
                        ),
                        backgroundColor: success
                            ? Colors.green.shade600
                            : Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                    if (success) vm.resetSubmitStatus();
                  },
          ),
        ),
      ],
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
                child:
                    Icon(icon, size: 16, color: AppColors.secondaryLight),
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
          const Divider(
              height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Generic styled dropdown that works for any model type
class _StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T) labelBuilder;
  final Widget Function(T) leadingBuilder;
  final void Function(T) onChanged;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.labelBuilder,
    required this.leadingBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      hint: Text(hint,
          style: AppTextStyles.bodyMedium
              .copyWith(color: Colors.grey.shade500)),
      decoration: InputDecoration(
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Row(
            children: [
              leadingBuilder(item),
              const SizedBox(width: 10),
              Expanded(
                child: Text(labelBuilder(item),
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300))),
        const SizedBox(width: 5),
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: Colors.grey.shade500)),
      ],
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
