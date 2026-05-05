import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Metodă pentru sign-up care creează și documentul în Firestore
  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // 1. Creează utilizatorul cu Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        // Trimite email de verificare imediat după creare
        if (!user.emailVerified) {
          await user.sendEmailVerification();
        }

        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'createdAt': Timestamp.now(), // Folosește timestamp-ul serverului
          // Gamification init
          'level': 1,
          'currentXP': 0,
          'totalRecipesCooked': 0,
          'hasSeenTutorial': false,
        });

        // Initialize Default Pantry (Main)
        DocumentReference defaultPantryRef = await _firestore
            .collection('pantries')
            .add({
              'name': 'Main Pantry',
              'createdAt': Timestamp.now(),
              'ownerId': user.uid,
              'members': [user.uid],
            });

        await defaultPantryRef.collection('items').add({'_init_': true});

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('shoppingList')
            .add({'_init_': true});
      }

      return userCredential;
    } on FirebaseAuthException {
      // Propagăm excepția pentru a fi gestionată în UI.
      // Acest lucru permite afișarea unui mesaj specific utilizatorului.
      rethrow;
    }
  }

  // Metodă pentru a marca tutorialul ca fiind vizualizat
  Future<void> markTutorialAsSeen() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'hasSeenTutorial': true,
      });
    }
  }
}
