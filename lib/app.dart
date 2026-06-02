import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskai/core/constants/app_constants.dart';
import 'package:taskai/core/theme/app_theme.dart';
import 'package:taskai/presentation/providers/app_providers.dart';
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

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const MainShell(),
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

  static const _screens = [
    HomeScreen(),
    TaskListScreen(),
    ScheduleScreen(),
    ChatbotScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
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