import 'package:flutter/material.dart';
import 'package:meals/services/pantry_service.dart';
import 'package:meals/screens/recipe_detail_screen.dart';
import 'package:meals/services/storage_service.dart';

class SuggestedRecipeCard extends StatelessWidget {
  final Future<List<Map<String, dynamic>>>? randomRecipesFuture;

  const SuggestedRecipeCard({super.key, required this.randomRecipesFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: randomRecipesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final recipes = snapshot.data!;
        return SizedBox.expand(
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                  top: 8.0,
                  bottom:
                      24.0, // Mai mult spațiu jos pentru un aspect mai aerisit
                ),
                child: InkWell(
                  onTap: () async {
                    final pantryService = PantryService();
                    // Preluăm alimentele din cămară
                    final pantryItems = await pantryService
                        .getPantryItems(PantryService.activePantryId)
                        .first;
                    final pantryNames = pantryItems
                        .map((e) => e.name.toLowerCase())
                        .toList();

                    // Extragem ingredientele necesare rețetei random
                    final extended =
                        recipe['extendedIngredients'] as List<dynamic>? ?? [];
                    final List<String> missing = [];

                    for (var item in extended) {
                      final ingName =
                          (item['name'] as String?)?.toLowerCase() ?? '';
                      if (ingName.isEmpty) continue;

                      final hasItem = pantryNames.contains(ingName);
                      if (!hasItem) {
                        missing.add(item['name'] as String);
                      }
                    }

                    if (!context.mounted) return;

                    // Salvăm instantaneu rețeta în istoric la apăsare pentru a fi afișată în Home
                    StorageService().addToHistory(
                      recipeId: recipe['id'],
                      title: recipe['title'] ?? 'Unknown Recipe',
                      imageUrl: recipe['image'] ?? '',
                    );

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => RecipeDetailScreen(
                          recipeId: recipe['id'],
                          title: recipe['title'],
                          imageUrl: recipe['image'] ?? '',
                          missedIngredients: missing,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                recipe['image'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Center(
                                  child: Icon(Icons.broken_image, size: 50),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_fire_department,
                                        color: Colors.orangeAccent,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Trending',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe['title'] ?? 'Unknown Recipe',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${recipe['readyInMinutes'] ?? '?'} mins',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.restaurant,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${recipe['extendedIngredients']?.length ?? '?'} items',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
