import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meals/screens/home.dart';
import 'package:meals/screens/pantry_screen.dart';
import 'package:meals/screens/shopping_lists_screen.dart';
import 'package:meals/screens/custom_search_screen.dart';
import 'package:meals/screens/favourites_screen.dart';
import 'package:meals/services/gamification_service.dart';
import 'package:meals/screens/cooking_history_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meals/screens/auth_wrapper.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        hoverColor: Theme.of(context).colorScheme.primaryContainer,
        splashColor: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.4),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gamificationService = GamificationService();

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'media/APRON_image.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Apron',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your smart kitchen assistant',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<DocumentSnapshot>(
                  stream: gamificationService.getUserGamificationStats(),
                  builder: (context, snapshot) {
                    int level = 1;
                    int currentXP = 0;
                    int xpNeeded = 100;

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null) {
                        level = data['level'] ?? 1;
                        currentXP = data['currentXP'] ?? 0;
                        xpNeeded = gamificationService.getXpForNextLevel(level);
                      }
                    }
                    String rankTitle = gamificationService.getRankForLevel(
                      level,
                    );
                    double progress = (xpNeeded > 0)
                        ? (currentXP / xpNeeded).clamp(0.0, 1.0)
                        : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          rankTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Level $level',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$currentXP / $xpNeeded XP',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildListTile(context, Icons.home_outlined, 'Home', () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (ctx) => const HomeScreen()),
                  );
                }),
                _buildListTile(
                  context,
                  Icons.kitchen_outlined,
                  'My Pantry',
                  () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (ctx) => PantryScreen()),
                    );
                  },
                ),
                _buildListTile(
                  context,
                  Icons.favorite_outline,
                  'Favourites',
                  () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (ctx) => const FavouritesScreen(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  context,
                  Icons.shopping_cart_outlined,
                  'Shopping List',
                  () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (ctx) => const ShoppingListsScreen(),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Divider(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                _buildListTile(
                  context,
                  Icons.history_edu_outlined,
                  'Cooking History',
                  () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (ctx) => const CookingHistoryScreen(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  context,
                  Icons.manage_search_outlined,
                  'Custom Search',
                  () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const CustomSearchScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Logout',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {
              Navigator.of(context).pop();
              await FirebaseAuth.instance.signOut();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (ctx) => AuthWrapper()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
