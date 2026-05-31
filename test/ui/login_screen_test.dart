import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:jabatkopi/ui/login_screen.dart';
import 'package:jabatkopi/core/providers/auth_provider.dart';

void main() {
  testWidgets('LoginScreen has username, password fields and login button', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('JABAT KOPI'), findsWidgets);
    expect(find.text('LOGIN'), findsOneWidget); 
  });
}
