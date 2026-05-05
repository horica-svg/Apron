import 'package:flutter/material.dart';
import 'package:meals/models/pantry_item.dart';
import 'package:meals/services/pantry_service.dart';
import 'package:meals/services/recipe_service.dart';
import 'package:meals/screens/recipe_detail_screen.dart';

class CustomSearchScreen extends StatefulWidget {
  const CustomSearchScreen({super.key});

  @override
  State<CustomSearchScreen> createState() => _CustomSearchScreenState();
}

class _CustomSearchScreenState extends State<CustomSearchScreen> {
  final PantryService _pantryService = PantryService();
  final SpoonacularService _spoonacularService = SpoonacularService();

  List<PantryItem>? _pantryItems;
  final Set<String> _selectedIngredients = {};
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadPantryItems();
  }

  Future<void> _loadPantryItems() async {
    try {
      final items = await _pantryService.getPantryItems().first;
      items.sort((a, b) {
        if (a.expiryDate == null && b.expiryDate == null) return 0;
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;
        return a.expiryDate!.compareTo(b.expiryDate!);
      });

      setState(() {
        _pantryItems = items;
        _selectedIngredients.addAll(items.map((e) => e.name));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _selectAll() {
    if (_pantryItems == null) return;
    setState(() {
      _selectedIngredients.addAll(_pantryItems!.map((e) => e.name));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIngredients.clear();
    });
  }

  Future<void> _searchRecipes() async {
    if (_selectedIngredients.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final recipes = await _spoonacularService.getRecipesByIngredients(
        _selectedIngredients.toList(),
      );

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          expand: false,
          builder: (sheetContext, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Found ${recipes.length} Recipes for you',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: recipes.length,
                    itemBuilder: (listContext, index) {
                      final recipe = recipes[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
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
                          child: Row(
                            children: [
                              Image.network(
                                recipe.image,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Icon(Icons.broken_image, size: 40),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe.title,
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
                                          Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: Colors.green.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${recipe.usedIngredientCount} used',
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.error_outline,
                                            size: 16,
                                            color: Colors.orange.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${recipe.missedIngredientCount} missed',
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Recipe Search')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pantryItems == null || _pantryItems!.isEmpty
          ? const Center(child: Text('Your pantry is empty!'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16.0,
                    left: 16.0,
                    right: 16.0,
                    bottom: 8.0,
                  ),
                  child: Text(
                    'Choose the ingredients you want to use.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: _selectAll,
                      icon: const Icon(Icons.checklist),
                      label: const Text('Select All'),
                    ),
                    TextButton.icon(
                      onPressed: _deselectAll,
                      icon: const Icon(Icons.check_box_outline_blank),
                      label: const Text('Deselect All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _pantryItems!.length,
                    itemBuilder: (context, index) {
                      final item = _pantryItems![index];
                      final isSelected = _selectedIngredients.contains(
                        item.name,
                      );
                      final isExpiringSoon =
                          item.expiryDate != null &&
                          item.expiryDate!.difference(DateTime.now()).inDays <=
                              3;

                      return Card(
                        elevation: 0,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                                  .withValues(alpha: 0.3)
                            : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedIngredients.add(item.name);
                              } else {
                                _selectedIngredients.remove(item.name);
                              }
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: isExpiringSoon
                              ? const Text(
                                  'Expires soon',
                                  style: TextStyle(color: Colors.orange),
                                )
                              : null,
                          secondary: isExpiringSoon
                              ? const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _selectedIngredients.isEmpty || _isSearching
                          ? null
                          : _searchRecipes,
                      icon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                        'Search with ${_selectedIngredients.length} items',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
