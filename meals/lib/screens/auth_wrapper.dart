import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meals/screens/tabs.dart';
import 'package:meals/screens/auth/login.dart';
import 'package:meals/screens/auth/verify_email.dart';
import 'package:meals/services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  AuthWrapper({super.key});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Așteaptă conexiunea
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Verifică dacă există un utilizator autentificat
        if (snapshot.hasData) {
          // Dacă email-ul nu este verificat, arată ecranul de verificare
          if (!snapshot.data!.emailVerified) {
            return const VerifyEmailScreen();
          }
          // Altfel, arată ecranul principal al aplicației
          return const TabsScreen();
        }
        // Dacă nu există utilizator, arată ecranul de login
        return const LoginScreen();
      },
    );
  }
}
