import 'package:agilemeets/screens/calendar/calendar_screen.dart';
import 'package:agilemeets/screens/home_page.dart';
import 'package:agilemeets/screens/organization/organization_dashboard_screen.dart';
import 'package:agilemeets/screens/project/project_list_screen.dart';
import 'package:agilemeets/widgets/organization/add_members_dialog.dart';
import 'package:agilemeets/widgets/project/create_project_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/cubits/auth/auth_cubit.dart';
import '../logic/cubits/auth/auth_state.dart';

class ShellScreen extends StatefulWidget {
  static final ValueNotifier<int> selectedTabNotifier = ValueNotifier<int>(0);
  
  const ShellScreen({super.key});

  static void navigateToTab(int index) {
    selectedTabNotifier.value = index;
  }

  @override
  State<ShellScreen> createState() => ShellScreenState();
}

class ShellScreenState extends State<ShellScreen> {
  @override
  void initState() {
    super.initState();
    ShellScreen.selectedTabNotifier.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    setState(() {
      _selectedIndex = ShellScreen.selectedTabNotifier.value;
    });
  }

  @override
  void dispose() {
    ShellScreen.selectedTabNotifier.removeListener(_handleTabChange);
    super.dispose();
  }

  int _selectedIndex = 0;

  final List<NavigationDestination> _adminDestinations = [
    const NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    const NavigationDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: 'Projects',
    ),
    const NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Calendar',
    ),
    const NavigationDestination(
      icon: Icon(Icons.admin_panel_settings_outlined),
      selectedIcon: Icon(Icons.admin_panel_settings),
      label: 'Management',
    ),
  ];

  final List<NavigationDestination> _userDestinations = [
    const NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    const NavigationDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: 'Projects',
    ),
    const NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Calendar',
    ),
    const NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  void _handleFabPressed(BuildContext context) {
    switch (_selectedIndex) {
      case 0: // Home
        if (context.read<AuthCubit>().state.isAdmin) {
          _showCreateMenu(context);
        }
        break;
      case 1: // Projects
        if (context.read<AuthCubit>().state.isAdmin) {
          showDialog(
            context: context,
            builder: (context) => const CreateProjectDialog(),
          );
        }
        break;
      case 3: // Management (admin only)
        if (context.read<AuthCubit>().state.isAdmin) {
          showDialog(
            context: context,
            builder: (context) => const AddMembersDialog(),
          );
        }
        break;
    }
  }

  void _showCreateMenu(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha:0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Create New',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: Icon(Icons.group_add, color: theme.colorScheme.primary),
              title: const Text('Add a Member'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const AddMembersDialog(),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.folder_open, color: theme.colorScheme.primary),
              title: const Text('New Project'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to create project screen
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
              title: const Text('Schedule Meeting'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to schedule meeting screen
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void setTab(int index) {
    setState(() {
      _selectedIndex = index;
      ShellScreen.selectedTabNotifier.value = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final destinations = authState.isAdmin ? _adminDestinations : _userDestinations;
        final screens = authState.isAdmin 
          ? [
              const HomePage(),
              const ProjectListScreen(),
              const CalendarScreen(),
              const OrganizationDashboardScreen(),
            ]
          : [
              const HomePage(),
              const ProjectListScreen(),
              const CalendarScreen(),
              const ProfileScreen(),
            ];
        
        return Scaffold(
         
          body: IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: setTab,
            destinations: destinations,
          ),
          floatingActionButton: _buildFAB(theme),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  Widget _getScreenTitle(int index) {
    switch (index) {
      case 0:
        return const Text('Home');
      case 1:
        return const Text('Projects');
      case 2:
        return const Text('Calendar');
      case 3:
        return const Text('Management');
      default:
        return const Text('');
    }
  }

  Widget? _buildFAB(ThemeData theme) {
    if (!context.read<AuthCubit>().state.isAdmin) {
      return null;
    }
    if (!context.read<AuthCubit>().state.isAdmin) {
      if (_selectedIndex == 3) return null;
    }
    
    return InkWell(
      onTap: () => _handleFabPressed(context),
      child: Container(
        height: 52.h,
        width: 52.h,
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: theme.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha:0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 26.w,
        ),
      ).animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut
        )
        .shimmer(delay: 2.seconds, duration: 1.seconds),
    );
  }
}