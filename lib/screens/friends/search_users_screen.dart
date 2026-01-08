import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/friends_service.dart';
import '../../providers/auth_provider.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final _searchController = TextEditingController();
  final _friendsService = FriendsService();
  List<UserModel> _searchResults = [];
  bool _isLoading = false;
  final Map<String, bool> _friendStatus = {};
  final Map<String, String?> _requestStatus = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final currentUserId = context.read<AuthProvider>().user?.uid ?? '';
    final results = await _friendsService.searchUsers(query, currentUserId);

    // Check friend status for each user
    for (var user in results) {
      final isFriend = await _friendsService.areFriends(currentUserId, user.uid);
      final requestStatus = await _friendsService.checkFriendRequestStatus(currentUserId, user.uid);
      _friendStatus[user.uid] = isFriend;
      _requestStatus[user.uid] = requestStatus;
    }

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  Future<void> _sendFriendRequest(UserModel receiver) async {
    final sender = context.read<AuthProvider>().user;
    if (sender == null) return;

    final success = await _friendsService.sendFriendRequest(sender, receiver);

    if (success && mounted) {
      setState(() {
        _requestStatus[receiver.uid] = 'sent';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent!'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send request'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Friends'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchUsers('');
                  },
                )
                    : null,
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Search for friends'
                        : 'No users found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                final isFriend = _friendStatus[user.uid] ?? false;
                final requestStatus = _requestStatus[user.uid];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      (user.displayName ?? user.email)
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user.displayName ?? user.email),
                  subtitle: Text(user.email),
                  trailing: isFriend
                      ? const Chip(label: Text('Friends'), backgroundColor: Colors.green)
                      : requestStatus == 'sent'
                      ? const Chip(label: Text('Pending'))
                      : requestStatus == 'received'
                      ? const Chip(label: Text('Respond'), backgroundColor: Colors.orange)
                      : ElevatedButton.icon(
                    onPressed: () => _sendFriendRequest(user),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}