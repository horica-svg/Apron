import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meals/screens/recipe_detail_screen.dart';

class LastUsedRecipesGrid extends StatelessWidget {
  const LastUsedRecipesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .orderBy('viewedAt', descending: true)
          .limit(8)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("You haven't viewed any recipes lately."),
          );
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
            final data = historyDocs[index].data() as Map<String, dynamic>;
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
                    title: Text(data['title'], textAlign: TextAlign.center),
                  ),
                  child: Image.network(
                    data['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
