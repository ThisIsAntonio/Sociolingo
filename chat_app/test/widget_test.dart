import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/screens/welcome_screen.dart';

void main() {
  testWidgets('showComingSoonDialog displays the dialog',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());
    print('App built successfully');

    // Find the first SocialButton in the widget tree.
    final socialButtonFinder = find.byType(SocialButton).first;

    // Verify that the SocialButton is found.
    expect(socialButtonFinder, findsOneWidget);
    print('SocialButton found');

    // Tap the button to trigger the dialog.
    await tester.tap(socialButtonFinder);
    print('SocialButton tapped');
    await tester.pumpAndSettle(); // Wait for the dialog to appear.

    // Verify that the dialog appears.
    expect(find.byType(AlertDialog), findsOneWidget);
    print('AlertDialog displayed');

    // Tap the OK button to dismiss the dialog.
    final okButtonFinder = find.widgetWithText(TextButton, 'OK');
    expect(okButtonFinder, findsOneWidget);
    print('OK button found in AlertDialog');

    await tester.tap(okButtonFinder);
    print('OK button tapped');
    await tester.pumpAndSettle(); // Wait for the dialog to disappear.

    // Verify that the dialog is no longer visible.
    expect(find.byType(AlertDialog), findsNothing);
    print('AlertDialog dismissed');
  });
}
