import 'package:filter_corporate_customer/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/profile_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'profile_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Editable field controllers
  final _billingAddressController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _mobileController = TextEditingController();

  bool _controllersInitialised = false;

  @override
  void dispose() {
    _billingAddressController.dispose();
    _contactPersonController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  /// Populate controllers once the profile data has loaded
  void _initControllers(ProfileModel profile) {
    if (_controllersInitialised) return;
    _billingAddressController.text = profile.billingAddress;
    _contactPersonController.text = profile.contactPerson;
    _mobileController.text = profile.mobile;
    _controllersInitialised = true;
  }

  Future<void> _onSave(ProfileViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await vm.saveProfile(
      billingAddress: _billingAddressController.text,
      contactPerson: _contactPersonController.text,
      mobile: _mobileController.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Profile updated successfully.' : vm.errorMessage,
        ),
        backgroundColor: success ? Colors.green.shade600 : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: Consumer<ProfileViewModel>(
        builder: (context, vm, _) {
          // Show loader while fetching
          if (vm.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.backgroundLight,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primaryLight),
              ),
            );
          }

          final profile = vm.profile!;
          _initControllers(profile);

          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Column(
              children: [
              CustomAppBar(title: "Your Profile", showBackButton: true,),
                // ── Scrollable body ───────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryLight,
                    onRefresh: () async {
                      _controllersInitialised = false;
                      await vm.refresh();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Company Profile card ──────────────────────
                            _SectionCard(
                              title: 'Company Profile',
                              icon: Icons.business_outlined,
                              children: [
                                // Read-only fields
                                _ReadOnlyField(
                                  label: 'Company Name',
                                  value: profile.companyName,
                                  icon: Icons.apartment_outlined,
                                ),
                                const SizedBox(height: 12),
                                _ReadOnlyField(
                                  label: 'VAT Number',
                                  value: profile.vatNumber,
                                  icon: Icons.receipt_long_outlined,
                                ),
                                const SizedBox(height: 20),

                                // Editable fields
                                CustomTextField(
                                  label: 'Billing Address',
                                  hint: 'Enter billing address',
                                  controller: _billingAddressController,
                                  prefixIcon:
                                      const Icon(Icons.location_on_outlined),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Billing address is required'
                                          : null,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Contact Person',
                                  hint: 'Enter contact person name',
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
                                  label: 'Mobile',
                                  hint: 'Enter mobile number',
                                  controller: _mobileController,
                                  keyboardType: TextInputType.phone,
                                  prefixIcon:
                                      const Icon(Icons.phone_outlined),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Mobile number is required'
                                          : null,
                                ),
                                const SizedBox(height: 20),

                                // Save button
                                SizedBox(
                                  width: double.infinity,
                                  child: CustomButton(
                                    text: 'Save Changes',
                                    isLoading: vm.isSaving,
                                    onPressed: vm.isSaving
                                        ? () {}
                                        : () => _onSave(vm),
                                    backgroundColor: AppColors.primaryLight,
                                    textColor: AppColors.onPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Wallet card ───────────────────────────────
                            _SectionCard(
                              title: 'Wallet',
                              icon: Icons.account_balance_wallet_outlined,
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
                                            style:
                                                AppTextStyles.bodySmall.copyWith(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'SAR ${_fmt(profile.walletBalance)}',
                                            style: AppTextStyles.h2.copyWith(
                                              color: AppColors.onBackgroundLight,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Top-up button
                                    ElevatedButton.icon(
                                      onPressed: () => Navigator.pushNamed(
                                          context, '/wallet-topup'),
                                      icon: const Icon(Icons.add_rounded,
                                          size: 18),
                                      label: const Text('Top-up Wallet'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryLight,
                                        foregroundColor:
                                            AppColors.onPrimaryLight,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
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

                            // ── Allowed Branches card ─────────────────────
                            _SectionCard(
                              title: 'Allowed Branches',
                              icon: Icons.store_outlined,
                              children: [
                                ...profile.branches.map(
                                  (branch) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
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
                                              color:
                                                  AppColors.onBackgroundLight,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: branch.isActive
                                                ? Colors.green.shade50
                                                : Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            branch.isActive
                                                ? 'Active'
                                                : 'Inactive',
                                            style:
                                                AppTextStyles.bodySmall.copyWith(
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

                                // Manage Branches button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pushNamed(
                                        context, '/manage-branches'),
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
                                            BorderRadius.circular(12),
                                      ),
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
// Reusable section card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
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
          // Card title row
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
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Read-only info row
// ─────────────────────────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
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
        Column(
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
                color: AppColors.onBackgroundLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Number formatter
// ─────────────────────────────────────────────────────────────────────────────

String _fmt(double value) {
  final parts = value.toStringAsFixed(0).split('');
  final buffer = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    if (i > 0 && (parts.length - i) % 3 == 0) buffer.write(',');
    buffer.write(parts[i]);
  }
  return buffer.toString();
}
