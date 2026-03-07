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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.kitchen,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your pantry is empty.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add items to track what you have at home.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return Dismissible(
                key: Key(item.id!),
                direction: DismissDirection.endToStart,
                background: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                onDismissed: (direction) {
                  _pantryService.deletePantryItem(item.id!);
                },
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        _getCategoryIcon(item.category),
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.quantity} ${item.unit} • ${item.category}',
                        ),
                        if (item.expiryDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _buildExpiryChip(context, item.expiryDate!),
                          ),
                      ],
                    ),
                  ),
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Vegetable':
        return Icons.eco;
      case 'Fruit':
        return Icons.apple;
      case 'Meat':
        return Icons.restaurant;
      case 'Dairy':
        return Icons.local_drink;
      case 'Grain':
        return Icons.grass;
      case 'Spice':
        return Icons.whatshot;
      default:
        return Icons.kitchen;
    }
  }

  Widget _buildExpiryChip(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    Color color;
    String text;

    if (diff < 0) {
      color = Colors.red;
      text = 'Expired';
    } else if (diff < 3) {
      color = Colors.orange;
      text = 'Expires soon';
    } else {
      color = Colors.green;
      text = 'Exp: ${date.toString().split(' ')[0]}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    String selectedUnit = 'pcs';
    String selectedCategory = 'Other';
    DateTime? selectedDate;

    final categories = [
      'Vegetable',
      'Fruit',
      'Meat',
      'Dairy',
      'Grain',
      'Spice',
      'Other',
    ];
    final units = ['pcs', 'kg', 'g', 'l', 'ml'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Item to Pantry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Item Name'),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            decoration: const InputDecoration(labelText: 'Qty'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            items: units
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => selectedUnit = val!),
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedCategory = val!),
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          selectedDate == null
                              ? 'No Expiry Date'
                              : 'Expires: ${selectedDate!.toString().split(' ')[0]}',
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 5),
                              ),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: const Text('Pick Date'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final quantity =
                        double.tryParse(quantityController.text) ?? 0.0;

                    if (name.isNotEmpty && quantity > 0) {
                      _pantryService.addPantryItem(
                        PantryItem(
                          name: name,
                          quantity: quantity,
                          unit: selectedUnit,
                          category: selectedCategory,
                          expiryDate: selectedDate,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
