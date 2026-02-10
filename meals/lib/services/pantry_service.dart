import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pantry_item.dart';

class PantryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obține referința către colecția 'pantry' a utilizatorului logat
  CollectionReference? get _pantryCollection {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('pantry');
  }

  // Stream pentru a asculta modificările în timp real
  Stream<List<PantryItem>> getPantryItems() {
    final collection = _pantryCollection;
    if (collection == null) return Stream.value([]);

    return collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Ignorăm documentul de inițializare '_init_' dacă există
            if (data.containsKey('_init_')) return null;
            return PantryItem.fromFirestore(data, doc.id);
          })
          .whereType<PantryItem>() // Elimină elementele null
          .toList();
    });
  }

  Future<void> addPantryItem(PantryItem item) async {
    await _pantryCollection?.add(item.toFirestore());
  }

  Future<void> deletePantryItem(String id) async {
    await _pantryCollection?.doc(id).delete();
  }
}
