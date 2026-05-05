import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- FAVORITES ---

  /// Verifică dacă o rețetă este favorită
  Stream<bool> isFavorite(int recipeId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(recipeId.toString())
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  /// Adaugă sau șterge o rețetă de la favorite
  Future<void> toggleFavorite({
    required int recipeId,
    required String title,
    required String imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(recipeId.toString());

    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'id': recipeId,
        'title': title,
        'image': imageUrl,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Returnează un stream cu toate rețetele favorite ale utilizatorului
  Stream<QuerySnapshot> getFavorites() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .orderBy('savedAt', descending: true)
        .snapshots();
  }

  // --- HISTORY ---

  /// Adaugă o rețetă în istoric
  Future<void> addToHistory({
    required int recipeId,
    required String title,
    required String imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final historyRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('history');

    // Folosim set cu merge pentru a actualiza timestamp-ul dacă există deja
    await historyRef.doc(recipeId.toString()).set({
      'id': recipeId,
      'title': title,
      'image': imageUrl,
      'viewedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
