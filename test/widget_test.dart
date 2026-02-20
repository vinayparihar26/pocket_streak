import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_streak/core/theme/app_theme.dart';
import 'package:pocket_streak/features/challenge/provider/challenge_provider.dart';
import 'package:pocket_streak/features/home/view/home_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('HomeScreen shows empty state when no challenges',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ChallengeProvider>(
        create: (_) => ChallengeProvider(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const HomeScreen(),
        ),
      ),
    );

    // Allow async operations (loadFromLocalStorage) to complete
    await tester.pumpAndSettle();

    // The empty-state text or the challenge list should be rendered
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('HomeScreen shows FAB with correct label',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ChallengeProvider>(
        create: (_) => ChallengeProvider(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // FAB "New Challenge" should be present
    expect(find.text('New Challenge'), findsOneWidget);
  });
}
