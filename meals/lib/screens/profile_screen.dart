import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meals/services/auth_service.dart';
import 'package:meals/screens/auth_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedAvatar = '👨‍🍳';
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _avatars = [
    '👨‍🍳',
    '👩‍🍳',
    '🍕',
    '🥗',
    '🍔',
    '🥑',
    '🥞',
    '🌶️',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Încărcăm datele utilizatorului la deschiderea ecranului
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _selectedAvatar = data['profilePicture'] ?? '👨‍🍳';
          if (!_avatars.contains(_selectedAvatar)) {
            _avatars.add(
              _selectedAvatar,
            ); // În caz că are un emoji diferit salvat
          }
        });
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numele de utilizator nu poate fi gol!')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _authService.updateUserProfile(username, _selectedAvatar);

      final newPassword = _passwordController.text.trim();
      if (newPassword.isNotEmpty) {
        if (newPassword.length < 6) {
          throw Exception('Parola trebuie să aibă cel puțin 6 caractere.');
        }
        await _authService.updatePassword(newPassword);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profilul a fost actualizat cu succes!'),
          ),
        );
        Navigator.of(context).pop(); // Ne întoarcem la ecranul anterior
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = e.message ?? 'Eroare la actualizare.';
        if (e.code == 'requires-recent-login') {
          message =
              'Din motive de securitate, trebuie să te deconectezi și să te reautentifici pentru a schimba parola.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Eroare: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to completely delete your account? This action cannot be undone.',
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
      setState(() => _isSaving = true);
      try {
        await _authService.deleteAccount();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (ctx) => AuthWrapper()),
            (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          String message = e.message ?? 'Eroare la ștergerea contului.';
          if (e.code == 'requires-recent-login') {
            message =
                'Din motive de securitate, trebuie să te deconectezi și să te reautentifici înainte de a șterge contul.';
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          setState(() => _isSaving = false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Eroare: $e')));
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Choose an Avatar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: _avatars.map((avatar) {
                      final isSelected = _selectedAvatar == avatar;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAvatar = avatar),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: Text(
                            avatar,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Chef Name',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Change Password (Optional)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Leave empty to keep current',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Profile',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 64),
                  Divider(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isSaving ? null : _confirmDeleteAccount,
                    icon: Icon(
                      Icons.delete_forever,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    label: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
