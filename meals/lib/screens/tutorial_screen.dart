import 'package:flutter/material.dart';
import 'package:meals/services/auth_service.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  int _currentPage = 0;
  bool _isSaving = false;
  String _selectedAvatar = '👨‍🍳'; // Avatar default

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
  void dispose() {
    _usernameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _finishTutorial() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Te rugăm să alegi un nume de utilizator!'),
        ),
      );
      _pageController.animateToPage(
        3,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _authService.completeOnboarding(username, _selectedAvatar);
      // Aici nu este necesar un Navigator.push, deoarece StreamBuilder-ul
      // din AuthWrapper va detecta schimbarea stării și va încărca HomeScreen-ul.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Eroare: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildPage(
                    context,
                    topWidget: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 24,
                            spreadRadius: 8,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'media/APRON_image.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    title: 'Welcome to Apron',
                    description:
                        'Discover new recipes, cook delicious meals, and save your favorites for later.',
                  ),
                  _buildPage(
                    context,
                    topWidget: Icon(
                      Icons.kitchen,
                      size: 100,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: 'Smart Pantry',
                    description:
                        'Keep track of the ingredients you have at home. We will suggest recipes based on what you already have.',
                  ),
                  _buildPage(
                    context,
                    topWidget: Icon(
                      Icons.emoji_events,
                      size: 100,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: 'Level Up',
                    description:
                        'Cook meals to earn XP, level up, and progress from a Kitchen Novice to a Culinary Legend!',
                  ),
                  _buildCustomPage(
                    context,
                    title: 'Choose your Chef Name',
                    description: 'This is how other cooks will see you.',
                    child: TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'e.g., MasterChef99',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  _buildCustomPage(
                    context,
                    title: 'Pick an Avatar',
                    description:
                        'Choose a profile picture that represents your cooking style.',
                    child: Wrap(
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
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
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
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicator pentru pagini
                  Row(
                    children: List.generate(
                      5,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Butonul Next / Get Started
                  _currentPage == 4
                      ? FilledButton(
                          onPressed: _isSaving ? null : _finishTutorial,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Get Started'),
                        )
                      : TextButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Next'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required Widget topWidget,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          topWidget,
          const SizedBox(height: 48),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomPage(
    BuildContext context, {
    required String title,
    required String description,
    required Widget child,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            child,
          ],
        ),
      ),
    );
  }
}
