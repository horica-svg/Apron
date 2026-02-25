import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meals/models/pantry_item.dart';
import 'package:meals/services/pantry_service.dart';
import 'package:meals/services/recipe_service.dart';
import 'package:meals/widgets/main_drawer.dart';

class ShoppingListsScreen extends StatefulWidget {
  const ShoppingListsScreen({super.key});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  final PantryService _pantryService = PantryService();
  final SpoonacularService _spoonacularService = SpoonacularService();
  double? _totalCost;
  bool _isCalculating = false;

  Future<void> _calculateTotal(List<String> ingredients) async {
    setState(() {
      _isCalculating = true;
      _totalCost = null;
    });

    try {
      final cost = await _spoonacularService.getIngredientsTotalCost(
        ingredients,
      );
      if (mounted) {
        setState(() {
          _totalCost = cost;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error calculating price: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
      }
    }
  }

  Future<void> _showAddToPantryDialog(
    BuildContext context,
    String itemName,
    String docId,
    bool currentStatus,
  ) async {
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

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add $itemName to Pantry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      items: units
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedUnit = val!),
                      decoration: const InputDecoration(labelText: 'Unit'),
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
                              : 'Expires: ${selectedDate!.toLocal().toString().split(' ')[0]}',
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
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final quantity =
                        double.tryParse(quantityController.text) ?? 1.0;

                    final newItem = PantryItem(
                      id: '', // ID is generated by Firestore
                      name: itemName,
                      quantity: quantity,
                      unit: selectedUnit,
                      category: selectedCategory,
                      expiryDate: selectedDate,
                    );

                    await _pantryService.addPantryItem(newItem);
                    // Mark as checked in shopping list
                    await _pantryService.toggleShoppingItem(
                      docId,
                      currentStatus,
                    );

                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$itemName added to pantry!')),
                      );
                    }
                  },
                  child: const Text('Add & Check'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      drawer: const MainDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _pantryService.getShoppingList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your shopping list is empty.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add ingredients from recipes to see them here.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Filtrăm documentul de inițializare '_init_'
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return !data.containsKey('_init_');
          }).toList();

          // Verificăm dacă toate elementele sunt bifate
          if (docs.isNotEmpty) {
            final allChecked = docs.every((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['checked'] == true;
            });

            if (allChecked) {
              // Programăm ștergerea după ce se termină randarea curentă
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All items bought! Clearing list...'),
                  ),
                );
                // Așteptăm puțin pentru ca utilizatorul să vadă feedback-ul
                await Future.delayed(const Duration(seconds: 2));
                for (final doc in docs) {
                  _pantryService.deleteShoppingItem(doc.id);
                }
              });
            }
          }

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your shopping list is empty.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add ingredients from recipes to see them here.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Extragem lista de nume pentru calculul prețului
          final ingredientNames = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['name'] as String;
          }).toList();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final isChecked = data['checked'] ?? false;

                    return Dismissible(
                      key: Key(doc.id),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      onDismissed: (direction) {
                        _pantryService.deleteShoppingItem(doc.id);
                      },
                      child: Card(
                        elevation: isChecked ? 0 : 2,
                        color: isChecked
                            ? Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5)
                            : Theme.of(context).colorScheme.surfaceContainerLow,
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Theme.of(context).colorScheme.primary,
                          title: Text(
                            name,
                            style: TextStyle(
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isChecked
                                  ? Colors.grey
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                              fontWeight: isChecked
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                            ),
                          ),
                          value: isChecked,
                          onChanged: (val) {
                            if (val == true) {
                              // If checking, show dialog to add to pantry
                              _showAddToPantryDialog(
                                context,
                                name,
                                doc.id,
                                isChecked,
                              );
                            } else {
                              // If unchecking, just toggle normally
                              _pantryService.toggleShoppingItem(
                                doc.id,
                                isChecked,
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Cost',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                          Text(
                            _totalCost != null
                                ? '€${_totalCost!.toStringAsFixed(2)}'
                                : '--',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      if (_isCalculating)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => _calculateTotal(ingredientNames),
                          icon: const Icon(Icons.calculate_outlined),
                          label: const Text('Calculate'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
