import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../boreholes/borehole_detail_screen.dart';

/// Reports screen — spec §11.3b bottom nav tab
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final boreholes = data.boreholes;

    // Compute simple stats
    final total = boreholes.length;
    final functional = boreholes.where((b) => b.status.toLowerCase() == 'active' || b.status.toLowerCase() == 'functional').length;
    final nonFunctional = boreholes.where((b) => b.status.toLowerCase() == 'inactive' || b.status.toLowerCase() == 'non_functional').length;
    final underRehab = boreholes.where((b) => b.status.toLowerCase() == 'under_rehabilitation').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => data.loadBoreholes(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: data.loadBoreholes,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Overview header ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Field Operations Report',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.fullName ?? 'NGO Team Member',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _ReportStat(label: 'Total\nBoreholes', value: '$total', color: Colors.white),
                      _ReportStat(label: 'Functional', value: '$functional', color: const Color(0xFF4ADE80)),
                      _ReportStat(label: 'Non-\nFunctional', value: '$nonFunctional', color: const Color(0xFFF87171)),
                      _ReportStat(label: 'Under\nRehab', value: '$underRehab', color: const Color(0xFFFBBF24)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Status breakdown ───────────────────────────────────────────
            Text(
              'Borehole Status Breakdown',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  _StatusProgressRow(
                    label: 'Functional',
                    count: functional,
                    total: total,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  _StatusProgressRow(
                    label: 'Non-Functional',
                    count: nonFunctional,
                    total: total,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  _StatusProgressRow(
                    label: 'Under Rehabilitation',
                    count: underRehab,
                    total: total,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 12),
                  _StatusProgressRow(
                    label: 'Other / Pending',
                    count: total - functional - nonFunctional - underRehab,
                    total: total,
                    color: AppColors.info,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Survey completion ──────────────────────────────────────────
            Text(
              'Survey Module Completion',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  _ModuleCompletionRow(
                    icon: Icons.travel_explore,
                    label: 'Borehole Recce',
                    color: AppColors.primary,
                    completed: 0,
                    total: total,
                  ),
                  const Divider(height: 20),
                  _ModuleCompletionRow(
                    icon: Icons.fact_check_outlined,
                    label: 'Baseline Survey',
                    color: AppColors.info,
                    completed: 0,
                    total: total,
                  ),
                  const Divider(height: 20),
                  _ModuleCompletionRow(
                    icon: Icons.groups_2_outlined,
                    label: 'LSC Consultation',
                    color: AppColors.warning,
                    completed: 0,
                    total: total,
                  ),
                  const Divider(height: 20),
                  _ModuleCompletionRow(
                    icon: Icons.handyman_outlined,
                    label: 'Rehabilitation',
                    color: const Color(0xFF7C3AED),
                    completed: 0,
                    total: total,
                  ),
                  const Divider(height: 20),
                  _ModuleCompletionRow(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Monitoring Survey',
                    color: AppColors.success,
                    completed: 0,
                    total: total,
                  ),
                  const Divider(height: 20),
                  _ModuleCompletionRow(
                    icon: Icons.report_problem_outlined,
                    label: 'Grievance Records',
                    color: AppColors.error,
                    completed: 0,
                    total: total,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Borehole listing for reports ───────────────────────────────
            Text(
              'Borehole Summary',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
            const SizedBox(height: 12),
            if (boreholes.isEmpty)
              AppEmptyState(
                icon: Icons.bar_chart_outlined,
                title: 'No Data Yet',
                description: 'Borehole report data will appear here once assignments are made.',
              )
            else
              ...boreholes.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BoreholeDetailScreen(
                          borehole: b,
                          currentUserId: user?.id ?? '',
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.uniqueId,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
                            Text('${b.village}, ${b.district}',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      StatusPill.fromStatus(b.status),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.subtle),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ReportStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label, textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.75), height: 1.3)),
        ],
      ),
    );
  }
}

class _StatusProgressRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusProgressRow({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy)),
            ),
            Text('$count / $total', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _ModuleCompletionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int completed;
  final int total;

  const _ModuleCompletionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : completed / total;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$completed/$total',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
