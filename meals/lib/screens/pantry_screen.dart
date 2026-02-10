import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import '../services/pantry_service.dart';
import 'package:meals/widgets/main_drawer.dart';

class PantryScreen extends StatelessWidget {
  PantryScreen({super.key});

  final PantryService _pantryService = PantryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Pantry')),
      drawer: const MainDrawer(),
      body: StreamBuilder<List<PantryItem>>(
        stream: _pantryService.getPantryItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(child: Text('Your pantry is empty.'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: const Icon(Icons.fastfood),
                title: Text(item.name),
                subtitle: Text('${item.quantity} ${item.unit}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _pantryService.deletePantryItem(item.id!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adaugă aliment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nume produs'),
            ),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Cantitate'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(
                labelText: 'Unitate (ex: kg, buc)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final quantity = double.tryParse(quantityController.text) ?? 0.0;
              final unit = unitController.text.trim();

              if (name.isNotEmpty && quantity > 0) {
                _pantryService.addPantryItem(
                  PantryItem(name: name, quantity: quantity, unit: unit),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }
}
