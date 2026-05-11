import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pantry_item.dart';
import '../services/pantry_service.dart';
import 'package:meals/widgets/main_drawer.dart';
import 'package:meals/widgets/pantry_item_card.dart';
import 'package:meals/widgets/add_pantry_item_dialog.dart';
import 'package:meals/utils/pantry_dialog_helper.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final PantryService _pantryService = PantryService();

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
            actions: [
              if (pantries.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share Pantry',
                  onPressed: () =>
                      PantryDialogHelper.showSharePantryDialog(context),
                ),
                if (isOwner) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit current pantry name',
                    onPressed: () =>
                        PantryDialogHelper.showEditPantryDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete current pantry',
                    onPressed: () => PantryDialogHelper.showDeletePantryDialog(
                      context,
                      (newId) =>
                          setState(() => PantryService.activePantryId = newId),
                    ),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.exit_to_app),
                    tooltip: 'Leave Pantry',
                    onPressed: () => PantryDialogHelper.showLeavePantryDialog(
                      context,
                      (newId) =>
                          setState(() => PantryService.activePantryId = newId),
                    ),
                  ),
                ],
              ],
              PopupMenuButton<String>(
                icon: const Icon(Icons.add_home_work),
                tooltip: 'Pantry Options',
                onSelected: (value) {
                  if (value == 'create') {
                    PantryDialogHelper.showAddPantryDialog(context);
                  } else if (value == 'join') {
                    PantryDialogHelper.showJoinPantryDialog(
                      context,
                      (newId) =>
                          setState(() => PantryService.activePantryId = newId),
                    );
                  }
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

                              return PantryItemCard(
                                item: item,
                                onDismissed: () {
                                  _pantryService.deletePantryItem(
                                    item.id!,
                                    PantryService.activePantryId,
                                  );
                                },
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
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AddPantryItemDialog(
                        activePantryId: PantryService.activePantryId,
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }
}
