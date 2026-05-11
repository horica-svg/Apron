import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  // --- SEARCH ---
  /// Searches for users by their exact username.
  /// Excludes the current user from results.
  Future<List<QueryDocumentSnapshot>> searchUsers(String username) async {
    if (_currentUser == null) throw Exception('User not logged in');

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      // Filter out the current user from the search results
      return snapshot.docs.where((doc) => doc.id != _currentUser!.uid).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Please check Firestore Rules.');
      }
      throw Exception('Failed to search users: ${e.message}');
    }
  }

  // --- FRIEND REQUESTS ---

  /// Sends a friend request to a user.
  Future<void> sendFriendRequest(String targetUserId) async {
    if (_currentUser == null) throw Exception('User not logged in');
    if (_currentUser!.uid == targetUserId) return; // Can't add yourself

    // Add request to target user's friend_requests subcollection
    await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('friend_requests')
        .doc(_currentUser!.uid)
        .set({'requestedAt': FieldValue.serverTimestamp()});
  }

  /// Gets a stream of incoming friend requests for the current user.
  /// Each document contains the UID of the user who sent the request.
  Stream<QuerySnapshot> getFriendRequests() {
    if (_currentUser == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('friend_requests')
        .orderBy('requestedAt', descending: true)
        .snapshots();
  }

  /// Accepts a friend request.
  Future<void> acceptFriendRequest(String requesterId) async {
    if (_currentUser == null) throw Exception('User not logged in');

    final batch = _firestore.batch();

    // 1. Add requester to current user's friends list
    final currentUserFriendRef = _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('friends')
        .doc(requesterId);
    batch.set(currentUserFriendRef, {'since': FieldValue.serverTimestamp()});

    // 2. Add current user to requester's friends list
    final requesterFriendRef = _firestore
        .collection('users')
        .doc(requesterId)
        .collection('friends')
        .doc(_currentUser!.uid);
    batch.set(requesterFriendRef, {'since': FieldValue.serverTimestamp()});

    // 3. Delete the friend request
    final requestRef = _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('friend_requests')
        .doc(requesterId);
    batch.delete(requestRef);

    await batch.commit();
  }

  /// Rejects a friend request.
  Future<void> rejectFriendRequest(String requesterId) async {
    if (_currentUser == null) throw Exception('User not logged in');
    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('friend_requests')
        .doc(requesterId)
        .delete();
  }

  // --- FRIENDS LIST ---

  /// Gets a stream of the current user's friends (their UIDs).
  Stream<QuerySnapshot> getFriends() {
    if (_currentUser == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('friends')
        .snapshots();
  }

  /// Removes a friend.
  Future<void> removeFriend(String friendId) async {
    if (_currentUser == null) throw Exception('User not logged in');

    final batch = _firestore.batch();

    // 1. Remove friend from current user's list
    final currentUserFriendRef = _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('friends')
        .doc(friendId);
    batch.delete(currentUserFriendRef);

    // 2. Remove current user from friend's list
    final friendUserFriendRef = _firestore
        .collection('users')
        .doc(friendId)
        .collection('friends')
        .doc(_currentUser!.uid);
    batch.delete(friendUserFriendRef);

    await batch.commit();
  }

  // --- FRIEND DATA ---

  /// Gets a stream of a specific user's public data.
  Stream<DocumentSnapshot> getUserData(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  /// Gets a stream of a friend's cooked meals.
  Stream<QuerySnapshot> getFriendCookedMeals(String friendId) {
    return _firestore
        .collection('users')
        .doc(friendId)
        .collection('cooked_meals')
        .orderBy('cookedAt', descending: true)
        .limit(10) // Limit to the last 10
        .snapshots();
  }

  /// Checks the friendship status between the current user and another user.
  /// Returns 'friends', 'request_sent', 'request_received', or 'not_friends'.
  Future<String> checkFriendshipStatus(String otherUserId) async {
    if (_currentUser == null) return 'not_friends';
    final myUid = _currentUser!.uid;

    // Check if they are friends
    final friendDoc = await _firestore
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(otherUserId)
        .get();
    if (friendDoc.exists) {
      return 'friends';
    }

    // Check if I sent a request to them
    final sentRequestDoc = await _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('friend_requests')
        .doc(myUid)
        .get();
    if (sentRequestDoc.exists) {
      return 'request_sent';
    }

    // Check if they sent a request to me
    final receivedRequestDoc = await _firestore
        .collection('users')
        .doc(myUid)
        .collection('friend_requests')
        .doc(otherUserId)
        .get();
    if (receivedRequestDoc.exists) {
      return 'request_received';
    }

    return 'not_friends';
  }
}
