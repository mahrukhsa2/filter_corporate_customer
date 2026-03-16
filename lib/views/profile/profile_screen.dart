import 'package:filter_corporate_customer/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/branch_model.dart';
import '../../models/profile_model.dart';
import '../../data/app_cache.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_alert.dart';
import '../Profile/profile_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/Profile/profile_screen.dart
// UI is unchanged — only wired to the real ViewModel/model shape.
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _billingAddressController = TextEditingController();
  final _contactPersonController  = TextEditingController();
  final _mobileController         = TextEditingController();

  bool _controllersInitialised = false;

  @override
  void dispose() {
    _billingAddressController.dispose();
    _contactPersonController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  /// Populate controllers once — guard with flag so pull-to-refresh
  /// re-initialises after _controllersInitialised is reset.
  void _initControllers(ProfileModel profile) {
    if (_controllersInitialised) return;
    _billingAddressController.text = profile.billingAddress;
    _contactPersonController.text  = profile.name;
    _mobileController.text         = profile.mobile;
    _controllersInitialised = true;
  }

  Future<void> _onSave(BuildContext context, ProfileViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    // Context is passed into the VM so AppAlert can show error dialogs
    final success = await vm.saveProfile(
      context:        context,
      billingAddress: _billingAddressController.text,
      contactPerson:  _contactPersonController.text,
      mobile:         _mobileController.text,
    );

    if (!mounted) return;

    // Errors are shown via AppAlert inside the VM.
    // Only show a success snackbar here.
    if (success) {
      AppAlert.snackbar(
        context,
        message:   'Profile updated successfully.',
        isSuccess: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: Consumer<ProfileViewModel>(
        builder: (context, vm, _) {

          // ── Loading state ────────────────────────────────────────────
          if (vm.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.backgroundLight,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primaryLight),
              ),
            );
          }

          // ── Error state (first load failed, no stale data) ───────────
          if (vm.profile == null) {
            return Scaffold(
              backgroundColor: AppColors.backgroundLight,
              body: Column(
                children: [
                  const CustomAppBar(title: 'Your Profile', showBackButton: true),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Could not load profile.\nPull down to retry.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => vm.refresh(context: context),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
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
                  ),
                ],
              ),
            );
          }

          // ── Loaded state ─────────────────────────────────────────────
          final profile = vm.profile!;
          _initControllers(profile);

          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Column(
              children: [
                const CustomAppBar(title: 'Your Profile', showBackButton: true),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryLight,
                    onRefresh: () async {
                      _controllersInitialised = false;
                      await vm.refresh(context: context);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            // ── Company Profile card ──────────────────
                            _SectionCard(
                              title: 'Company Profile',
                              icon:  Icons.business_outlined,
                              children: [
                                _ReadOnlyField(
                                  label: 'Company Name',
                                  value: profile.companyName.isNotEmpty
                                      ? profile.companyName
                                      : '-',
                                  icon: Icons.apartment_outlined,
                                ),
                                const SizedBox(height: 12),

                                _ReadOnlyField(
                                  label: 'Email',
                                  value: profile.email.isNotEmpty
                                      ? profile.email
                                      : '-',
                                  icon: Icons.mail_outline_rounded,
                                ),
                                const SizedBox(height: 12),
                                _ReadOnlyField(
                                  label: 'Credit Limit',
                                  value: 'SAR ${_fmt(profile.creditLimit)}',
                                  icon: Icons.credit_card_outlined,
                                ),
                                const SizedBox(height: 12),
                                _ReadOnlyField(
                                  label: 'Due Balance',
                                  value: 'SAR ${_fmt(profile.dueBalance)}',
                                  icon: Icons.receipt_long_outlined,
                                ),
                                const SizedBox(height: 20),

                                // ── Editable fields ───────────────────
                                CustomTextField(
                                  label:      'Billing Address',
                                  hint:       'Enter billing address',
                                  controller: _billingAddressController,
                                  prefixIcon: const Icon(
                                      Icons.location_on_outlined),
                                  validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Billing address is required'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label:      'Contact Person',
                                  hint:       'Enter contact person name',
                                  controller: _contactPersonController,
                                  prefixIcon:
                                  const Icon(Icons.person_outline),
                                  validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Contact person is required'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label:        'Mobile',
                                  hint:         'Enter mobile number',
                                  controller:   _mobileController,
                                  keyboardType: TextInputType.phone,
                                  prefixIcon:
                                  const Icon(Icons.phone_outlined),
                                  validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Mobile number is required'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                SizedBox(
                                  width: double.infinity,
                                  child: CustomButton(
                                    text:            'Save Changes',
                                    isLoading:       vm.isSaving,
                                    onPressed:       vm.isSaving
                                        ? () {}
                                        : () => _onSave(context, vm),
                                    backgroundColor: AppColors.primaryLight,
                                    textColor:       AppColors.onPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Wallet card ───────────────────────────
                            _SectionCard(
                              title: 'Wallet',
                              icon:  Icons.account_balance_wallet_outlined,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Wallet Balance',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                color: Colors
                                                    .grey.shade600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'SAR ${_fmt(profile.walletBalance)}',
                                            style: AppTextStyles.h2.copyWith(
                                              color: AppColors
                                                  .onBackgroundLight,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => Navigator.pushNamed(
                                          context, '/wallet-topup'),
                                      icon: const Icon(Icons.add_rounded,
                                          size: 18),
                                      label: const Text('Top-up Wallet'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        AppColors.primaryLight,
                                        foregroundColor:
                                        AppColors.onPrimaryLight,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        textStyle: AppTextStyles.bodyMedium
                                            .copyWith(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Allowed Branches card ─────────────────
                            _SectionCard(
                              title: 'Allowed Branches',
                              icon:  Icons.store_outlined,
                              children: [
                                if (profile.branches.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    child: Text(
                                      'No branches assigned to this account.',
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(
                                          color: Colors.grey.shade500),
                                    ),
                                  )
                                else
                                  ...profile.branches.map(
                                        (branch) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 10),
                                      child: Row(
                                        children: [
                                          Container(
                                            width:  8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: branch.isActive
                                                  ? Colors.green.shade500
                                                  : Colors.grey.shade400,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              branch.name,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                color: AppColors
                                                    .onBackgroundLight,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 10,
                                                vertical:   4),
                                            decoration: BoxDecoration(
                                              color: branch.isActive
                                                  ? Colors.green.shade50
                                                  : Colors.grey.shade100,
                                              borderRadius:
                                              BorderRadius.circular(
                                                  20),
                                            ),
                                            child: Text(
                                              branch.isActive
                                                  ? 'Active'
                                                  : 'Inactive',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: branch.isActive
                                                    ? Colors.green.shade700
                                                    : Colors.grey.shade600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await vm.loadAllBranches();
                                      if (!context.mounted) return;
                                      await showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => ChangeNotifierProvider.value(
                                          value: vm,
                                          child: _ManageBranchesSheet(vm: vm),
                                        ),
                                      );
                                      if (context.mounted) {
                                        vm.refresh(context: context);
                                      }
                                    },
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    label: const Text('Manage Branches'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                      AppColors.secondaryLight,
                                      side: BorderSide(
                                          color: AppColors.secondaryLight
                                              .withOpacity(0.4)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      textStyle: AppTextStyles.bodyMedium
                                          .copyWith(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String       title;
  final IconData     icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
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
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color:      AppColors.onBackgroundLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color:      AppColors.onBackgroundLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _fmt(double value) {
  final parts  = value.toStringAsFixed(0).split('');
  final buffer = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
    buffer.write(parts[i]);
  }
  return buffer.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// Manage Branches bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ManageBranchesSheet extends StatelessWidget {
  final ProfileViewModel vm;
  const _ManageBranchesSheet({required this.vm});

  @override
  Widget build(BuildContext context) {
    // Listen to vm so sheet rebuilds after add/remove
    final liveVm      = context.watch<ProfileViewModel>();
    final assigned    = liveVm.assignedBranchIds;
    final allBranches = liveVm.allBranches;
    final maxHeight  = MediaQuery.of(context).size.height * 0.80;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store_outlined,
                      size: 18, color: AppColors.secondaryLight),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manage Branches',
                          style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.onBackgroundLight)),
                      Text('Add or remove branches from your account',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade100),

          // Body
          Flexible(
            child: liveVm.isBranchesLoading
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryLight),
              ),
            )
                : allBranches.isEmpty
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store_outlined,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text('No branches available',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade400)),
                ],
              ),
            )
                : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              itemCount: allBranches.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (ctx, i) {
                final branch    = allBranches[i];
                final isAdded   = assigned.contains(branch.id);
                return _BranchTile(
                  branch:  branch,
                  isAdded: isAdded,
                  vm:      vm,
                );
              },
            ),
          ),

          // Close button
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20,
                MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Done',
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

// ── Branch tile — add / remove ────────────────────────────────────────────────

class _BranchTile extends StatefulWidget {
  final BranchModel      branch;
  final bool             isAdded;
  final ProfileViewModel vm;
  const _BranchTile({
    required this.branch,
    required this.isAdded,
    required this.vm,
  });

  @override
  State<_BranchTile> createState() => _BranchTileState();
}

class _BranchTileState extends State<_BranchTile> {
  bool _loading = false;

  Future<void> _toggle() async {
    setState(() => _loading = true);
    if (widget.isAdded) {
      await widget.vm.removeBranch(widget.branch.id);
    } else {
      await widget.vm.addBranch(widget.branch.id);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isAdded = widget.isAdded;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAdded
                  ? Colors.green.shade50
                  : AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.store_outlined,
                size: 16,
                color: isAdded
                    ? Colors.green.shade600
                    : Colors.grey.shade500),
          ),
          const SizedBox(width: 12),

          // Name + address
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.branch.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackgroundLight)),
                if (widget.branch.address.isNotEmpty)
                  Text(widget.branch.address,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade500, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Add / Remove button
          if (_loading)
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primaryLight),
            )
          else
            GestureDetector(
              onTap: _toggle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isAdded
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAdded
                        ? Colors.red.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAdded
                          ? Icons.remove_circle_outline_rounded
                          : Icons.add_circle_outline_rounded,
                      size: 14,
                      color: isAdded
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAdded ? 'Remove' : 'Add',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isAdded
                            ? Colors.red.shade600
                            : Colors.green.shade600,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}