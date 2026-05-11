import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meals/screens/friend_detail_screen.dart';
import 'package:meals/services/friends_service.dart';
import 'package:meals/services/gamification_service.dart';
import 'package:meals/widgets/main_drawer.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FriendsService _friendsService = FriendsService();
  final TextEditingController _searchController = TextEditingController();
  Future<List<QueryDocumentSnapshot>>? _searchFuture;

  void _searchUsers() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _searchFuture = _friendsService.searchUsers(query);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.group), text: 'Friends'),
              Tab(icon: Icon(Icons.person_add_alt_1), text: 'Requests'),
              Tab(icon: Icon(Icons.search), text: 'Add Friends'),
            ],
          ),
        ),
        drawer: const MainDrawer(),
        body: TabBarView(
          children: [
            _buildFriendsList(),
            _buildRequestsList(),
            _buildAddFriendsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _friendsService.getFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'You have no friends yet. Add some from the "Add Friends" tab!',
              textAlign: TextAlign.center,
            ),
          );
        }

        final friendDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: friendDocs.length,
          itemBuilder: (context, index) {
            final friendId = friendDocs[index].id;
            return _buildUserCard(friendId);
          },
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _friendsService.getFriendRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No pending friend requests.'));
        }

        final requestDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: requestDocs.length,
          itemBuilder: (context, index) {
            final requesterId = requestDocs[index].id;
            return _buildUserCard(requesterId, isRequest: true);
          },
        );
      },
    );
  }

  Widget _buildAddFriendsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by exact username',
              hintText: 'e.g., MasterChef99',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searchUsers,
              ),
            ),
            onSubmitted: (_) => _searchUsers(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _searchFuture == null
                ? const Center(child: Text('Enter a username to search.'))
                : FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: _searchFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No users found with that name.'),
                        );
                      }

                      final userDocs = snapshot.data!;
                      return ListView.builder(
                        itemCount: userDocs.length,
                        itemBuilder: (context, index) {
                          final userId = userDocs[index].id;
                          return _buildUserCard(userId, isSearchResult: true);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    String userId, {
    bool isRequest = false,
    bool isSearchResult = false,
  }) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _friendsService.getUserData(userId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Card(child: ListTile(title: Text('Loading...')));
        }
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final level = userData['level'] ?? 1;

        Widget trailing;
        if (isRequest) {
          trailing = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                tooltip: 'Accept',
                onPressed: () => _friendsService.acceptFriendRequest(userId),
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                tooltip: 'Reject',
                onPressed: () => _friendsService.rejectFriendRequest(userId),
              ),
            ],
          );
        } else if (isSearchResult) {
          trailing = FutureBuilder<String>(
            future: _friendsService.checkFriendshipStatus(userId),
            builder: (context, statusSnapshot) {
              if (statusSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              final status = statusSnapshot.data ?? 'not_friends';
              switch (status) {
                case 'friends':
                  return const Tooltip(
                    message: 'Already friends',
                    child: Icon(Icons.check_circle, color: Colors.green),
                  );
                case 'request_sent':
                  return const Text('Sent');
                case 'request_received':
                  return ElevatedButton(
                    child: const Text('Accept'),
                    onPressed: () {
                      _friendsService.acceptFriendRequest(userId);
                      setState(() {
                        _searchFuture = _friendsService.searchUsers(
                          _searchController.text.trim(),
                        );
                      });
                    },
                  );
                default: // 'not_friends'
                  return IconButton(
                    icon: const Icon(Icons.person_add),
                    tooltip: 'Send friend request',
                    onPressed: () {
                      _friendsService.sendFriendRequest(userId);
                      setState(() {
                        _searchFuture = _friendsService.searchUsers(
                          _searchController.text.trim(),
                        );
                      });
                    },
                  );
              }
            },
          );
        } else {
          // It's a friend
          trailing = const Icon(Icons.arrow_forward_ios);
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Text(
              userData['profilePicture'] ?? '👨‍🍳',
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(userData['username'] ?? 'No name'),
            subtitle: Text(
              'Level $level - ${GamificationService.getRankForLevel(level)}',
            ),
            trailing: trailing,
            onTap: isRequest || isSearchResult
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => FriendDetailScreen(
                          friendId: userId,
                          friendData: userData,
                        ),
                      ),
                    );
                  },
          ),
        );
      },
    );
  }
}
