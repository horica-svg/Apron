import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meals/widgets/main_drawer.dart';
import 'package:meals/services/pantry_service.dart';
import 'package:meals/services/recipe_service.dart';
import 'package:meals/screens/recipe_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meals/screens/pantry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PantryService _pantryService = PantryService();
  final SpoonacularService _spoonacularService = SpoonacularService();
  bool _isLoading = false;
  Future<Map<String, dynamic>>? _randomRecipeFuture;

  @override
  void initState() {
    super.initState();
    _randomRecipeFuture = _spoonacularService.getRandomRecipe();
  }

  Future<void> _findRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasEnough = await _pantryService.hasEnoughIngredients(
        pantryId: PantryService.activePantryId,
      );
      if (!hasEnough) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You should add at least 4 items in your pantry before searching for recipes...',
            ),
          ),
        );
        return;
      }

      // 1. Get current pantry items (take the first snapshot)
      final pantryItems = await _pantryService
          .getPantryItems(PantryService.activePantryId)
          .first;

      // Verificăm dacă există alimente expirate
      final now = DateTime.now();
      final hasExpiredItems = pantryItems.any((item) {
        if (item.expiryDate == null) return false;
        return item.expiryDate!.difference(now).inDays < 0;
      });

      if (hasExpiredItems) {
        if (!mounted) return;
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
                    MaterialPageRoute(builder: (ctx) => PantryScreen()),
                  ); // Navighează la My Pantry
                },
                child: const Text('Go to Pantry'),
              ),
            ],
          ),
        );
        return;
      }

      // Sortăm alimentele astfel încât cele care expiră cel mai curând să fie primele în listă.
      pantryItems.sort((a, b) {
        if (a.expiryDate == null && b.expiryDate == null) return 0;
        if (a.expiryDate == null) return 1; // Cele fără dată merg la final
        if (b.expiryDate == null) return -1;
        return a.expiryDate!.compareTo(b.expiryDate!);
      });

      final ingredients = pantryItems.map((item) => item.name).toList();

      if (ingredients.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your pantry is empty! Add some items first.'),
          ),
        );
        return;
      }

      // 3. Call Spoonacular API
      final recipes = await _spoonacularService.getRecipesByIngredients(
        ingredients,
      );

      if (!mounted) return;

      // 4. Show results in a BottomSheet for testing
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          builder: (sheetContext, scrollController) {
            return ListView.builder(
              controller: scrollController,
              itemCount: recipes.length,
              itemBuilder: (listContext, index) {
                final recipe = recipes[index];
                return ListTile(
                  leading: Image.network(
                    recipe.image,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                  ),
                  title: Text(recipe.title),
                  subtitle: Text(
                    'Used: ${recipe.usedIngredientCount}, Missed: ${recipe.missedIngredientCount}',
                  ),
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
                );
              },
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('history')
                      .orderBy('viewedAt', descending: true)
                      .limit(8)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No history yet.'));
                    }

                    final historyDocs = snapshot.data!.docs;

                    return GridView.builder(
                      padding: const EdgeInsets.all(10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3 / 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: historyDocs.length,
                      itemBuilder: (ctx, index) {
                        final data =
                            historyDocs[index].data() as Map<String, dynamic>;
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => RecipeDetailScreen(
                                  recipeId: data['id'],
                                  title: data['title'],
                                  imageUrl: data['image'],
                                  missedIngredients:
                                      const [], // Nu știm ce lipsește din istoric
                                ),
                              ),
                            );
                          },
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: GridTile(
                              footer: GridTileBar(
                                backgroundColor: Colors.black54,
                                title: Text(
                                  data['title'],
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              child: Image.network(
                                data['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
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
              FutureBuilder<Map<String, dynamic>>(
                future: _randomRecipeFuture,
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
                    padding: const EdgeInsets.only(
                      bottom: 16.0,
                      left: 12.0,
                      right: 12.0,
                    ),
                    child: InkWell(
                      onTap: () async {
                        // Preluăm alimentele din cămară
                        final pantryItems = await _pantryService
                            .getPantryItems(PantryService.activePantryId)
                            .first;
                        final pantryNames = pantryItems
                            .map((e) => e.name.toLowerCase())
                            .toList();

                        // Extragem ingredientele necesare rețetei random
                        final extended =
                            recipe['extendedIngredients'] as List<dynamic>? ??
                            [];
                        final List<String> missing = [];

                        for (var item in extended) {
                          final ingName =
                              (item['name'] as String?)?.toLowerCase() ?? '';
                          if (ingName.isEmpty) continue;

                          // Verificăm dacă ingredientul lipsește din cămară
                          // Potrivire exactă, având în vedere standardul Spoonacular
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
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
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
