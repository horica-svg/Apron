import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meals/widgets/main_drawer.dart';
import 'package:meals/services/pantry_service.dart';
import 'package:meals/services/recipe_service.dart';
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
  Future<List<Map<String, dynamic>>>? _randomRecipesFuture;

  @override
  void initState() {
    super.initState();
    _randomRecipesFuture = _spoonacularService.getRandomRecipes(number: 3);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 12.0),
                child: Text(
                  "What are we cooking today?",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: InkWell(
                  onTap: _isLoading ? null : _findRecipes,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Magic Recipe Finder',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Let us suggest meals based on what you already have in your pantry!',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary
                                      .withValues(alpha: 0.9),
                                  fontSize: 13,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Icon(
                                  Icons.auto_awesome,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  size: 32,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Suggested for You',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SuggestedRecipeCard(
                  randomRecipesFuture: _randomRecipesFuture,
                ),
              ),
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
