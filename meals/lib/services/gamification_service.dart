import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Calculează XP-ul necesar pentru a trece la nivelul următor.
  /// Ex: Nivel 1 cere 100 XP, Nivel 2 cere 200 XP, etc.
  int getXpForNextLevel(int currentLevel) {
    return currentLevel * 100;
  }

  /// Returnează titlul (Rank-ul) bazat pe nivelul curent
  String getRankForLevel(int level) {
    if (level < 5) return 'Kitchen Novice';
    if (level < 10) return 'Amateur Cook';
    if (level < 20) return 'Sous-Chef';
    if (level < 35) return 'Head Chef';
    if (level < 50) return 'Master Chef';
    return 'Culinary Legend';
  }

  /// Calculează XP-ul câștigat pentru prepararea unei rețete specifice
  int calculateEarnedXP(
    int readyInMinutes,
    int ingredientCount, {
    bool isFirstTime = true,
  }) {
    int baseXP = 10;
    int timeXP = (readyInMinutes / 10).floor(); // 1 XP pt fiecare 10 minute
    int ingredientsXP = ingredientCount * 2; // 2 XP pt fiecare ingredient
    int totalXP = baseXP + timeXP + ingredientsXP;
    return isFirstTime ? totalXP : (totalXP / 2).ceil();
  }

  /// Marchează o rețetă ca fiind gătită, actualizează nivelul și XP-ul
  Future<Map<String, dynamic>> markRecipeAsCooked({
    required int recipeId,
    required String title,
    required String imageUrl,
    required int readyInMinutes,
    required int ingredientCount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final userRef = _firestore.collection('users').doc(user.uid);

    // Verificăm dacă rețeta a mai fost gătită anterior
    final previouslyCooked = await userRef
        .collection('cooked_meals')
        .where('recipeId', isEqualTo: recipeId)
        .limit(1)
        .get();
    final bool isFirstTime = previouslyCooked.docs.isEmpty;

    // Calculăm XP-ul de adăugat
    final int earnedXP = calculateEarnedXP(
      readyInMinutes,
      ingredientCount,
      isFirstTime: isFirstTime,
    );

    bool leveledUp = false;
    int newLevel = 1;

    // Folosim o tranzacție pentru a ne asigura că citirea și scrierea se fac atomic
    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);

      if (!userSnapshot.exists) {
        throw Exception('User document does not exist!');
      }

      final data = userSnapshot.data()!;
      // Folosim fallback-uri în caz că documentul e mai vechi și nu are câmpurile
      int currentLevel = data['level'] ?? 1;
      int currentXP = data['currentXP'] ?? 0;
      int totalRecipesCooked = data['totalRecipesCooked'] ?? 0;

      currentXP += earnedXP;
      totalRecipesCooked += 1;

      int xpNeeded = getXpForNextLevel(currentLevel);

      // Verificăm dacă a crescut în nivel (folosim while în caz că a adunat foarte mult XP)
      while (currentXP >= xpNeeded) {
        currentXP -= xpNeeded;
        currentLevel++;
        leveledUp = true;
        xpNeeded = getXpForNextLevel(currentLevel);
      }

      newLevel = currentLevel;

      // Actualizăm documentul utilizatorului
      transaction.update(userRef, {
        'level': currentLevel,
        'currentXP': currentXP,
        'totalRecipesCooked': totalRecipesCooked,
      });

      // Salvăm rețeta în istoricul de preparate gătite
      final cookedMealRef = userRef.collection('cooked_meals').doc();
      transaction.set(cookedMealRef, {
        'recipeId': recipeId,
        'title': title,
        'image': imageUrl,
        'earnedXP': earnedXP,
        'cookedAt': FieldValue.serverTimestamp(),
      });
    });

    // Returnăm aceste date pentru a putea declanșa animații în interfață!
    return {'earnedXP': earnedXP, 'leveledUp': leveledUp, 'newLevel': newLevel};
  }

  /// Returnează un stream pentru a asculta în timp real schimbările de nivel/XP
  Stream<DocumentSnapshot> getUserGamificationStats() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  /// Returnează un stream cu istoricul rețetelor gătite, ordonate cronologic
  Stream<QuerySnapshot> getCookedMeals() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cooked_meals')
        .orderBy('cookedAt', descending: true)
        .snapshots();
  }
}
