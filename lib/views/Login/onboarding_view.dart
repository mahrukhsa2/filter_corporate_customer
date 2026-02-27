import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/custom_auth_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewScreenState();
}

class _OnboardingViewScreenState extends State<OnboardingView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _companyNameController   = TextEditingController();
  final _vatNumberController     = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _mobileEmailController   = TextEditingController();
  final _passwordController      = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading       = false;

  // Store selection
  final Map<String, bool> _selectedStores = {
    'Riyadh Main': false,
    'Jeddah':      false,
    'Dammam':      false,
    'All':         false,
  };

  // Referred By dropdown
  final List<String> _referralOptions = [
    'Mr. Ahmed - Sales',
    'Mr. Khalid - Sales',
    'Ms. Sara - Marketing',
    'Other',
  ];
  String? _selectedReferral;

  @override
  void dispose() {
    _companyNameController.dispose();
    _vatNumberController.dispose();
    _contactPersonController.dispose();
    _mobileEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onStoreToggle(String store, bool? value) {
    setState(() {
      if (store == 'All') {
        final newVal = value ?? false;
        _selectedStores.updateAll((key, _) => newVal);
      } else {
        _selectedStores[store] = value ?? false;
        final individuals = ['Riyadh Main', 'Jeddah', 'Dammam'];
        _selectedStores['All'] =
            individuals.every((s) => _selectedStores[s] == true);
      }
    });
  }

  void _navigateToLogin() =>
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);

  void _onRegister() {
    if (!_formKey.currentState!.validate()) return;

    final anyStoreSelected = _selectedStores.values.any((v) => v);
    if (!anyStoreSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one store')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: implement real registration API call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Registered successfully! Admin will verify your account.')),
    );
    _navigateToLogin();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:         Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness:    Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        // ── Single scrollable column – same pattern as login ────────────
        body: SingleChildScrollView(
          child: Column(
            children: [
              // ── Yellow header ─────────────────────────────────────────
              CustomAuthHeader(
                title: 'Corporate Registration',
                subtitle: 'Create your corporate account',
                showBackButton: true,
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
                                prefixIcon:
                                const Icon(Icons.business_outlined),
                                validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Company name is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'VAT Number *',
                                hint: 'Enter VAT number',
                                controller: _vatNumberController,
                                keyboardType: TextInputType.number,
                                prefixIcon: const Icon(
                                    Icons.receipt_long_outlined),
                                validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'VAT number is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'Contact Person *',
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
                                label: 'Mobile / Email (User ID) *',
                                hint: 'Enter mobile or email',
                                controller: _mobileEmailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon:
                                const Icon(Icons.phone_outlined),
                                validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Mobile / Email is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'Password *',
                                hint: 'Enter password',
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                prefixIcon:
                                const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Password is required';
                                  if (v.length < 6)
                                    return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Select Stores ─────────────────────────────
                          _SectionCard(
                            children: [
                              Text(
                                'Select Stores',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onBackgroundLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _StoreCheckbox(
                                    label: 'Riyadh Main',
                                    value: _selectedStores['Riyadh Main']!,
                                    onChanged: (v) =>
                                        _onStoreToggle('Riyadh Main', v),
                                  ),
                                  const SizedBox(width: 12),
                                  _StoreCheckbox(
                                    label: 'Jeddah',
                                    value: _selectedStores['Jeddah']!,
                                    onChanged: (v) =>
                                        _onStoreToggle('Jeddah', v),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  _StoreCheckbox(
                                    label: 'Dammam',
                                    value: _selectedStores['Dammam']!,
                                    onChanged: (v) =>
                                        _onStoreToggle('Dammam', v),
                                  ),
                                  const SizedBox(width: 12),
                                  _StoreCheckbox(
                                    label: 'All',
                                    value: _selectedStores['All']!,
                                    onChanged: (v) =>
                                        _onStoreToggle('All', v),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Referred By ───────────────────────────────
                          _SectionCard(
                            children: [
                              Text(
                                'Referred By',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onBackgroundLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedReferral,
                                hint: Text(
                                  'Select referral',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: Colors.grey),
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                      Icons.people_outline),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.primaryLight),
                                  ),
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 12),
                                ),
                                items: _referralOptions
                                    .map((ref) => DropdownMenuItem(
                                  value: ref,
                                  child: Text(ref,
                                      style: AppTextStyles
                                          .bodyMedium),
                                ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedReferral = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // ── Register button ───────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: 'Register',
                              onPressed: _onRegister,
                              isLoading: _isLoading,
                              backgroundColor: AppColors.primaryLight,
                              textColor: AppColors.onPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Already have ID? ──────────────────────────
                          Center(
                            child: TextButton(
                              onPressed: _navigateToLogin,
                              child: RichText(
                                text: TextSpan(
                                  text: 'Already have an ID? ',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: Colors.grey.shade600),
                                  children: [
                                    TextSpan(
                                      text: 'Login',
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(
                                        color: AppColors.secondaryLight,
                                        fontWeight: FontWeight.w700,
                                        decoration:
                                        TextDecoration.underline,
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
    return Expanded(
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryLight,
            checkColor: AppColors.onPrimaryLight,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)),
          ),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.onBackgroundLight),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}