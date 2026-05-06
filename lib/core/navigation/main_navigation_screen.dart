import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/learning/presentation/cubit/learning_items_cubit.dart';
import '../../features/learning/presentation/cubit/learning_items_state.dart';
import '../../features/learning/presentation/screens/home_screen.dart';
import '../../features/memory_game/presentation/screens/memory_game_screen.dart';
import '../../features/pronunciation/presentation/cubit/pronunciation_cubit.dart';
import '../../features/pronunciation/presentation/screens/pronunciation_screen.dart';
import '../../features/review/presentation/review_flow_launcher.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../di/service_locator.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: IndexedStack(
        index: _currentIndex,
        children: const <Widget>[
          HomeScreen(),
          _PracticeTab(),
          _LearnTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFF5F7FF),
        selectedItemColor: const Color(0xFF8A8CFF),
        unselectedItemColor: const Color(0xFF9095A5),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none_rounded),
            activeIcon: Icon(Icons.mic_rounded),
            label: 'Practice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school_rounded),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _PracticeTab extends StatelessWidget {
  const _PracticeTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningItemsCubit, LearningItemsState>(
      builder: (BuildContext context, LearningItemsState state) {
        return BlocProvider<PronunciationCubit>(
          create:
              (_) => PronunciationCubit(
                textToSpeechService: ServiceLocator.textToSpeechService,
                speechToTextService: ServiceLocator.speechToTextService,
                pronunciationEvaluator: ServiceLocator.pronunciationEvaluator,
              ),
          child: PronunciationScreen(items: state.items),
        );
      },
    );
  }
}

class _LearnTab extends StatelessWidget {
  const _LearnTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningItemsCubit, LearningItemsState>(
      builder: (BuildContext context, LearningItemsState state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FF),
          appBar: AppBar(title: const Text('Learn')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _LearnActionCard(
                    title: 'Memorama',
                    subtitle: 'Relaciona frases con su significado.',
                    icon: Icons.psychology_alt_rounded,
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => MemoryGameScreen(verbs: state.items),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _LearnActionCard(
                    title: 'Review',
                    subtitle: 'Repasa tarjetas pendientes para hoy.',
                    icon: Icons.auto_awesome_rounded,
                    onTap: () => ReviewFlowLauncher.openReview(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LearnActionCard extends StatelessWidget {
  const _LearnActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 28),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Profile'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFEEF3FF), Color(0xFFE7F5EE)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.person_rounded,
                size: 42,
                color: Color(0xFF3F5873),
              ),
              const SizedBox(height: 12),
              Text(
                'Your learning profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure reminders from the settings icon.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
