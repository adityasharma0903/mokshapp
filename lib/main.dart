import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/core/features/auth/data/repositories/auth_repository.dart';
import 'package:my_app/core/features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [Provider<AuthRepository>(create: (_) => AuthRepository())],
      child: MaterialApp(
        title: 'College App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
