import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meals/widgets/main_drawer.dart';
import 'package:meals/services/pantry_service.dart';
import 'package:meals/services/recipe_service.dart';
import 'package:meals/widgets/last_used_recipes_grid.dart';
import 'package:meals/widgets/suggested_recipe_card.dart';
import 'package:meals/services/recipe_finder_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PantryService _pantryService = PantryService();
  final SpoonacularService _spoonacularService = SpoonacularService();
  final RecipeFinderService _recipeFinderService = RecipeFinderService();
  bool _isLoading = false;
  Future<Map<String, dynamic>>? _randomRecipeFuture;

  @override
  void initState() {
    super.initState();
    _randomRecipeFuture = _spoonacularService.getRandomRecipe();
  }

  Future<void> _findRecipes() async {
    await _recipeFinderService.findAndShowRecipes(
      context,
      onStart: () {
        if (mounted) setState(() => _isLoading = true);
      },
      onEnd: () {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _pantryService.getUserPantries(),
      builder: (context, pantrySnapshot) {
        if (pantrySnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Home')),
            drawer: const MainDrawer(),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: Text('Error: ${pantrySnapshot.error}')),
            ),
          );
        }

        if (!pantrySnapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Home')),
            drawer: const MainDrawer(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final pantries = pantrySnapshot.data!.docs;

        if (PantryService.activePantryId.isEmpty ||
            !pantries.any((p) => p.id == PantryService.activePantryId)) {
          if (pantries.isNotEmpty) {
            PantryService.activePantryId = pantries.first.id;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: pantries.isEmpty
                ? const Text('Home')
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: PantryService.activePantryId,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      items: pantries.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(
                            data['name'] ?? 'Unknown Pantry',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            PantryService.activePantryId = val;
                          });
                        }
                      },
                    ),
                  ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.add_home_work),
                tooltip: 'Pantry Options',
                onSelected: (value) {
                  if (value == 'create') _showAddPantryDialog();
                  if (value == 'join') _showJoinPantryDialog();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'create',
                    child: Text('Create New Pantry'),
                  ),
                  const PopupMenuItem(
                    value: 'join',
                    child: Text('Join Existing Pantry'),
                  ),
                ],
              ),
            ],
          ),
          drawer: const MainDrawer(),
          body: Column(
            children: [
              // Top Section: Button to find recipes
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _findRecipes,
                        icon: const Icon(Icons.restaurant),
                        label: const Text('Find Recipes based on Pantry'),
                      ),
              ),
              const Divider(),
              // Grid Section: Last 8 recipes
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Last Used Recipes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Expanded(child: LastUsedRecipesGrid()),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Suggested for You',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SuggestedRecipeCard(randomRecipeFuture: _randomRecipeFuture),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddPantryDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Pantry'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Pantry Name',
            hintText: 'e.g., Vacation Home',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await _pantryService.createPantry(name);
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pantry "$name" created!')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinPantryDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Pantry'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Pantry Code',
            hintText: 'Enter the code shared with you',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                try {
                  await _pantryService.joinPantry(code);
                  if (mounted) {
                    setState(() => PantryService.activePantryId = code);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully joined the pantry!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                      ),
                    );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
