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

  /// Verifică dacă utilizatorul are cel puțin [minIngredients] ingrediente în cămară.
  /// Ignoră documentul de inițializare '_init_'.
  Future<bool> hasEnoughIngredients({int minIngredients = 4}) async {
    final collection = _pantryCollection;
    if (collection == null) return false;

    final snapshot = await collection.get();

    final count = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return !data.containsKey('_init_');
    }).length;

    return count >= minIngredients;
  }

  /// Adaugă o listă de ingrediente în lista de cumpărături a utilizatorului.
  Future<void> addShoppingListItems(List<String> items) async {
    final user = _auth.currentUser;
    if (user == null || items.isEmpty) return;

    final batch = _firestore.batch();
    final collection = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('shoppingList');

    for (final item in items) {
      final docRef = collection.doc();
      // Adăugăm cu o cantitate default de 1
      batch.set(docRef, {
        'name': item,
        'quantity': 1,
        'unit': '',
        'checked': false,
      });
    }

    await batch.commit();
  }

  /// Returnează un stream cu lista de cumpărături.
  Stream<QuerySnapshot> getShoppingList() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('shoppingList')
        .snapshots();
  }

  /// Schimbă starea (bifat/nebifat) a unui element din lista de cumpărături.
  Future<void> toggleShoppingItem(String id, bool currentStatus) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('shoppingList')
        .doc(id)
        .update({'checked': !currentStatus});
  }

  /// Șterge un element din lista de cumpărături.
  Future<void> deleteShoppingItem(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('shoppingList')
        .doc(id)
        .delete();
  }
}
