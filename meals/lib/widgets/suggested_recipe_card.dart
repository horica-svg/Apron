import 'package:flutter/material.dart';
import 'package:meals/services/pantry_service.dart';
import 'package:meals/screens/recipe_detail_screen.dart';

class SuggestedRecipeCard extends StatelessWidget {
  final Future<Map<String, dynamic>>? randomRecipeFuture;

  const SuggestedRecipeCard({super.key, required this.randomRecipeFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: randomRecipeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final recipe = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0, left: 12.0, right: 12.0),
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
                final ingName = (item['name'] as String?)?.toLowerCase() ?? '';
                if (ingName.isEmpty) continue;

                final hasItem = pantryNames.contains(ingName);
                if (!hasItem) {
                  missing.add(item['name'] as String);
                }
              }

              if (!context.mounted) return;

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
              elevation: 2,
              child: Row(
                children: [
                  Image.network(
                    recipe['image'] ?? '',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const SizedBox(
                      width: 100,
                      height: 100,
                      child: Icon(Icons.broken_image),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe['title'] ?? 'Unknown Recipe',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.timer,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe['readyInMinutes'] ?? '?'} mins',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
