import 'package:flutter/material.dart';
import 'package:geosociomap/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geosociomap/screens/signin_screen.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const HomeScreen();
          } else {
            return const SigninScreen();
          }
        },
      ),
    );
  }
}