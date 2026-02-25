import 'package:flutter/material.dart';
import 'package:meals/models/recipe_detail.dart';
import 'package:meals/services/pantry_service.dart';
import 'package:meals/services/recipe_service.dart';
import 'package:meals/services/storage_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;
  final String title;
  final String imageUrl;
  final List<String> missedIngredients;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    required this.title,
    required this.imageUrl,
    required this.missedIngredients,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final SpoonacularService _spoonacularService = SpoonacularService();
  final PantryService _pantryService = PantryService();
  final StorageService _storageService = StorageService();
  RecipeDetail? _recipeDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
    _addToHistory();
  }

  Future<void> _addToHistory() async {
    await _storageService.addToHistory(
      recipeId: widget.recipeId,
      title: widget.title,
      imageUrl: widget.imageUrl,
    );
  }

  Future<void> _fetchRecipeDetails() async {
    try {
      // Această metodă trebuie adăugată în SpoonacularService!
      final details = await _spoonacularService.getRecipeDetails(
        widget.recipeId,
      );
      if (mounted) {
        setState(() {
          _recipeDetail = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToShoppingList() async {
    if (widget.missedIngredients.isEmpty) return;

    try {
      await _pantryService.addShoppingListItems(widget.missedIngredients);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Au fost adăugate ${widget.missedIngredients.length} ingrediente în lista de cumpărături!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Eroare la adăugare: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.missedIngredients.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addToShoppingList,
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text('Adaugă ${widget.missedIngredients.length} lipsă'),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            actions: [
              StreamBuilder<bool>(
                stream: _storageService.isFavorite(widget.recipeId),
                builder: (context, snapshot) {
                  final isFav = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                    onPressed: () {
                      _storageService.toggleFavorite(
                        recipeId: widget.recipeId,
                        title: widget.title,
                        imageUrl: widget.imageUrl,
                      );
                    },
                  );
                },
              ),
            ],
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.title, style: const TextStyle(fontSize: 16)),
              background: Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.broken_image, size: 100),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(child: Center(child: Text('Eroare: $_error')))
          else if (_recipeDetail != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip(
                      Icons.timer,
                      '${_recipeDetail!.readyInMinutes} min',
                    ),
                    _buildInfoChip(
                      Icons.restaurant,
                      '${_recipeDetail!.servings} porții',
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Ingrediente',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return ListTile(
                  leading: const Icon(Icons.circle, size: 8),
                  title: Text(_recipeDetail!.ingredients[index]),
                );
              }, childCount: _recipeDetail!.ingredients.length),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Instrucțiuni',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(_recipeDetail!.instructions[index]),
                );
              }, childCount: _recipeDetail!.instructions.length),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}
