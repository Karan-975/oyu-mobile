import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../boreholes/boreholes_list_screen.dart';
import '../boreholes/create_borehole_screen.dart';
import '../offline/offline_sync_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/reports_screen.dart';
import '../surveys/surveys_hub_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().loadBoreholes();
    });
  }

  void _navigateTo(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // close drawer
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final pages = [
      DashboardScreen(
        onViewAllBoreholes: () => setState(() => _selectedIndex = 1),
        onNavigateToReports: () => setState(() => _selectedIndex = 3),
      ),
      const BoreholesListScreen(),
      const SurveysHubScreen(),
      const ReportsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      drawer: _AppDrawer(
        user: user,
        selectedIndex: _selectedIndex,
        onNavigate: _navigateTo,
        onLogout: () async {
          Navigator.pop(context);
          await context.read<AuthProvider>().logout();
        },
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Boreholes',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Surveys',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final dynamic user;
  final int selectedIndex;
  final void Function(int) onNavigate;
  final VoidCallback onLogout;

  const _AppDrawer({
    required this.user,
    required this.selectedIndex,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Field Member',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.email ?? '',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'NGO Team Member',
                            style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard,
                    label: 'Dashboard',
                    isSelected: selectedIndex == 0,
                    onTap: () => onNavigate(0),
                  ),
                  _DrawerItem(
                    icon: Icons.water_drop_outlined,
                    selectedIcon: Icons.water_drop,
                    label: 'Boreholes',
                    isSelected: selectedIndex == 1,
                    onTap: () => onNavigate(1),
                  ),
                  _DrawerItem(
                    icon: Icons.assignment_outlined,
                    selectedIcon: Icons.assignment,
                    label: 'Surveys',
                    isSelected: selectedIndex == 2,
                    onTap: () => onNavigate(2),
                  ),
                  _DrawerItem(
                    icon: Icons.bar_chart_outlined,
                    selectedIcon: Icons.bar_chart,
                    label: 'Reports',
                    isSelected: selectedIndex == 3,
                    onTap: () => onNavigate(3),
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_outlined,
                    selectedIcon: Icons.notifications,
                    label: 'Notifications',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.add_location_alt_outlined,
                    selectedIcon: Icons.add_location_alt,
                    label: 'Register Borehole',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateBoreholeScreen(
                            currentUserId: user?.id ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.sync_lock_outlined,
                    selectedIcon: Icons.sync,
                    label: 'Drafts & Sync',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OfflineSyncScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 20, indent: 8, endIndent: 8),
                  _DrawerItem(
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Profile',
                    isSelected: selectedIndex == 4,
                    onTap: () => onNavigate(4),
                  ),
                ],
              ),
            ),

            // Logout
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
              child: _DrawerItem(
                icon: Icons.logout,
                selectedIcon: Icons.logout,
                label: 'Logout',
                isSelected: false,
                color: AppColors.error,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Logout',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      content: Text('Are you sure you want to logout?',
                          style: GoogleFonts.inter(color: AppColors.muted)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: onLogout,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? (isSelected ? AppColors.primary : AppColors.navy);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        onTap: onTap,
        selected: isSelected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: itemColor,
          size: 21,
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: itemColor,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        dense: true,
        minLeadingWidth: 0,
      ),
    );
  }
}
