import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meals/services/friends_service.dart';
import 'package:meals/services/gamification_service.dart';

class FriendDetailScreen extends StatelessWidget {
  final String friendId;
  final Map<String, dynamic> friendData;

  const FriendDetailScreen({
    super.key,
    required this.friendId,
    required this.friendData,
  });

  @override
  Widget build(BuildContext context) {
    final FriendsService friendsService = FriendsService();

    final String username = friendData['username'] ?? 'Unknown';
    final String avatar = friendData['profilePicture'] ?? '👨‍🍳';
    final int level = friendData['level'] ?? 1;
    final int totalCooked = friendData['totalRecipesCooked'] ?? 0;
    final String rank = GamificationService.getRankForLevel(level);

    return Scaffold(
      appBar: AppBar(
        title: Text(username),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'remove') {
                _confirmRemoveFriend(context, friendId, username);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'remove',
                child: Text('Remove Friend'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Column(
                children: [
                  Text(avatar, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    username,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    avatar: Icon(
                      Icons.military_tech,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      'Level $level - $rank',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$totalCooked recipes cooked',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),

            // Recently Cooked
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Recently Cooked Meals',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: friendsService.getFriendCookedMeals(friendId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'This chef hasn\'t cooked anything recently.',
                      ),
                    ),
                  );
                }

                final cookedDocs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cookedDocs.length,
                  itemBuilder: (context, index) {
                    final meal =
                        cookedDocs[index].data() as Map<String, dynamic>;
                    final Timestamp? timestamp = meal['cookedAt'];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading:
                            meal['image'] != null &&
                                (meal['image'] as String).isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  meal['image'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.restaurant_menu),
                                ),
                              )
                            : const SizedBox(
                                width: 50,
                                height: 50,
                                child: Icon(Icons.restaurant_menu),
                              ),
                        title: Text(meal['title'] ?? 'Unknown Recipe'),
                        subtitle: Text(
                          timestamp != null
                              ? 'Cooked on ${timestamp.toDate().toLocal().toString().split(' ')[0]}'
                              : 'Date unknown',
                        ),
                        trailing: Text('+${meal['earnedXP'] ?? 0} XP'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveFriend(
    BuildContext context,
    String friendId,
    String friendName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove $friendName?'),
        content: Text(
          'Are you sure you want to remove $friendName from your friends list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FriendsService().removeFriend(friendId);
        if (context.mounted) {
          Navigator.of(context).pop(); // Go back from detail screen
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error removing friend: $e')));
        }
      }
    }
  }
}
