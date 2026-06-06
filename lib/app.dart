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
  double _posX = 0;
  double _posY = 0;
  bool _isInitialized = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (!_isInitialized) {
      _posX = size.width - 76; // 16px margin + 60px size
      _posY = size.height * 0.7;
      _isInitialized = true;
    }

    final screens = [
      const HomeScreen(),
      const TaskListScreen(),
      const ScheduleScreen(),
      const StatsScreen(),
      const SettingsScreen(),
    ];

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: screens,
          ),
          
          // Draggable Chathead
          AnimatedPositioned(
            duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            left: _posX,
            top: _posY,
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _isDragging = true;
                });
              },
              onPanUpdate: (details) {
                final currentSize = MediaQuery.of(context).size;
                setState(() {
                  _posX += details.delta.dx;
                  _posY += details.delta.dy;
                  // Restrict coordinates inside screen boundaries
                  _posX = _posX.clamp(0.0, currentSize.width - 60.0);
                  _posY = _posY.clamp(100.0, currentSize.height - 180.0);
                });
              },
              onPanEnd: (details) {
                final currentSize = MediaQuery.of(context).size;
                setState(() {
                  _isDragging = false;
                  // Snap to nearest side (left or right)
                  if (_posX + 30.0 < currentSize.width / 2) {
                    _posX = 16.0;
                  } else {
                    _posX = currentSize.width - 60.0 - 16.0;
                  }
                });
              },
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChatbotScreen(),
                  ),
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary,
                        scheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // AI Robot Icon
                      const Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      // Green Online Dot indicator
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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