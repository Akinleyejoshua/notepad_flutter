import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/global_overlay.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'note_editor_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Dynamic header data per tab
  String get _headerTitle {
    switch (_currentIndex) {
      case 1:
        return 'Search';
      default:
        return 'Notepad';
    }
  }

  String? get _headerSubtitle {
    switch (_currentIndex) {
      case 1:
        return 'Find your notes quickly';
      default:
        return 'Your thoughts, spoken and captured.';
    }
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _onCreatePressed() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GlobalOverlay(child: NoteEditorScreen()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Header
          AppHeader(title: _headerTitle, subtitle: _headerSubtitle),

          // Content area
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const [HomeScreen(), SearchScreen()],
            ),
          ),

          // Bottom nav bar
          BottomNavBar(
            currentIndex: _currentIndex,
            onTabSelected: _onTabSelected,
            onCreatePressed: _onCreatePressed,
          ),
        ],
      ),
    );
  }
}
