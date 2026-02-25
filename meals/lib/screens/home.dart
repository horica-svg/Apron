import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meals/widgets/main_drawer.dart';
import 'package:meals/services/pantry_service.dart';
import 'package:meals/services/recipe_service.dart';
import 'package:meals/screens/recipe_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PantryService _pantryService = PantryService();
  final SpoonacularService _spoonacularService = SpoonacularService();
  bool _isLoading = false;

  Future<void> _findRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasEnough = await _pantryService.hasEnoughIngredients();
      if (!hasEnough) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ai nevoie de cel puțin 4 alimente în cămară pentru a primi sugestii!',
            ),
          ),
        );
        return;
      }

      // 1. Get current pantry items (take the first snapshot)
      final pantryItems = await _pantryService.getPantryItems().first;

      // 2. Extract ingredient names (Fine-tuning: ensure PantryItem has .name)
      final ingredients = pantryItems.map((item) => item.name).toList();

      if (ingredients.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pantry is empty! Add some items first.'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
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
                    icon: const Icon(Icons.search),
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
                'Last 8 Recipes Used',
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
        ],
      ),
    );
  }
}
