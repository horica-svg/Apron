import 'package:flutter/material.dart';
import 'package:meals/screens/home.dart';
import 'package:meals/screens/pantry_screen.dart';
import 'package:meals/screens/shopping_lists_screen.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.fastfood,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 18),
                Text(
                  'Apron',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.of(context).pop(); // Închide drawer-ul
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (ctx) => const HomeScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shelves),
            title: const Text('Pantry'),
            onTap: () {
              Navigator.of(context).pop(); // Închide drawer-ul
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (ctx) => PantryScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Shopping List'),
            onTap: () {
              Navigator.of(context).pop(); // Închide drawer-ul
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (ctx) => const ShoppingListsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
