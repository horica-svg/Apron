import 'package:flutter/material.dart';
import 'package:meals/services/pantry_service.dart';
import 'package:meals/services/recipe_service.dart';
import 'package:meals/screens/pantry_screen.dart';
import 'package:meals/screens/recipe_detail_screen.dart';
import 'package:meals/services/storage_service.dart';

class RecipeFinderService {
  final PantryService _pantryService = PantryService();
  final SpoonacularService _spoonacularService = SpoonacularService();

  /// Execută logica de căutare a rețetelor și afișează rezultatele sau erorile
  Future<void> findAndShowRecipes(
    BuildContext context, {
    required VoidCallback onStart,
    required VoidCallback onEnd,
  }) async {
    // Notificăm UI-ul să afișeze indicatorul de încărcare
    onStart();

    try {
      final hasEnough = await _pantryService.hasEnoughIngredients(
        pantryId: PantryService.activePantryId,
      );
      if (!hasEnough) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You should add at least 4 items in your pantry before searching for recipes...',
            ),
          ),
        );
        return;
      }

      // 1. Preluăm alimentele din cămară
      final pantryItems = await _pantryService
          .getPantryItems(PantryService.activePantryId)
          .first;

      // 2. Verificăm dacă există alimente expirate
      final now = DateTime.now();
      final hasExpiredItems = pantryItems.any((item) {
        if (item.expiryDate == null) return false;
        return item.expiryDate!.difference(now).inDays < 0;
      });

      if (hasExpiredItems) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Oops! Expired ingredients'),
            content: const Text(
              "Looks like you have some spoiled apples in your basket. Don't worry, just swipe them out the pantry and come back for new recipes!",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // Închide dialogul
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const PantryScreen()),
                  ); // Navighează la My Pantry
                },
                child: const Text('Go to Pantry'),
              ),
            ],
          ),
        );
        return;
      }

      // Sortăm alimentele: cele care expiră cel mai curând vor fi primele
      pantryItems.sort((a, b) {
        if (a.expiryDate == null && b.expiryDate == null) return 0;
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;
        return a.expiryDate!.compareTo(b.expiryDate!);
      });

      final ingredients = pantryItems.map((item) => item.name).toList();

      if (ingredients.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your pantry is empty! Add some items first.'),
          ),
        );
        return;
      }

      // 3. Apelăm API-ul Spoonacular
      final recipes = await _spoonacularService.getRecipesByIngredients(
        ingredients,
      );

      if (!context.mounted) return;

      // 4. Afișăm rezultatele într-un BottomSheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (sheetContext, scrollController) {
            if (recipes.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    "Couldn't find any recipes with your ingredients.",
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Found ${recipes.length} Recipes',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: recipes.length,
                    itemBuilder: (listContext, index) {
                      final recipe = recipes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            // Adăugăm rețeta în istoricul Last Used Recipes de pe Home
                            StorageService().addToHistory(
                              recipeId: recipe.id,
                              title: recipe.title,
                              imageUrl: recipe.image,
                            );

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => RecipeDetailScreen(
                                  recipeId: recipe.id,
                                  title: recipe.title,
                                  imageUrl: recipe.image,
                                  missedIngredients: recipe.missedIngredients,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Image.network(
                                recipe.image,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(
                                      Icons.restaurant_menu,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  recipe.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    _buildIngredientChip(
                                      context,
                                      Icons.check_circle_outline,
                                      '${recipe.usedIngredientCount} Used',
                                      Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    if (recipe.missedIngredientCount > 0)
                                      _buildIngredientChip(
                                        context,
                                        Icons.error_outline,
                                        '${recipe.missedIngredientCount} Missed',
                                        Colors.red.shade700,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      // Notificăm UI-ul să oprească indicatorul de încărcare
      onEnd();
    }
  }

  Widget _buildIngredientChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(label),
      backgroundColor: color.withOpacity(0.15),
      shape: StadiumBorder(side: BorderSide(color: color.withOpacity(0.2))),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      labelPadding: const EdgeInsets.only(left: 2, right: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
