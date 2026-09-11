import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../dashboard/presentation/dashboard_screen.dart';
import '../groups/presentation/groups_screen.dart';
import '../settings/presentation/settings_screen.dart';
import '../students/presentation/students_screen.dart';

class MainNavScaffold extends StatefulWidget {
  const MainNavScaffold({super.key});

  @override
  State<MainNavScaffold> createState() => _MainNavScaffoldState();
}

class _MainNavScaffoldState extends State<MainNavScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    StudentsScreen(),
    GroupsScreen(),
    SettingsScreen(),
  ];

  final List<CNTabBarItem> _tabItems = const [
    CNTabBarItem(
      label: 'الرئيسية',
      icon: CNSymbol('square.grid.2x2'),
    ),
    CNTabBarItem(
      label: 'الطلاب',
      icon: CNSymbol('person.2'),
    ),
    CNTabBarItem(
      label: 'المجموعات',
      icon: CNSymbol('rectangle.3.group'),
    ),
    CNTabBarItem(
      label: 'الإعدادات',
      icon: CNSymbol('gearshape'),
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    return Scaffold(
      extendBody: isIos,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          if (isIos)
            Align(
              alignment: Alignment.bottomCenter,
              child: CNTabBar(
                items: _tabItems.reversed.toList(),
                currentIndex: (_tabItems.length - 1) - _currentIndex,
                tint: AppColors.primary,
                height: 85,
                onTap: (reversedIndex) {
                  final logicalIndex = (_tabItems.length - 1) - reversedIndex;
                  setState(() => _currentIndex = logicalIndex);
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: isIos ? null : _buildAndroidNavBar(context),
    );
  }

  Widget _buildAndroidNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppColors.cardBorder, width: 0.8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 64,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                );
              }
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(
                  color: AppColors.primary,
                  size: 24,
                );
              }
              return const IconThemeData(
                color: AppColors.textSecondary,
                size: 24,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: 'الطلاب',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: 'المجموعات',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'الإعدادات',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
