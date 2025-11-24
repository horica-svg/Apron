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
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'createdAt': Timestamp.now(), // Folosește timestamp-ul serverului
        });
      }

      await _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('pantry')
          .add({'_init_': true});

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('shoppingList')
          .add({'_init_': true});

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Poți gestiona erorile aici (ex: email deja folosit)
      print(e.message);
      return null;
    }
  }
}
