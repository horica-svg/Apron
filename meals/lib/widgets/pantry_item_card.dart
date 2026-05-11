import 'package:flutter/material.dart';
import '../models/pantry_item.dart';

class PantryItemCard extends StatelessWidget {
  final PantryItem item;
  final VoidCallback onDismissed;

  const PantryItemCard({
    super.key,
    required this.item,
    required this.onDismissed,
  });

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
      color = Theme.of(context).colorScheme.error;
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

  @override
  Widget build(BuildContext context) {
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
      onDismissed: (_) => onDismissed(),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
              Text('${item.quantity} ${item.unit} • ${item.category}'),
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
  }
}
