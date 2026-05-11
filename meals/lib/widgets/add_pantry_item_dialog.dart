import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import '../services/pantry_service.dart';
import '../services/recipe_service.dart';

class AddPantryItemDialog extends StatefulWidget {
  final String activePantryId;

  const AddPantryItemDialog({super.key, required this.activePantryId});

  @override
  State<AddPantryItemDialog> createState() => _AddPantryItemDialogState();
}

class _AddPantryItemDialogState extends State<AddPantryItemDialog> {
  final PantryService _pantryService = PantryService();
  final SpoonacularService _spoonacularService = SpoonacularService();

  String _itemName = '';
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  String _selectedUnit = 'pcs';
  String _selectedCategory = 'Other';
  DateTime? _selectedDate;

  final List<String> _categories = [
    'Vegetable',
    'Fruit',
    'Meat',
    'Dairy',
    'Grain',
    'Spice',
    'Other',
  ];
  final List<String> _units = ['pcs', 'kg', 'g', 'l', 'ml'];

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _saveItem() {
    final name = _itemName.trim();
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;

    if (name.isNotEmpty && quantity > 0) {
      _pantryService.addPantryItem(
        PantryItem(
          name: name,
          quantity: quantity,
          unit: _selectedUnit,
          category: _selectedCategory,
          expiryDate: _selectedDate,
        ),
        widget.activePantryId,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  return await _spoonacularService.getIngredientSuggestions(
                    textEditingValue.text,
                  );
                } catch (e) {
                  return const Iterable<String>.empty();
                }
              },
              onSelected: (String selection) {
                _itemName = selection;
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
                      onChanged: (val) => _itemName = val,
                    );
                  },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    items: _units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedUnit = val!),
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  _selectedDate == null
                      ? 'No Expiry Date'
                      : 'Expires: ${_selectedDate!.toString().split(' ')[0]}',
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
                      setState(() => _selectedDate = picked);
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
        ElevatedButton(onPressed: _saveItem, child: const Text('Save')),
      ],
    );
  }
}
