import 'package:flutter/material.dart';
import 'package:meals/models/recipe_detail.dart';
import 'package:meals/services/pantry_service.dart';
import 'package:meals/services/recipe_service.dart';
import 'package:meals/services/storage_service.dart';
import 'package:meals/services/gamification_service.dart';

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
  final GamificationService _gamificationService = GamificationService();
  RecipeDetail? _recipeDetail;
  bool _isLoading = true;
  bool _isMarkingAsCooked = false;
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

  Future<void> _markAsCooked() async {
    if (_recipeDetail == null) return;

    setState(() {
      _isMarkingAsCooked = true;
    });

    try {
      final result = await _gamificationService.markRecipeAsCooked(
        recipeId: widget.recipeId,
        title: widget.title,
        imageUrl: widget.imageUrl,
        readyInMinutes: _recipeDetail!.readyInMinutes,
        ingredientCount: _recipeDetail!.ingredients.length,
      );

      // Consumăm ingredientele folosite din Pantry
      final lowStockItems = await _pantryService.consumeRecipeIngredients(
        _recipeDetail!.ingredients,
        PantryService.activePantryId,
      );

      if (mounted) {
        _showRewardDialog(
          result['earnedXP'] as int,
          result['leveledUp'] as bool,
          result['newLevel'] as int,
          lowStockItems,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Eroare: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAsCooked = false;
        });
      }
    }
  }

  void _showRewardDialog(
    int earnedXP,
    bool leveledUp,
    int newLevel,
    List<String> lowStockItems,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          leveledUp ? '🎉 Level Up! 🎉' : 'Great Job! 🍳',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You succesfully cooked "${widget.title}"!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '+$earnedXP XP',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (leveledUp) ...[
              const SizedBox(height: 12),
              Text(
                'Ai ajuns la Nivelul $newLevel!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (lowStockItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                '⚠️ Low Stock Alert!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You are running very low on:\n${lowStockItems.join(', ')}.\nConsider adding them to your shopping list!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Awesome!', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.missedIngredients.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addToShoppingList,
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text(
                'Add ${widget.missedIngredients.length} missing ingredients',
              ),
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
              titlePadding: const EdgeInsets.only(
                left: 56.0,
                right: 16.0,
                bottom: 16.0,
              ),
              title: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'recipe_image_${widget.recipeId}',
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.broken_image, size: 100),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(child: Center(child: Text('Error: $_error')))
          else if (_recipeDetail != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24.0,
                  horizontal: 16.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoItem(
                        context,
                        Icons.timer_outlined,
                        '${_recipeDetail!.readyInMinutes ~/ 60}h ${_recipeDetail!.readyInMinutes % 60} min',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      _buildInfoItem(
                        context,
                        Icons.restaurant_menu,
                        '${_recipeDetail!.servings} servings',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSectionTitle(context, 'Ingredients'),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final ing = _recipeDetail!.ingredients[index];
                  final amountStr = ing.amount
                      .toStringAsFixed(1)
                      .replaceAll(RegExp(r'\.0$'), '');

                  // Construim frumos textele, evitând spațiile libere și capitalizând prima literă
                  final unitStr = ing.unit.isNotEmpty ? '${ing.unit} ' : '';
                  final nameStr = ing.name.isNotEmpty
                      ? '${ing.name[0].toUpperCase()}${ing.name.substring(1)}'
                      : '';

                  return Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    margin: const EdgeInsets.only(bottom: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$amountStr $unitStr$nameStr',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: _recipeDetail!.ingredients.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _buildSectionTitle(context, 'Steps')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _recipeDetail!.instructions[index],
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }, childCount: _recipeDetail!.instructions.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(child: Divider(indent: 32, endIndent: 32)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isMarkingAsCooked
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.workspace_premium, size: 28),
                  label: Text(
                    _isMarkingAsCooked
                        ? 'Claiming reward...'
                        : 'I Cooked This!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _isMarkingAsCooked ? null : _markAsCooked,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 60,
              ), // Spațiu suplimentar pentru FloatingActionButton
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
