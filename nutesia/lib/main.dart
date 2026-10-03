import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/providers/auth_provider.dart';
import 'core/providers/credit_provider.dart';
import 'core/providers/rewarded_ad_provider.dart';
import 'core/services/analytics_service.dart';
import 'core/services/config_service.dart';
import 'core/theme/app_theme.dart';
import 'features/analytics/providers/analytics_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/food_log/providers/add_food_provider.dart';
import 'features/food_log/providers/confirm_food_provider.dart';
import 'features/home/providers/home_provider.dart';
import 'features/home/providers/micro_section_provider.dart';
import 'features/home/providers/water_provider.dart';
import 'features/home/screens/home_screen.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/onboarding/screens/profile_setup_screen.dart';
import 'features/profile/providers/nutrition_space_provider.dart';
import 'features/profile/providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load runtime configuration for both native and web.
  await AppConfig.init();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('MobileAds initialization warning: $e');
    }
  }

  // Native status bar & orientation configuration
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Global production error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[PlatformDispatcher Error] $error');
    return true;
  };

  // Graceful fallback UI for unexpected widget build errors in production
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: AppTheme.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
              const Gap(16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const Gap(8),
              const Text(
                'An unexpected error occurred. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CreditProvider()),
        ChangeNotifierProvider(create: (_) => RewardedAdProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => NutritionSpaceProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => WaterProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => AddFoodProvider()),
        ChangeNotifierProvider(create: (_) => ConfirmFoodProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => MicroSectionProvider()),
      ],
      child: const NutoApp(),
    ),
  );
}

class NutoApp extends StatelessWidget {
  const NutoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutesia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorObservers: [AnalyticsService.instance.observer],
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading && auth.user == null) {
          return const _SplashScreen();
        }
        if (auth.isAuthenticated) {
          return const _AppRouter();
        }
        return const LoginScreen();
      },
    );
  }
}

/// Routes to onboarding or home based on whether user profile exists.
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProfileProvider, NutritionSpaceProvider>(
      builder: (context, profileProvider, spaceProvider, _) {
        if (profileProvider.isLoading) {
          return const _SplashScreen();
        }

        final user = profileProvider.user;
        if (user == null || !user.isProfileComplete) {
          return const ProfileSetupScreen();
        }

        // Ensure nutrition space fallback is active for this user
        if (spaceProvider.space == null || spaceProvider.space!.profiles.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            spaceProvider.initFromUser(user);
          });
        }

        return const HomeScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text('🥗', style: TextStyle(fontSize: 44)),
              ),
            ),
            const Gap(20),
            Text(
              'Nutesia',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    letterSpacing: 1.2,
                  ),
            ),
            const Gap(8),
            const Text(
              'Smart Nutrition Tracking',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const Gap(48),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
