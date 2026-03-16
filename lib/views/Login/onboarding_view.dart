import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/referral_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/custom_auth_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/referral_model.dart';
import 'registration_view_model.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewScreenState();
}

class _OnboardingViewScreenState extends State<OnboardingView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _companyNameController    = TextEditingController();
  final _vatNumberController      = TextEditingController();
  final _contactPersonController  = TextEditingController();
  final _emailController          = TextEditingController();
  final _passwordController       = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _companyNameController.dispose();
    _vatNumberController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToLogin() =>
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);

  Future<void> _onRegister() async {
    final vm = context.read<RegistrationViewModel>();

    if (!_formKey.currentState!.validate()) return;

    if (!vm.hasSelectedStores) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one store'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await vm.register(
      context:       context,
      companyName:   _companyNameController.text,
      vatNumber:     _vatNumberController.text,
      contactPerson: _contactPersonController.text,
      email:         _emailController.text,
      password:      _passwordController.text,
      // mobile:        "+966",
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.successMessage),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _navigateToLogin();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Consumer<RegistrationViewModel>(
          builder: (context, vm, _) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // ── Yellow header ─────────────────────────────────────────
                  CustomAuthHeader(
                    title: 'Corporate Registration',
                    subtitle: 'Create your corporate account',
                    showBackButton: Navigator.of(context).canPop(),
                  ),

                  // ── White card overlapping the header ─────────────────────
                  Transform.translate(
                    offset: const Offset(0, -90),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                              // ── Company Details ───────────────────────────
                              _SectionCard(
                                children: [
                                  CustomTextField(
                                    label: 'Company Name *',
                                    hint: 'Enter company name',
                                    controller: _companyNameController,
                                    prefixIcon: const Icon(Icons.business_outlined),
                                    validator: (v) => (v == null || v.trim().isEmpty)
                                        ? 'Company name is required' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'VAT Number *',
                                    hint: 'Enter VAT number',
                                    controller: _vatNumberController,
                                    prefixIcon: const Icon(Icons.receipt_long_outlined),
                                    validator: (v) => (v == null || v.trim().isEmpty)
                                        ? 'VAT number is required' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Contact Person *',
                                    hint: 'Enter contact person name',
                                    controller: _contactPersonController,
                                    prefixIcon: const Icon(Icons.person_outline),
                                    validator: (v) => (v == null || v.trim().isEmpty)
                                        ? 'Contact person is required' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Email *',
                                    hint: 'Enter email address',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      final emailRegex = RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                      if (!emailRegex.hasMatch(v.trim())) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Password *',
                                    hint: 'Enter password',
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined),
                                      onPressed: () => setState(
                                              () => _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (v.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // ── Select Stores ─────────────────────────────
                              _SectionCard(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Select Stores *',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.onBackgroundLight,
                                        ),
                                      ),
                                      if (vm.stores.isNotEmpty)
                                        TextButton(
                                          onPressed: () =>
                                              vm.toggleAllStores(!vm.allStoresSelected),
                                          child: Text(
                                            vm.allStoresSelected
                                                ? 'Deselect All'
                                                : 'Select All',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.primaryLight,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (vm.stores.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                        'No branches available. Please contact support.',
                                        style: AppTextStyles.bodySmall
                                            .copyWith(color: Colors.grey.shade600),
                                      ),
                                    )
                                  else
                                    ...vm.stores.map((store) => _StoreCheckbox(
                                      label: store.name,
                                      value: store.isSelected,
                                      onChanged: (_) => vm.toggleStore(store.id),
                                    )),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // ── Referred By ───────────────────────────────
                              _SectionCard(
                                children: [
                                  Text(
                                    'Referred By (Optional)',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onBackgroundLight,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (vm.referrals.isEmpty)
                                    Text(
                                      'No referrals available.',
                                      style: AppTextStyles.bodySmall
                                          .copyWith(color: Colors.grey.shade500),
                                    )
                                  else
                                    DropdownButtonFormField<ReferralModel>(
                                      value: vm.selectedReferral,
                                      hint: Text(
                                        'Select referral',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(color: Colors.grey),
                                      ),
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.people_outline),
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide:
                                          BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: AppColors.primaryLight),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 12),
                                      ),
                                      // Items come from AppCache.referrals via VM
                                      items: vm.referrals
                                          .map((ref) => DropdownMenuItem<ReferralModel>(
                                        value: ref,
                                        child: Text(ref.displayName,
                                            style: AppTextStyles.bodyMedium),
                                      ))
                                          .toList(),
                                      onChanged: (ref) => vm.selectReferral(ref),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // ── Register button ───────────────────────────
                              SizedBox(
                                width: double.infinity,
                                child: CustomButton(
                                  text: 'Register',
                                  onPressed: vm.isLoading ? () {} : _onRegister,
                                  isLoading: vm.isLoading,
                                  backgroundColor: AppColors.primaryLight,
                                  textColor: AppColors.onPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // ── Already have ID? ──────────────────────────
                              Center(
                                child: TextButton(
                                  onPressed: vm.isLoading ? null : _navigateToLogin,
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Already have an ID? ',
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(color: Colors.grey.shade600),
                                      children: [
                                        TextSpan(
                                          text: 'Login',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.secondaryLight,
                                            fontWeight: FontWeight.w700,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
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
      ),
    );
  }
}

// ─── Helper Widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

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
        children: children,
      ),
    );
  }
}

class _StoreCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _StoreCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryLight,
            checkColor: AppColors.onPrimaryLight,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.onBackgroundLight),
            ),
          ),
        ],
      ),
    );
  }
}