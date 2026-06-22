import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/data_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../boreholes/borehole_detail_screen.dart';
import '../notifications/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onViewAllBoreholes;
  final VoidCallback? onNavigateToReports;

  const DashboardScreen({
    super.key,
    required this.onViewAllBoreholes,
    this.onNavigateToReports,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().loadBoreholes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final boreholes = data.boreholes;

    final pendingSurveys = boreholes.length; // approximate
    final completed = 0;
    final drafts = 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: data.loadBoreholes,
          child: CustomScrollView(
            slivers: [
              // ── Hero App Bar ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  Center(
                    child: _SyncStatusChip(isLoading: data.isLoading),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.85),
                          const Color(0xFF065F46),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    Scaffold.of(context).openDrawer();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white, size: 22),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hello, ${user?.fullName.split(' ').first ?? 'Field Member'} 👋',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        user?.ngoName ?? 'NGO Team Member',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Summary chips
                            Row(
                              children: [
                                _HeroStatChip(
                                  label: 'Assigned',
                                  value: '${boreholes.length}',
                                  icon: Icons.water_drop_outlined,
                                ),
                                const SizedBox(width: 10),
                                _HeroStatChip(
                                  label: 'Pending',
                                  value: '$pendingSurveys',
                                  icon: Icons.pending_outlined,
                                ),
                                const SizedBox(width: 10),
                                _HeroStatChip(
                                  label: 'Completed',
                                  value: '$completed',
                                  icon: Icons.check_circle_outline,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Summary Cards ─────────────────────────────────────
                      SizedBox(
                        height: 125,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          children: [
                            _SummaryCard(
                              label: 'Assigned\nBoreholes',
                              value: '${boreholes.length}',
                              icon: Icons.water_drop,
                              color: AppColors.primary,
                              onTap: widget.onViewAllBoreholes,
                            ),
                            const SizedBox(width: 12),
                            _SummaryCard(
                              label: 'Pending\nSurveys',
                              value: '$pendingSurveys',
                              icon: Icons.assignment_outlined,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 12),
                            _SummaryCard(
                              label: 'Completed\nSurveys',
                              value: '$completed',
                              icon: Icons.check_circle_outline,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 12),
                            _SummaryCard(
                              label: 'Drafts\nPending Sync',
                              value: '$drafts',
                              icon: Icons.drafts_outlined,
                              color: AppColors.info,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Survey Modules Quick Access ───────────────────────
                      Text(
                        'Survey Modules',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.1,
                        children: [
                          _ModuleQuickCard(
                            label: 'Borehole\nRecce',
                            icon: Icons.travel_explore,
                            color: AppColors.primary,
                            onTap: widget.onViewAllBoreholes,
                          ),
                          _ModuleQuickCard(
                            label: 'Baseline\nSurvey',
                            icon: Icons.fact_check_outlined,
                            color: AppColors.info,
                            onTap: widget.onViewAllBoreholes,
                          ),
                          _ModuleQuickCard(
                            label: 'LSC\nConsult.',
                            icon: Icons.groups_2_outlined,
                            color: AppColors.warning,
                            onTap: widget.onViewAllBoreholes,
                          ),
                          _ModuleQuickCard(
                            label: 'Monitoring\nSurvey',
                            icon: Icons.monitor_heart_outlined,
                            color: AppColors.success,
                            onTap: widget.onViewAllBoreholes,
                          ),
                          _ModuleQuickCard(
                            label: 'Grievance\nReport',
                            icon: Icons.report_problem_outlined,
                            color: AppColors.error,
                            onTap: widget.onViewAllBoreholes,
                          ),
                          _ModuleQuickCard(
                            label: 'Rehabilitation',
                            icon: Icons.handyman_outlined,
                            color: const Color(0xFF7C3AED),
                            onTap: widget.onViewAllBoreholes,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Assigned Boreholes ────────────────────────────────
                      Row(
                        children: [
                          Text(
                            'Assigned Boreholes',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: widget.onViewAllBoreholes,
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (data.isLoading && boreholes.isEmpty)
                        const AppLoader()
                      else if (boreholes.isEmpty)
                        AppEmptyState(
                          icon: Icons.water_drop_outlined,
                          title: 'No Assignments Yet',
                          description: 'Contact your NGO Admin to get boreholes assigned.',
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: boreholes.length > 4 ? 4 : boreholes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final b = boreholes[i];
                            return _BoreholeAssignmentCard(
                              borehole: b,
                              currentUserId: user?.id ?? '',
                            );
                          },
                        ),
                      const SizedBox(height: 24),

                      // ── Recent Activity ───────────────────────────────────
                      Row(
                        children: [
                          Text(
                            'Recent Activity',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
                          ),
                          const Spacer(),
                          TextButton(onPressed: () {}, child: const Text('View All')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _RecentActivityCard(
                        icon: Icons.info_outline,
                        text: 'Activity log will appear here after surveys are submitted.',
                        time: 'Now',
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 24),

                      // ── Draft & Offline Status ────────────────────────────
                      AppCard(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.cloud_done_outlined, color: AppColors.success, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'All Data Synced',
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
                                  ),
                                  Text(
                                    '$drafts drafts pending • Last sync: Just now',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => data.loadBoreholes(),
                              child: const Text('Sync', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting Widgets ─────────────────────────────────────────────────────────

class _SyncStatusChip extends StatelessWidget {
  final bool isLoading;
  const _SyncStatusChip({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
            )
          else
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
            ),
          const SizedBox(width: 5),
          Text(
            isLoading ? 'Syncing...' : 'Online',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroStatChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleQuickCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ModuleQuickCard({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.navy, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoreholeAssignmentCard extends StatelessWidget {
  final Borehole borehole;
  final String currentUserId;

  const _BoreholeAssignmentCard({required this.borehole, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BoreholeDetailScreen(borehole: borehole, currentUserId: currentUserId),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  borehole.uniqueId,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
                Text(
                  '${borehole.village}, ${borehole.district}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          StatusPill.fromStatus(borehole.status),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.subtle),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final String time;
  final Color color;

  const _RecentActivityCard({
    required this.icon,
    required this.text,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted, height: 1.4),
            ),
          ),
          Text(time, style: GoogleFonts.inter(fontSize: 10, color: AppColors.subtle)),
        ],
      ),
    );
  }
}
