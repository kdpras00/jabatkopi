import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabatkopi/ui/login_screen.dart';

void main() {
  testWidgets('LoginScreen has username, password fields and login button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Login Jabat Kopi'), findsOneWidget); // AppBar title
    expect(find.text('Login'), findsWidgets); // Button text
  });
}
