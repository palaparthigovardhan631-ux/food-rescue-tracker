import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/models/user_model.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/role_selection_screen.dart';
import 'features/provider_dashboard/presentation/screens/provider_home_screen.dart';
import 'features/receiver_dashboard/presentation/screens/receiver_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await FCMService.initialize();
  } catch (e) {
    debugPrint("Firebase init note (running local demo mode or emulator): $e");
  }

  runApp(
    const ProviderScope(
      child: SmartFoodRescueApp(),
    ),
  );
}

class SmartFoodRescueApp extends ConsumerWidget {
  const SmartFoodRescueApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Smart Leftover & Food Rescue Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        // Fetch user profile and route to role-specific dashboard
        final profileAsync = ref.watch(userProfileStreamProvider);
        return profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const RoleSelectionScreen();
            }
            if (profile.role == UserRole.provider) {
              return const ProviderHomeScreen();
            } else {
              return const ReceiverHomeScreen();
            }
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const RoleSelectionScreen(),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const LoginScreen(),
    );
  }
}
