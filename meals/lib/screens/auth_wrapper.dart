import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meals/screens/auth/login.dart';
import 'package:meals/screens/auth/verify_email.dart';
import 'package:meals/services/auth_service.dart';
import 'package:meals/screens/home.dart';
import 'package:meals/screens/tutorial_screen.dart';

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

          // Verifică în Firestore dacă tutorialul a fost parcurs
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final hasSeenTutorial =
                    userData['hasSeenTutorial'] ??
                    true; // true default pentru conturile vechi

                if (!hasSeenTutorial) {
                  return const TutorialScreen();
                }
              }

              // Altfel, arată ecranul principal al aplicației
              return const HomeScreen();
            },
          );
        }
        // Dacă nu există utilizator, arată ecranul de login
        return const LoginScreen();
      },
    );
  }
}
