import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_auth_header.dart';
import 'login_view_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// lib/views/Login/login_view.dart
// UI is UNCHANGED. The only diff from the original:
//   _onLogin() passes `context` to vm.login() so AppAlert can show dialogs.
//   The vm now owns all error handling — no SnackBar here.
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey                = GlobalKey<FormState>();
  final _mobileEmailController  = TextEditingController();
  final _passwordController     = TextEditingController();

  @override
  void dispose() {
    _mobileEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin(LoginViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    // context is passed so the VM can show AppAlert dialogs
    final success = await vm.login(
      context,
      email:    _mobileEmailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else {
      vm.resetStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Consumer<LoginViewModel>(
        builder: (context, vm, _) {
          final isWide = MediaQuery.of(context).size.width > 600;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor:           Colors.transparent,
              statusBarIconBrightness:  Brightness.dark,
              statusBarBrightness:      Brightness.light,
            ),
            child: Scaffold(
              backgroundColor: AppColors.backgroundLight,
              body: isWide
                  ? _buildWideLayout(vm, context)
                  : _buildNarrowLayout(vm, context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNarrowLayout(LoginViewModel vm, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          CustomAuthHeader(
            title:          'Corporate Login',
            subtitle:       'Sign in to your corporate account',
            showBackButton: false,
          ),
          Transform.translate(
            offset: const Offset(0, -90),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _LoginCard(
                vm:                    vm,
                formKey:               _formKey,
                mobileEmailController: _mobileEmailController,
                passwordController:    _passwordController,
                onLogin:               () => _onLogin(vm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(LoginViewModel vm, BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.primaryLight,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/icon.png',
                    width: 120,
                    color: Colors.black,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.car_repair, size: 80, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Text('Corporate Login',
                      style: AppTextStyles.h2.copyWith(
                          color: AppColors.onPrimaryLight,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Sign in to your corporate account',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onPrimaryLight.withOpacity(0.7))),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.surfaceLight,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _LoginCard(
                      vm:                    vm,
                      formKey:               _formKey,
                      mobileEmailController: _mobileEmailController,
                      passwordController:    _passwordController,
                      onLogin:               () => _onLogin(vm),
                      elevated:              false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form card — unchanged from original
// ─────────────────────────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  final LoginViewModel vm;
  final GlobalKey<FormState> formKey;
  final TextEditingController mobileEmailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final bool elevated;

  const _LoginCard({
    required this.vm,
    required this.formKey,
    required this.mobileEmailController,
    required this.passwordController,
    required this.onLogin,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color:        AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: elevated
            ? [
                BoxShadow(
                    color:      Colors.black.withOpacity(0.10),
                    blurRadius: 24,
                    offset:     const Offset(0, 8)),
                BoxShadow(
                    color:      Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset:     const Offset(0, 2)),
              ]
            : null,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize:       MainAxisSize.min,
          children: [
            CustomTextField(
              label:         'Mobile / Email',
              hint:          'Enter your mobile or email',
              controller:    mobileEmailController,
              keyboardType:  TextInputType.emailAddress,
              prefixIcon:    const Icon(Icons.mail_outline_rounded),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Mobile / Email is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label:       'Password',
              hint:        'Enter your password',
              controller:  passwordController,
              obscureText: vm.obscurePassword,
              prefixIcon:  const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  vm.obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade500,
                ),
                onPressed: vm.togglePasswordVisibility,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                return null;
              },
            ),
            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/forgot-password'),
                style: TextButton.styleFrom(
                  padding:         EdgeInsets.zero,
                  minimumSize:     Size.zero,
                  tapTargetSize:   MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot Password?',
                  style: AppTextStyles.bodySmall.copyWith(
                    color:      AppColors.secondaryLight,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text:            'Sign In',
                onPressed:       vm.isLoading ? () {} : onLogin,
                isLoading:       vm.isLoading,
                backgroundColor: AppColors.primaryLight,
                textColor:       AppColors.onPrimaryLight,
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: RichText(
                  text: TextSpan(
                    text:  'New Company? ',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey.shade500),
                    children: [
                      TextSpan(
                        text:  'Register Here',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color:      AppColors.secondaryLight,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
