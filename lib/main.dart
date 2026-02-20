import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/hive/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'features/challenge/provider/challenge_provider.dart';
import 'features/challenge/view/analytics_screen.dart';
import 'features/challenge/view/challenge_detail_screen.dart';
import 'features/challenge/view/create_challenge_screen.dart';
import 'features/home/view/home_screen.dart';
import 'features/home/view/splash_screen.dart';
import 'features/profile/provider/profile_provider.dart';
import 'features/profile/view/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialise Hive (opens both boxes) ──────────────────────────────────────
  await HiveService.init();

  runApp(const SaveStreakApp());
}

class SaveStreakApp extends StatelessWidget {
  const SaveStreakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChallengeProvider>(
          create: (_) => ChallengeProvider(),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'SaveStreak',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: AppConstants.splashRoute,
        routes: {
          AppConstants.splashRoute: (_) => const SplashScreen(),
          AppConstants.homeRoute: (_) => const HomeScreen(),
          AppConstants.createRoute: (_) => const CreateChallengeScreen(),
          AppConstants.detailRoute: (_) => const ChallengeDetailScreen(),
          AppConstants.analyticsRoute: (_) => const AnalyticsScreen(),
          AppConstants.profileRoute: (_) => const ProfileScreen(),
        },
      ),
    );
  }
}
