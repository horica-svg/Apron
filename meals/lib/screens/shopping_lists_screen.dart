import 'package:flutter/material.dart';
import 'package:meals/widgets/main_drawer.dart';

class ShoppingListsScreen extends StatelessWidget {
  const ShoppingListsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Lists')),
      drawer: const MainDrawer(),
      body: const Center(child: Text('Your shopping list will appear here.')),
    );
  }
}
