import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/core/constants/app_constants.dart';
import 'package:taskai/core/theme/app_theme.dart';
import 'package:taskai/presentation/providers/app_providers.dart';
import 'package:taskai/presentation/providers/auth_provider.dart';
import 'package:taskai/presentation/screens/auth/login_screen.dart';
import 'package:taskai/presentation/screens/chatbot_screen.dart';
import 'package:taskai/presentation/screens/home_screen.dart';
import 'package:taskai/presentation/screens/schedule_screen.dart';
import 'package:taskai/presentation/screens/settings_screen.dart';
import 'package:taskai/presentation/screens/stats_screen.dart';
import 'package:taskai/presentation/screens/task_list_screen.dart';

class TaskAIApp extends ConsumerWidget {
  const TaskAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);
    final isGuest = ref.watch(guestModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: authState.when(
        data: (user) {
          if (user != null || isGuest) {
            return const MainShell();
          }
          return LoginScreen(
            onContinueAsGuest: () {
              ref.read(guestModeProvider.notifier).state = true;
            },
          );
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, stack) => Scaffold(
          body: Center(
            child: Text('Lỗi khởi động: $err'),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _goHome() {
    setState(() {
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const TaskListScreen(),
      const ScheduleScreen(),
      ChatbotScreen(onBackHome: _goHome),
      const StatsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            label: 'Task',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Lịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_rounded),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Thống kê',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}