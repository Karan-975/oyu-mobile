import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/data_models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../surveys/survey_selection_screen.dart';
import 'map_view_screen.dart';

/// Central operational hub for a single borehole — spec §11.5
class BoreholeDetailScreen extends StatefulWidget {
  final Borehole borehole;
  final String currentUserId;

  const BoreholeDetailScreen({
    super.key,
    required this.borehole,
    required this.currentUserId,
  });

  @override
  State<BoreholeDetailScreen> createState() => _BoreholeDetailScreenState();
}

class _BoreholeDetailScreenState extends State<BoreholeDetailScreen> {
  bool _loadingAssignments = true;
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _surveys = [];
  List<Map<String, dynamic>> _rehabilitation = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() { _loadingAssignments = true; _error = null; });
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([
        api.getBoreholeAssignments(widget.borehole.id),
        api.getBoreholeSurveys(widget.borehole.id),
        api.getBoreholeRehabilitation(widget.borehole.id),
      ]);
      if (!mounted) return;
      setState(() {
        _assignments = results[0];
        _surveys = results[1];
        _rehabilitation = results[2];
        _loadingAssignments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loadingAssignments = false; });
    }
  }

  // Determine lifecycle status for each module
  _ModuleStatus _moduleStatus(String slug) {
    if (slug == 'basic_info') {
      final isCompleted = _isModuleCompleted('basic_info');
      return isCompleted ? _ModuleStatus.completed : _ModuleStatus.pending;
    }
    // Check if there's an assignment for this module for the current user
    bool hasAnyAssignment = false;
    bool assignedToMe = false;

    for (final a in _assignments) {
      if (a['status'] != 'active') continue;
      final module = (a['module'] as String?)?.trim() ?? '';
      bool matches = module.isEmpty || _moduleMatchesSlug(module, slug);
      if (!matches) continue;
      hasAnyAssignment = true;
      if (a['assignee_id'] == widget.currentUserId) {
        assignedToMe = true;
        break;
      }
    }

    // Check completion
    final isCompleted = _isModuleCompleted(slug);
    if (isCompleted) return _ModuleStatus.completed;
    if (!hasAnyAssignment) return _ModuleStatus.unassigned;
    if (!assignedToMe) return _ModuleStatus.assignedToOther;
    return _ModuleStatus.pending;
  }

  bool _moduleMatchesSlug(String module, String slug) {
    switch (module) {
      case 'flow_1': case 'flow1': case 'independent':
        return slug == 'lsc_survey' || slug == 'grievance';
      case 'flow_2': case 'flow2': case 'lifecycle':
        return slug == 'borehole_recce' || slug == 'baseline_survey' ||
            slug == 'rehabilitation' || slug == 'monitoring_survey';
      default:
        // Normalize
        final normalized = module == 'lsc' ? 'lsc_survey' :
            module == 'recce' ? 'borehole_recce' :
            module == 'baseline' ? 'baseline_survey' :
            module == 'monitoring' ? 'monitoring_survey' : module;
        return normalized == slug;
    }
  }

  bool _isModuleCompleted(String slug) {
    for (final s in _surveys) {
      final status = (s['status'] ?? s['submission_status'] ?? '').toString().toLowerCase();
      if (status != 'submitted' && status != 'approved') continue;
      final type = (s['survey_type'] ?? s['survey_module_id'] ?? '').toString();
      if (type == slug || type == 'recce' && slug == 'borehole_recce' ||
          type == 'baseline' && slug == 'baseline_survey' ||
          type == 'monitoring' && slug == 'monitoring_survey' ||
          type == 'lsc' && slug == 'lsc_survey') return true;
    }
    if (slug == 'rehabilitation') {
      return _rehabilitation.any((r) {
        final s = (r['status'] ?? '').toString().toLowerCase();
        return s == 'completed' || s == 'approved';
      });
    }
    return false;
  }

  void _openSurveyHub() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurveySelectionScreen(
          borehole: widget.borehole,
          currentUserId: widget.currentUserId,
        ),
      ),
    ).then((_) => _loadDetails());
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapViewScreen(
          boreholes: [widget.borehole],
          focusBorehole: widget.borehole,
        ),
      ),
    );
  }

  Future<void> _openInMaps() async {
    final lat = widget.borehole.latitude;
    final lng = widget.borehole.longitude;
    final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng(${widget.borehole.uniqueId})');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.borehole;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ───────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, const Color(0xFF065F46)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'BH',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b.uniqueId,
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                            _StatusPill(b.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${b.village}, ${b.taluka}, ${b.district}',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                        ),
                        Text(
                          '${b.state}',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.65)),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            _InfoChip(icon: Icons.gps_fixed, label: '${b.latitude.toStringAsFixed(4)}, ${b.longitude.toStringAsFixed(4)}'),
                            const SizedBox(width: 8),
                            _InfoChip(icon: Icons.update_outlined, label: 'Active'),
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
            child: _loadingAssignments
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: AppLoader(),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center,
                                style: GoogleFonts.inter(color: AppColors.error)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _loadDetails,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick Actions
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionButton(
                                    icon: Icons.assignment_outlined,
                                    label: 'Open Survey Hub',
                                    color: AppColors.primary,
                                    onTap: _openSurveyHub,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ActionButton(
                                    icon: Icons.map_outlined,
                                    label: 'View on Map',
                                    color: AppColors.info,
                                    onTap: _openMap,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ActionButton(
                                    icon: Icons.navigation_outlined,
                                    label: 'Navigate',
                                    color: AppColors.warning,
                                    onTap: _openInMaps,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Lifecycle Progress ─────────────────────────────────
                            _SectionTitle('Borehole Lifecycle'),
                            const SizedBox(height: 12),
                            AppCard(
                              child: Column(
                                children: [
                                  _LifecycleRow(
                                    step: 1,
                                    slug: 'basic_info',
                                    label: 'Basic Info Verification',
                                    icon: Icons.verified_user_outlined,
                                    color: Colors.blueGrey.shade800,
                                    status: _moduleStatus('basic_info'),
                                    onTap: _openSurveyHub,
                                    isFirst: true,
                                  ),
                                  _LifecycleDivider(),
                                  _LifecycleRow(
                                    step: 2,
                                    slug: 'borehole_recce',
                                    label: 'Borehole Recce',
                                    icon: Icons.travel_explore,
                                    color: AppColors.primary,
                                    status: _moduleStatus('borehole_recce'),
                                    onTap: _openSurveyHub,
                                  ),
                                  _LifecycleDivider(),
                                  _LifecycleRow(
                                    step: 3,
                                    slug: 'baseline_survey',
                                    label: 'Baseline Survey',
                                    icon: Icons.fact_check_outlined,
                                    color: AppColors.info,
                                    status: _moduleStatus('baseline_survey'),
                                    onTap: _openSurveyHub,
                                  ),
                                  _LifecycleDivider(),
                                  _LifecycleRow(
                                    step: 4,
                                    slug: 'lsc_survey',
                                    label: 'LSC Consultation',
                                    icon: Icons.groups_2_outlined,
                                    color: AppColors.warning,
                                    status: _moduleStatus('lsc_survey'),
                                    onTap: _openSurveyHub,
                                    isIndependent: true,
                                  ),
                                  _LifecycleDivider(),
                                  _LifecycleRow(
                                    step: 5,
                                    slug: 'rehabilitation',
                                    label: 'Rehabilitation',
                                    icon: Icons.handyman_outlined,
                                    color: const Color(0xFF7C3AED),
                                    status: _moduleStatus('rehabilitation'),
                                    onTap: _openSurveyHub,
                                  ),
                                  _LifecycleDivider(),
                                  _LifecycleRow(
                                    step: 6,
                                    slug: 'monitoring_survey',
                                    label: 'Monitoring Survey',
                                    icon: Icons.monitor_heart_outlined,
                                    color: AppColors.success,
                                    status: _moduleStatus('monitoring_survey'),
                                    onTap: _openSurveyHub,
                                  ),
                                  _LifecycleDivider(),
                                  _LifecycleRow(
                                    step: 7,
                                    slug: 'grievance',
                                    label: 'Grievance Report',
                                    icon: Icons.report_problem_outlined,
                                    color: AppColors.error,
                                    status: _moduleStatus('grievance'),
                                    onTap: _openSurveyHub,
                                    isIndependent: true,
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Borehole Information ─────────────────────────────
                            _SectionTitle('Borehole Information'),
                            const SizedBox(height: 12),
                            AppCard(
                              child: Column(
                                children: [
                                  _InfoRow(label: 'Borehole ID', value: b.uniqueId),
                                  _InfoRow(label: 'Village', value: b.village),
                                  _InfoRow(label: 'Taluka', value: b.taluka.isEmpty ? '—' : b.taluka),
                                  _InfoRow(label: 'District', value: b.district),
                                  _InfoRow(label: 'State', value: b.state),
                                  _InfoRow(label: 'GPS', value: '${b.latitude.toStringAsFixed(6)}, ${b.longitude.toStringAsFixed(6)}'),
                                  if (b.waterTableDepth != null)
                                    _InfoRow(label: 'Water Table', value: '${b.waterTableDepth}m'),
                                  if (b.formationType != null)
                                    _InfoRow(label: 'Formation', value: b.formationType!),
                                  _InfoRow(
                                    label: 'Status',
                                    value: b.status,
                                    isStatus: true,
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── GPS / Map Mini ──────────────────────────────────
                            _SectionTitle('GPS & Location'),
                            const SizedBox(height: 12),
                            AppCard(
                              onTap: _openMap,
                              child: Column(
                                children: [
                                  // Simple map placeholder
                                  Container(
                                    height: 140,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(
                                        colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.info.withValues(alpha: 0.06)],
                                      ),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(Icons.map_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.15)),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12)],
                                              ),
                                              child: const Icon(Icons.location_pin, color: Colors.white, size: 20),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${b.latitude.toStringAsFixed(5)}, ${b.longitude.toStringAsFixed(5)}',
                                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Open Map →',
                                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.gps_fixed, size: 14, color: AppColors.success),
                                      const SizedBox(width: 6),
                                      Text(
                                        'GPS Accuracy: High  •  ${b.latitude.toStringAsFixed(4)}°N, ${b.longitude.toStringAsFixed(4)}°E',
                                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Activity Timeline ───────────────────────────────
                            _SectionTitle('Activity Timeline'),
                            const SizedBox(height: 12),
                            AppCard(
                              child: Column(
                                children: [
                                  if (_surveys.isEmpty && _rehabilitation.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Text(
                                        'No activity recorded yet. Submit a survey to begin.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                                      ),
                                    )
                                  else
                                    ..._buildActivityItems(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomActionBar(onOpenSurveys: _openSurveyHub),
    );
  }

  List<Widget> _buildActivityItems() {
    final items = <_ActivityItem>[];
    for (final s in _surveys) {
      items.add(_ActivityItem(
        type: (s['survey_type'] ?? 'Survey').toString(),
        time: (s['created_at'] ?? s['submitted_at'] ?? '').toString(),
        status: (s['status'] ?? '').toString(),
      ));
    }
    for (final r in _rehabilitation) {
      items.add(_ActivityItem(
        type: 'Rehabilitation',
        time: (r['created_at'] ?? '').toString(),
        status: (r['status'] ?? '').toString(),
      ));
    }
    items.sort((a, b) => b.time.compareTo(a.time));
    return items.take(5).map((item) => _ActivityRowWidget(item: item)).toList();
  }
}

// ── Data Classes ──────────────────────────────────────────────────────────────

enum _ModuleStatus { pending, completed, unassigned, assignedToOther }

class _ActivityItem {
  final String type;
  final String time;
  final String status;
  _ActivityItem({required this.type, required this.time, required this.status});
}

// ── Widget Helpers ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (status.toLowerCase()) {
      case 'active': case 'functional': color = AppColors.success; bg = AppColors.successBg; break;
      case 'inactive': case 'non_functional': color = AppColors.error; bg = AppColors.errorBg; break;
      case 'under_rehabilitation': color = AppColors.warning; bg = AppColors.warningBg; break;
      default: color = AppColors.info; bg = AppColors.infoBg;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _LifecycleRow extends StatelessWidget {
  final int step;
  final String slug;
  final String label;
  final IconData icon;
  final Color color;
  final _ModuleStatus status;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final bool isIndependent;

  const _LifecycleRow({
    required this.step,
    required this.slug,
    required this.label,
    required this.icon,
    required this.color,
    required this.status,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.isIndependent = false,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    bool clickable;

    switch (status) {
      case _ModuleStatus.completed:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusLabel = 'Completed';
        clickable = false;
        break;
      case _ModuleStatus.pending:
        statusColor = color;
        statusIcon = Icons.play_circle_outline;
        statusLabel = 'Assigned to me';
        clickable = true;
        break;
      case _ModuleStatus.unassigned:
        statusColor = AppColors.subtle;
        statusIcon = Icons.radio_button_unchecked;
        statusLabel = 'Not assigned';
        clickable = false;
        break;
      case _ModuleStatus.assignedToOther:
        statusColor = AppColors.muted;
        statusIcon = Icons.person_outline;
        statusLabel = 'Assigned to other';
        clickable = false;
        break;
    }

    return InkWell(
      onTap: clickable ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            // Step indicator
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: status == _ModuleStatus.completed
                    ? AppColors.success.withValues(alpha: 0.1)
                    : status == _ModuleStatus.pending
                        ? color.withValues(alpha: 0.1)
                        : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: status == _ModuleStatus.completed
                      ? AppColors.success.withValues(alpha: 0.3)
                      : status == _ModuleStatus.pending
                          ? color.withValues(alpha: 0.3)
                          : AppColors.border,
                ),
              ),
              child: Icon(icon, size: 18,
                color: status == _ModuleStatus.pending || status == _ModuleStatus.completed
                    ? (status == _ModuleStatus.completed ? AppColors.success : color)
                    : AppColors.subtle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: status == _ModuleStatus.unassigned ? AppColors.subtle : AppColors.navy,
                        ),
                      ),
                      if (isIndependent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Independent',
                            style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w600, color: AppColors.warning),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    statusLabel,
                    style: GoogleFonts.inter(fontSize: 11, color: statusColor),
                  ),
                ],
              ),
            ),
            Icon(statusIcon, color: statusColor, size: 18),
            if (clickable) const SizedBox(width: 4),
            if (clickable)
              const Icon(Icons.chevron_right, size: 14, color: AppColors.subtle),
          ],
        ),
      ),
    );
  }
}

class _LifecycleDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 52);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isStatus;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isStatus = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: isStatus
                    ? StatusPill.fromStatus(value)
                    : Text(
                        value,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
                      ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

class _ActivityRowWidget extends StatelessWidget {
  final _ActivityItem item;
  const _ActivityRowWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.type.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy),
                ),
                Text(
                  item.time.isNotEmpty ? item.time.substring(0, item.time.length > 10 ? 10 : item.time.length) : '—',
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          StatusPill.fromStatus(item.status),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onOpenSurveys;
  const _BottomActionBar({required this.onOpenSurveys});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ElevatedButton.icon(
        onPressed: onOpenSurveys,
        icon: const Icon(Icons.assignment_outlined),
        label: const Text('Open Survey Hub'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
