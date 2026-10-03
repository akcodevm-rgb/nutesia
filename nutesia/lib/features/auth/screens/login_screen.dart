import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/credit_provider.dart';
import '../../../core/services/device_service.dart';
import '../../../core/theme/app_theme.dart';

import '../../profile/providers/profile_provider.dart';
import '../../profile/providers/nutrition_space_provider.dart';

import '../../../shared/widgets/error_views/error_views.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const String testEmail = 'tester@nuto.app';
  static const String testPassword = 'NutoTester@2026';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInAnonymously(BuildContext context) async {
    DeviceService.clearCache();
    final auth = context.read<AuthProvider>();
    final success = await auth.signInAnonymously();
    if (success && context.mounted) {
      await context.read<UserProfileProvider>().load();
      if (context.mounted) {
        await context.read<NutritionSpaceProvider>().refresh();
        await context.read<CreditProvider>().refresh();
      }
    } else if (!success && context.mounted) {
      AppToast.showError(
        context,
        auth.appError ?? auth.errorMessage ?? 'Authentication failed',
        onAction: () => _signInAnonymously(context),
      );
    }
  }

  Future<void> _signInAsTester(BuildContext context) async {
    _emailController.text = testEmail;
    _passwordController.text = testPassword;
    DeviceService.clearCache();
    final auth = context.read<AuthProvider>();

    // Try signing in first
    bool success = await auth.signInWithEmail(email: testEmail, password: testPassword);
    if (!success) {
      // If user not created yet in Firebase Auth, automatically sign up
      success = await auth.signUpWithEmail(email: testEmail, password: testPassword);
    }

    if (success && context.mounted) {
      await context.read<UserProfileProvider>().load();
      if (context.mounted) {
        await context.read<NutritionSpaceProvider>().refresh();
        await context.read<CreditProvider>().refresh();
      }
    } else if (!success && context.mounted) {
      AppToast.showError(
        context,
        auth.appError ?? auth.errorMessage ?? 'Testing authentication failed',
        onAction: () => _signInAsTester(context),
      );
    }
  }

  Future<void> _submitEmailAuth(BuildContext context) async {
    DeviceService.clearCache();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final auth = context.read<AuthProvider>();

    final success = auth.isLoginMode
        ? await auth.signInWithEmail(email: email, password: password)
        : await auth.signUpWithEmail(email: email, password: password);

    if (success && context.mounted) {
      await context.read<UserProfileProvider>().load();
      if (context.mounted) {
        await context.read<NutritionSpaceProvider>().refresh();
        await context.read<CreditProvider>().refresh();
      }
    } else if (!success && context.mounted) {
      AppToast.showError(
        context,
        auth.appError ?? auth.errorMessage ?? 'Authentication failed',
        onAction: () => _submitEmailAuth(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final validationError = auth.appError is ValidationAppError
            ? (auth.appError as ValidationAppError).fieldErrors
            : const <String, String>{};

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.eco, size: 64, color: AppTheme.primary),
                    const Gap(16),
                    const Text(
                      'Welcome to Nutesia',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Gap(8),
                    Text(
                      auth.isLoginMode ? 'Sign in to continue' : 'Create a new account',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const Gap(24),

                    // Test Account Banner / Quick Sign-In
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bolt, color: AppTheme.primary, size: 20),
                              Gap(6),
                              Text(
                                'Test Account (Unlimited Credits)',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const Gap(6),
                          const SelectableText(
                            'Email: tester@nuto.app\nPassword: NutoTester@2026',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const Gap(10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: auth.isLoading ? null : () => _signInAsTester(context),
                              icon: const Icon(Icons.flash_on, size: 16, color: AppTheme.primary),
                              label: const Text(
                                '1-Tap Sign In as Tester',
                                style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.primary),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(24),

                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.email, color: Colors.white54),
                      ),
                    ),
                    InlineFieldError(errorText: validationError['email']),
                    const Gap(16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                      ),
                    ),
                    InlineFieldError(errorText: validationError['password']),
                    const Gap(24),
                    if (auth.isLoading)
                      const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    else ...[
                      ElevatedButton(
                        onPressed: () => _submitEmailAuth(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.background,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          auth.isLoginMode ? 'Sign In' : 'Sign Up',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Gap(16),
                      TextButton(
                        onPressed: () => auth.toggleMode(),
                        child: Text(
                          auth.isLoginMode ? "Don't have an account? Sign Up" : 'Already have an account? Sign In',
                          style: const TextStyle(color: AppTheme.primary),
                        ),
                      ),
                      const Gap(20),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: TextStyle(color: Colors.white54)),
                          ),
                          Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),
                      const Gap(20),
                      OutlinedButton.icon(
                        onPressed: () => _signInAnonymously(context),
                        icon: const Icon(Icons.person_outline, color: Colors.white),
                        label: const Text('Continue as Guest', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

