import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meals/services/pantry_service.dart';

class PantryDialogHelper {
  static final PantryService _pantryService = PantryService();

  static Future<void> showAddPantryDialog(BuildContext context) async {
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
                if (context.mounted) {
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

  static Future<void> showDeletePantryDialog(
    BuildContext context,
    Function(String) onPantryChanged,
  ) async {
    final pantriesSnapshot = await _pantryService.getUserPantries().first;
    final pantries = pantriesSnapshot.docs;

    if (pantries.length <= 1) {
      if (!context.mounted) return;
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

    if (!context.mounted) return;
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

      if (context.mounted) {
        onPantryChanged(nextPantry.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pantry "$pantryName" deleted.')),
        );
      }
    }
  }

  static Future<void> showEditPantryDialog(BuildContext context) async {
    final pantriesSnapshot = await _pantryService.getUserPantries().first;
    final pantries = pantriesSnapshot.docs;

    final activeDocs = pantries
        .where((p) => p.id == PantryService.activePantryId)
        .toList();
    if (activeDocs.isEmpty) return;

    final pantryData = activeDocs.first.data() as Map<String, dynamic>;
    final currentName = pantryData['name'] ?? 'Pantry';

    final controller = TextEditingController(text: currentName);

    if (!context.mounted) return;
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
                if (context.mounted) {
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

  static void showSharePantryDialog(BuildContext context) {
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

  static Future<void> showJoinPantryDialog(
    BuildContext context,
    Function(String) onPantryChanged,
  ) async {
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
                  if (context.mounted) {
                    onPantryChanged(code);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully joined the pantry!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  static Future<void> showLeavePantryDialog(
    BuildContext context,
    Function(String) onPantryChanged,
  ) async {
    final pantriesSnapshot = await _pantryService.getUserPantries().first;
    final pantries = pantriesSnapshot.docs;

    final pantryToLeave = PantryService.activePantryId;
    final activeDocs = pantries.where((p) => p.id == pantryToLeave).toList();
    if (activeDocs.isEmpty) return;

    final pantryData = activeDocs.first.data() as Map<String, dynamic>;
    final pantryName = pantryData['name'] ?? 'Pantry';

    if (!context.mounted) return;
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
      if (context.mounted) {
        onPantryChanged(nextPantry.id != pantryToLeave ? nextPantry.id : '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('You left "$pantryName".')));
      }
    }
  }
}
