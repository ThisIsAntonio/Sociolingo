import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/screens/welcome_screen.dart';

void main() {
  testWidgets('App opens and closes correctly', (WidgetTester tester) async {
    print('Starting test: App opens and closes correctly');

    // Build the app and trigger a frame.
    await tester.pumpWidget(MyApp());
    print('App built successfully');

    // Verify that the WelcomeScreen is displayed initially.
    expect(find.byType(WelcomeScreen), findsOneWidget);
    print('WelcomeScreen displayed');

    // Simulate app "closure" by popping the top route off the navigator.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
    print('App simulated closure');

    // Note: The app cannot actually be closed in a test environment, but we can simulate lifecycle changes.

    // Re-open the app by re-pumping the widget tree.
    await tester.pumpWidget(MyApp());
    print('App re-opened successfully');

    // Verify that the WelcomeScreen is displayed again.
    expect(find.byType(WelcomeScreen), findsOneWidget);
    print('WelcomeScreen displayed after reopening');

    print('Test completed: App opens and closes correctly');
  });
}
