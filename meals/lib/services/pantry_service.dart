import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pantry_item.dart';
import '../models/recipe_detail.dart';

class PantryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stocăm ID-ul cămării selectate pentru a-l sincroniza între ecrane
  static String activePantryId = '';

  // --- MULTIPLE PANTRIES MANAGEMENT ---

  Stream<QuerySnapshot> getUserPantries() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('pantries')
        .where('members', arrayContains: user.uid)
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> createPantry(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final docRef = await _firestore.collection('pantries').add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': user.uid,
      'members': [user.uid],
    });
    await docRef.collection('items').add({'_init_': true});
  }

  Future<void> updatePantryName(String pantryId, String newName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('pantries').doc(pantryId).update({
      'name': newName,
    });
  }

  Future<void> deletePantry(String pantryId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final pantryRef = _firestore.collection('pantries').doc(pantryId);

    // Ștergem elementele din subcolecția 'items' pentru a nu lăsa documente orfane
    final itemsSnapshot = await pantryRef.collection('items').get();
    final batch = _firestore.batch();
    for (final doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(pantryRef);
    await batch.commit();
  }

  Future<void> joinPantry(String pantryId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final pantryRef = _firestore.collection('pantries').doc(pantryId);
    final doc = await pantryRef.get();

    if (!doc.exists) {
      throw Exception('Pantry not found. Please check the code and try again.');
    }

    await pantryRef.update({
      'members': FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> leavePantry(String pantryId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('pantries').doc(pantryId).update({
      'members': FieldValue.arrayRemove([user.uid]),
    });
  }

  // Obține referința către colecția 'items' a unui pantry specific
  CollectionReference? _getPantryCollection([String? pantryId]) {
    final user = _auth.currentUser;
    if (user == null || pantryId == null || pantryId.isEmpty) return null;
    return _firestore.collection('pantries').doc(pantryId).collection('items');
  }

  // Stream pentru a asculta modificările în timp real
  Stream<List<PantryItem>> getPantryItems([String? pantryId]) {
    final collection = _getPantryCollection(pantryId);
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

  Future<void> addPantryItem(PantryItem item, [String? pantryId]) async {
    await _getPantryCollection(pantryId)?.add(item.toFirestore());
  }

  Future<void> deletePantryItem(String id, [String? pantryId]) async {
    await _getPantryCollection(pantryId)?.doc(id).delete();
  }

  /// Verifică dacă utilizatorul are cel puțin [minIngredients] ingrediente în cămară.
  /// Ignoră documentul de inițializare '_init_'.
  Future<bool> hasEnoughIngredients({
    String? pantryId,
    int minIngredients = 4,
  }) async {
    final collection = _getPantryCollection(pantryId);
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

  /// Convertește cantitatea rețetei în unitatea de măsură folosită în cămară.
  double _getConvertedAmount(
    double recipeAmount,
    String recipeUnit,
    String pantryUnit,
  ) {
    final rUnit = recipeUnit.toLowerCase().trim();
    final pUnit = pantryUnit.toLowerCase().trim();

    if (rUnit == pUnit) return recipeAmount;

    double baseAmount = recipeAmount;

    // 1. Aducem cantitatea rețetei la o bază comună (grame / mililitri)
    if (rUnit == 'kg' || rUnit == 'l')
      baseAmount = recipeAmount * 1000;
    else if (rUnit == 'tbsp' ||
        rUnit == 'tbsps' ||
        rUnit == 'Tbsp' ||
        rUnit == 'tablespoon' ||
        rUnit == 'tablespoons' ||
        rUnit == 'tbs')
      baseAmount = recipeAmount * 15;
    else if (rUnit == 'tsp' ||
        rUnit == 'tsps' ||
        rUnit == 'teaspoon' ||
        rUnit == 'teaspoons')
      baseAmount = recipeAmount * 5;
    else if (rUnit == 'cup' || rUnit == 'cups')
      baseAmount = recipeAmount * 240;
    else if (rUnit == 'oz' || rUnit == 'ounce' || rUnit == 'ounces')
      baseAmount = recipeAmount * 28.35;
    else if (rUnit == 'lb' ||
        rUnit == 'lbs' ||
        rUnit == 'pound' ||
        rUnit == 'pounds')
      baseAmount = recipeAmount * 453.6;

    // 2. Convertim din baza comună (g/ml) în unitatea setată în cămară (ex. dacă în cămară ai kg, împărțim gramele la 1000)
    if (pUnit == 'kg' || pUnit == 'l') {
      return baseAmount / 1000;
    }

    return baseAmount;
  }

  /// Șterge din Pantry ingredientele care se potrivesc exact cu numele celor folosite în rețetă.
  /// Returnează o listă de ingrediente care au ajuns la o cantitate critică.
  Future<List<String>> consumeRecipeIngredients(
    List<RecipeIngredient> recipeIngredients, [
    String? pantryId,
  ]) async {
    final collection = _getPantryCollection(pantryId);
    if (collection == null || recipeIngredients.isEmpty) return [];

    final snapshot = await collection.get();
    final batch = _firestore.batch();
    final List<String> lowStockItems = [];

    for (final recipeIng in recipeIngredients) {
      final targetName = recipeIng.name.toLowerCase();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('_init_')) continue;

        final pantryName = (data['name'] as String).toLowerCase();

        if (pantryName == targetName) {
          final pantryUnit = data['unit'] as String? ?? '';
          final currentQuantity = (data['quantity'] as num?)?.toDouble() ?? 0.0;

          final amountToConsume = _getConvertedAmount(
            recipeIng.amount,
            recipeIng.unit,
            pantryUnit,
          );

          double newQuantity = currentQuantity - amountToConsume;
          // Aproximăm rezultatul la maxim 2 zecimale (ex: 1.333334 -> 1.33)
          newQuantity = (newQuantity * 100).roundToDouble() / 100;

          if (newQuantity <= 0) {
            batch.delete(doc.reference);
          } else {
            batch.update(doc.reference, {'quantity': newQuantity});

            // Setăm un prag dinamic de avertizare în funcție de unitatea de măsură
            double threshold = 0.05; // Default pentru kg, litri, etc.
            if (pantryUnit == 'g' || pantryUnit == 'ml') {
              threshold = 10.0; // 10 grame / mililitri
            } else if (pantryUnit == 'pcs') {
              threshold = 0.5; // Jumătate de bucată
            }

            if (newQuantity <= threshold) {
              lowStockItems.add(data['name'] as String);
            }
          }
          break; // Trecem la următorul ingredient după ce i-am actualizat starea acestuia
        }
      }
    }

    await batch.commit();
    return lowStockItems;
  }
}
