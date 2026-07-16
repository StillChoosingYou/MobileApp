import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pgpc_campus_app/features/auth/login_screen.dart';
import 'package:pgpc_campus_app/models/app_user.dart';

void main() {
  testWidgets('LoginScreen shows ID and password fields for a Student role', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(role: UserRole.student),
        ),
      ),
    );

    expect(find.text('Student Login'), findsOneWidget);
    expect(find.text('Student Number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('LoginScreen shows Employee ID label for non-student roles', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(role: UserRole.registrar),
        ),
      ),
    );

    expect(find.text('Employee ID'), findsOneWidget);
  });
}
