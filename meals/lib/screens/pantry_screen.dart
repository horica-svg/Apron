import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pantry_item.dart';
import '../services/pantry_service.dart';
import 'package:meals/widgets/main_drawer.dart';
import 'package:meals/services/recipe_service.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final PantryService _pantryService = PantryService();
  final SpoonacularService _spoonacularService = SpoonacularService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _pantryService.getUserPantries(),
      builder: (context, pantrySnapshot) {
        if (pantrySnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Pantry')),
            drawer: const MainDrawer(),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: Text('Error: ${pantrySnapshot.error}')),
            ),
          );
        }

        if (!pantrySnapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Pantry')),
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

        bool isOwner = false;
        String currentPantryName = 'Unknown Pantry';
        if (pantries.isNotEmpty && PantryService.activePantryId.isNotEmpty) {
          final activeDocs = pantries.where(
            (p) => p.id == PantryService.activePantryId,
          );
          final activeDoc = activeDocs.isNotEmpty
              ? activeDocs.first
              : pantries.first;
          final activeData = activeDoc.data() as Map<String, dynamic>;
          isOwner =
              activeData['ownerId'] == FirebaseAuth.instance.currentUser?.uid;
          currentPantryName = activeData['name'] ?? 'Unknown Pantry';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Pantry'),
            actions: [
              if (pantries.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share Pantry',
                  onPressed: () => _showSharePantryDialog(),
                ),
                if (isOwner) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit current pantry name',
                    onPressed: () => _showEditPantryDialog(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete current pantry',
                    onPressed: () => _showDeletePantryDialog(),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.exit_to_app),
                    tooltip: 'Leave Pantry',
                    onPressed: () => _showLeavePantryDialog(),
                  ),
                ],
              ],
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
          body: pantries.isEmpty
              ? Center(
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
                        'You have no pantries.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create one to start tracking your food.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.kitchen,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: PopupMenuButton<String>(
                              initialValue: PantryService.activePantryId,
                              position: PopupMenuPosition.under,
                              tooltip: 'Select Pantry',
                              color: Theme.of(context).colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (val) {
                                if (val != PantryService.activePantryId) {
                                  setState(() {
                                    PantryService.activePantryId = val;
                                  });
                                }
                              },
                              itemBuilder: (context) {
                                return pantries.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final isSelected =
                                      doc.id == PantryService.activePantryId;
                                  return PopupMenuItem<String>(
                                    value: doc.id,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            data['name'] ?? 'Unknown Pantry',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.check,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            size: 20,
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        currentPantryName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<PantryItem>>(
                        stream: _pantryService.getPantryItems(
                          PantryService.activePantryId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Your pantry is empty.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.errorContainer,
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
                                  _pantryService.deletePantryItem(
                                    item.id!,
                                    PantryService.activePantryId,
                                  );
                                },
                                child: Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
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
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item.quantity} ${item.unit} • ${item.category}',
                                        ),
                                        if (item.expiryDate != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: _buildExpiryChip(
                                              context,
                                              item.expiryDate!,
                                            ),
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
                    ),
                  ],
                ),
          floatingActionButton: pantries.isEmpty
              ? null
              : FloatingActionButton(
                  onPressed: () => _showAddItemDialog(context),
                  child: const Icon(Icons.add),
                ),
        );
      },
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
      text = 'Expired on: ${date.toString().split(' ')[0]}';
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
    String itemName = '';
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
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.length < 2) {
                          return const Iterable<String>.empty();
                        }
                        try {
                          // Apelează metoda din SpoonacularService pentru sugestii
                          return await _spoonacularService
                              .getIngredientSuggestions(textEditingValue.text);
                        } catch (e) {
                          return const Iterable<String>.empty();
                        }
                      },
                      onSelected: (String selection) {
                        itemName = selection;
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textEditingController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: 'Item Name (Search Spoonacular)',
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (val) => itemName = val,
                            );
                          },
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
                    final name = itemName.trim();
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
                        PantryService.activePantryId,
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

  Future<void> _showDeletePantryDialog() async {
    final pantriesSnapshot = await _pantryService.getUserPantries().first;
    final pantries = pantriesSnapshot.docs;

    if (pantries.length <= 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete your only pantry.')),
      );
      return;
    }

    final pantryToDelete = PantryService.activePantryId;
    final activeDocs = pantries.where((p) => p.id == pantryToDelete).toList();
    if (activeDocs.isEmpty) return;

    final pantryData = activeDocs.first.data() as Map<String, dynamic>;
    final pantryName = pantryData['name'] ?? 'Pantry';

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pantry'),
        content: Text(
          'Are you sure you want to delete "$pantryName"? All items inside will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final nextPantry = pantries.firstWhere((p) => p.id != pantryToDelete);
      await _pantryService.deletePantry(pantryToDelete);

      if (mounted) {
        setState(() {
          PantryService.activePantryId = nextPantry.id;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pantry "$pantryName" deleted.')),
        );
      }
    }
  }

  Future<void> _showEditPantryDialog() async {
    final pantriesSnapshot = await _pantryService.getUserPantries().first;
    final pantries = pantriesSnapshot.docs;

    final activeDocs = pantries
        .where((p) => p.id == PantryService.activePantryId)
        .toList();
    if (activeDocs.isEmpty) return;

    final pantryData = activeDocs.first.data() as Map<String, dynamic>;
    final currentName = pantryData['name'] ?? 'Pantry';

    final controller = TextEditingController(text: currentName);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Pantry Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Pantry Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                await _pantryService.updatePantryName(
                  PantryService.activePantryId,
                  newName,
                );
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pantry renamed to "$newName"!')),
                  );
                }
              } else {
                Navigator.of(ctx).pop(); // Închide dacă e gol sau neschimbat
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSharePantryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share Pantry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Give this code to your housemate so they can join this pantry:',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                PantryService.activePantryId,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: PantryService.activePantryId),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard!')),
              );
              Navigator.of(ctx).pop();
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
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

  Future<void> _showLeavePantryDialog() async {
    final pantriesSnapshot = await _pantryService.getUserPantries().first;
    final pantries = pantriesSnapshot.docs;

    final pantryToLeave = PantryService.activePantryId;
    final activeDocs = pantries.where((p) => p.id == pantryToLeave).toList();
    if (activeDocs.isEmpty) return;

    final pantryData = activeDocs.first.data() as Map<String, dynamic>;
    final pantryName = pantryData['name'] ?? 'Pantry';

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Pantry'),
        content: Text(
          'Are you sure you want to leave "$pantryName"? You will lose access to its items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final nextPantries = pantries.where((p) => p.id != pantryToLeave);
      final nextPantry = nextPantries.isNotEmpty
          ? nextPantries.first
          : pantries.first;
      await _pantryService.leavePantry(pantryToLeave);
      if (mounted) {
        setState(
          () => PantryService.activePantryId = nextPantry.id != pantryToLeave
              ? nextPantry.id
              : '',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('You left "$pantryName".')));
      }
    }
  }
}
