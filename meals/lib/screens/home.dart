import 'package:flutter/material.dart';
import 'package:meals/widgets/main_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      drawer: const MainDrawer(),
      body: const Center(child: Text("What's Cookin, Good Lookin?")),
    );
  }
}
