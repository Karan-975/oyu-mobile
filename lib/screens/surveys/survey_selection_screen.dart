import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/data_models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../water_testing/water_testing_screen.dart';
import 'survey_start_screens.dart';

enum _SurveyStatus {
  active,
  completed,
  locked,
  assignedToOther,
  notAssigned,
}

class _SurveyStatusInfo {
  final _SurveyStatus status;
  final String label;
  final String subtitle;
  final bool isClickable;

  const _SurveyStatusInfo({
    required this.status,
    required this.label,
    required this.subtitle,
    required this.isClickable,
  });
}

class SurveySelectionScreen extends StatefulWidget {
  final Borehole borehole;
  final String currentUserId;

  const SurveySelectionScreen({
    super.key,
    required this.borehole,
    required this.currentUserId,
  });

  @override
  State<SurveySelectionScreen> createState() => _SurveySelectionScreenState();
}

class _SurveySelectionScreenState extends State<SurveySelectionScreen> {
  bool _loadingAssignments = true;
  String? _assignmentError;
  List<dynamic> _assignmentsList = [];
  final Set<String> _completedModules = {};

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([
        api.getBoreholeAssignments(widget.borehole.id),
        api.getBoreholeSurveys(widget.borehole.id),
        api.getBoreholeRehabilitation(widget.borehole.id),
      ]);
      final assignments = results[0];
      final surveys = results[1];
      final rehabilitation = results[2];

      final completedModules = _completedFromRecords(surveys, rehabilitation);

      if (!mounted) return;
      setState(() {
        _assignmentsList = assignments;
        _completedModules
          ..clear()
          ..addAll(completedModules);
        _loadingAssignments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _assignmentError = e.toString();
        _loadingAssignments = false;
      });
    }
  }

  List<_SurveyMenuItem> _allSurveys() => [
        _SurveyMenuItem(
          moduleSlug: 'basic_info',
          name: 'Basic Info Verification',
          description: 'Verify and confirm technical and coordinate data.',
          icon: Icons.verified_user_outlined,
          color: Colors.blueGrey.shade800,
          builder: (_) => BasicInfoVerificationScreen(borehole: widget.borehole),
        ),
        _SurveyMenuItem(
          moduleSlug: 'borehole_recce',
          name: 'Borehole Recce',
          description: 'Identification, current status, and field evidence.',
          icon: Icons.travel_explore,
          color: AppColors.primary,
          builder: (_) => RecceSurveyScreen(borehole: widget.borehole),
        ),
        _SurveyMenuItem(
          moduleSlug: 'baseline_survey',
          name: 'Baseline Survey',
          description: 'Household and community baseline information.',
          icon: Icons.fact_check_outlined,
          color: AppColors.info,
          builder: (_) => BaselineSurveyScreen(borehole: widget.borehole),
        ),
        _SurveyMenuItem(
          moduleSlug: 'lsc_survey',
          name: 'LSC Consultation',
          description: 'Stakeholder consultation and community feedback.',
          icon: Icons.groups_2_outlined,
          color: AppColors.warning,
          builder: (_) => LscSurveyScreen(borehole: widget.borehole),
        ),
        _SurveyMenuItem(
          moduleSlug: 'monitoring_survey',
          name: 'Monitoring Survey',
          description: 'Impact, functionality, and condition tracking.',
          icon: Icons.monitor_heart_outlined,
          color: AppColors.success,
          builder: (_) => MonitoringSurveyScreen(borehole: widget.borehole),
        ),
        _SurveyMenuItem(
          moduleSlug: 'rehabilitation',
          name: 'Rehabilitation Report',
          description: 'Repair, testing, handover, and evidence.',
          icon: Icons.handyman_outlined,
          color: Colors.deepPurple,
          builder: (_) => NgoRehabilitationScreen(borehole: widget.borehole),
        ),
        _SurveyMenuItem(
          moduleSlug: 'grievance',
          name: 'Grievance Report',
          description: 'Submit issues with context, GPS, and evidence.',
          icon: Icons.report_problem_outlined,
          color: AppColors.error,
          builder: (_) => GrievanceSurveyScreen(borehole: widget.borehole),
        ),
        _SurveyMenuItem(
          moduleSlug: 'water_testing',
          name: 'Water Quality Testing',
          description: 'Register water samples, vials, and track tests.',
          icon: Icons.biotech_outlined,
          color: Colors.blue,
          builder: (_) => WaterTestingScreen(borehole: widget.borehole),
        ),
      ];

  Set<String> _expandAssignedModule(String module) {
    final normalized = _normalizeModule(module);
    if (normalized == 'flow_1') {
      return {'lsc_survey', 'grievance', 'water_testing'};
    }
    if (normalized == 'flow_2') {
      return {
        'basic_info',
        'borehole_recce',
        'baseline_survey',
        'rehabilitation',
        'monitoring_survey',
      };
    }
    return normalized.isEmpty ? <String>{} : {normalized};
  }

  String _normalizeModule(String module) {
    switch (module) {
      case 'flow1':
      case 'flow_1':
      case 'independent':
        return 'flow_1';
      case 'flow2':
      case 'flow_2':
      case 'lifecycle':
        return 'flow_2';
      case 'recce':
        return 'borehole_recce';
      case 'lsc':
        return 'lsc_survey';
      case 'baseline':
        return 'baseline_survey';
      case 'monitoring':
        return 'monitoring_survey';
      default:
        return module;
    }
  }

  Set<String> _completedFromRecords(
    List<Map<String, dynamic>> surveys,
    List<Map<String, dynamic>> rehabilitation,
  ) {
    final completed = <String>{};
    for (final survey in surveys) {
      final status = (survey['status'] ?? survey['submission_status'] ?? '')
          .toString()
          .toLowerCase();
      if (status != 'submitted' && status != 'approved') continue;

      final type = (survey['survey_type'] ?? survey['survey_module_id'] ?? '').toString().toLowerCase();
      if (type == 'basic_info') {
        completed.add('basic_info');
      } else if (type == 'recce' || type == 'borehole_recce') {
        completed.add('borehole_recce');
      } else if (type == 'baseline' || type == 'baseline_survey') {
        completed.add('baseline_survey');
      } else if (type == 'monitoring' || type == 'monitoring_survey') {
        completed.add('monitoring_survey');
      } else if (type == 'lsc' || type == 'lsc_survey') {
        completed.add('lsc_survey');
      }
    }

    final rehabDone = rehabilitation.any((record) {
      final status = (record['status'] ?? '').toString().toLowerCase();
      return status == 'completed' || status == 'approved';
    });
    if (rehabDone) completed.add('rehabilitation');

    return completed;
  }

  int? _extractSequenceNum(String uniqueId) {
    final regExp = RegExp(r'\d{4}');
    final match = regExp.firstMatch(uniqueId);
    if (match != null) {
      return int.tryParse(match.group(0)!);
    }
    final digitRegExp = RegExp(r'\d+');
    final digitMatch = digitRegExp.firstMatch(uniqueId);
    if (digitMatch != null) {
      return int.tryParse(digitMatch.group(0)!);
    }
    return null;
  }

  bool _isBaselineNeeded(String uniqueId) {
    final seq = _extractSequenceNum(uniqueId);
    if (seq == null) return false;
    return seq % 8 == 0;
  }

  bool _isFlowTwoLocked(String moduleSlug) {
    if (!_completedModules.contains('basic_info')) {
      return true;
    }
    switch (moduleSlug) {
      case 'borehole_recce':
        return false;
      case 'baseline_survey':
        if (!_completedModules.contains('borehole_recce')) return true;
        return !_isBaselineNeeded(widget.borehole.uniqueId);
      case 'rehabilitation':
        if (!_completedModules.contains('borehole_recce')) return true;
        if (_isBaselineNeeded(widget.borehole.uniqueId) && !_completedModules.contains('baseline_survey')) {
          return true;
        }
        return false;
      case 'monitoring_survey':
        return !_completedModules.contains('rehabilitation');
      default:
        return false;
    }
  }

  String _flowTwoLockReason(String moduleSlug) {
    if (!_completedModules.contains('basic_info')) {
      return 'Locked until Basic Info is verified.';
    }
    switch (moduleSlug) {
      case 'baseline_survey':
        if (!_completedModules.contains('borehole_recce')) {
          return 'Locked until Recce is completed.';
        }
        if (!_isBaselineNeeded(widget.borehole.uniqueId)) {
          return 'Baseline Survey not required for this borehole.';
        }
        return 'Locked.';
      case 'rehabilitation':
        if (!_completedModules.contains('borehole_recce')) {
          return 'Locked until Recce is completed.';
        }
        if (_isBaselineNeeded(widget.borehole.uniqueId) && !_completedModules.contains('baseline_survey')) {
          return 'Locked until Baseline Survey is completed.';
        }
        return 'Locked.';
      case 'monitoring_survey':
        return 'Locked until Rehabilitation is completed.';
      default:
        return 'This step is locked.';
    }
  }

  _SurveyStatusInfo _getSurveyStatusInfo(String moduleSlug) {
    final isCompleted = _completedModules.contains(moduleSlug);

    if (moduleSlug == 'basic_info') {
      if (isCompleted) {
        return const _SurveyStatusInfo(
          status: _SurveyStatus.completed,
          label: 'Completed',
          subtitle: 'Basic Information verified.',
          isClickable: false,
        );
      }
      return const _SurveyStatusInfo(
        status: _SurveyStatus.active,
        label: 'Required',
        subtitle: 'Tap to verify borehole metadata.',
        isClickable: true,
      );
    }

    if (moduleSlug == 'water_testing') {
      return const _SurveyStatusInfo(
        status: _SurveyStatus.active,
        label: 'Available',
        subtitle: 'Tap to log/view water quality tests.',
        isClickable: true,
      );
    }

    // Find active user assignment for this module
    Map<String, dynamic>? activeAssignment;
    for (final a in _assignmentsList) {
      if (a['assignee_type'] == 'user' && a['status'] == 'active') {
        final assignedModule = (a['module'] as String?)?.trim() ?? '';
        
        bool matches = false;
        if (assignedModule.isEmpty) {
          matches = true;
        } else {
          final expanded = _expandAssignedModule(assignedModule);
          if (expanded.contains(moduleSlug) || assignedModule == moduleSlug) {
            matches = true;
          }
        }

        if (matches) {
          if (a['assignee_id'] == widget.currentUserId) {
            activeAssignment = a;
            break;
          } else {
            activeAssignment ??= a;
          }
        }
      }
    }

    final hasAssignment = activeAssignment != null;
    final isAssignedToMe = hasAssignment && activeAssignment['assignee_id'] == widget.currentUserId;
    final assigneeName = hasAssignment ? (activeAssignment['assignee_name'] ?? 'Other Member') : null;

    if (isCompleted) {
      return _SurveyStatusInfo(
        status: _SurveyStatus.completed,
        label: 'Completed',
        subtitle: hasAssignment 
            ? 'Completed (Assigned to $assigneeName)'
            : 'Completed',
        isClickable: false,
      );
    }

    if (!hasAssignment) {
      return const _SurveyStatusInfo(
        status: _SurveyStatus.notAssigned,
        label: 'Unassigned',
        subtitle: 'Not assigned to any team member yet.',
        isClickable: false,
      );
    }

    if (!isAssignedToMe) {
      return _SurveyStatusInfo(
        status: _SurveyStatus.assignedToOther,
        label: 'Assigned to Other',
        subtitle: 'Assigned to $assigneeName.',
        isClickable: false,
      );
    }

    // It is active and assigned to me! But check sequential locks (only Flow 2)
    final isSequential = moduleSlug == 'borehole_recce' ||
        moduleSlug == 'baseline_survey' ||
        moduleSlug == 'rehabilitation' ||
        moduleSlug == 'monitoring_survey';

    if (isSequential) {
      final isLocked = _isFlowTwoLocked(moduleSlug);
      if (isLocked) {
        return _SurveyStatusInfo(
          status: _SurveyStatus.locked,
          label: 'Locked',
          subtitle: _flowTwoLockReason(moduleSlug),
          isClickable: false,
        );
      }
    }

    return const _SurveyStatusInfo(
      status: _SurveyStatus.active,
      label: 'Assigned to you',
      subtitle: 'Tap to start survey.',
      isClickable: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final flowOne = _allSurveys()
        .where((survey) =>
            survey.moduleSlug == 'lsc_survey' ||
            survey.moduleSlug == 'grievance' ||
            survey.moduleSlug == 'water_testing')
        .toList();

    final flowTwo = _allSurveys()
        .where((survey) =>
            survey.moduleSlug == 'basic_info' ||
            survey.moduleSlug == 'borehole_recce' ||
            survey.moduleSlug == 'baseline_survey' ||
            survey.moduleSlug == 'rehabilitation' ||
            survey.moduleSlug == 'monitoring_survey')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Survey Hub'),
        centerTitle: false,
      ),
      body: _loadingAssignments
          ? const AppLoader()
          : _assignmentError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load survey assignments.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _assignmentError!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _loadAssignments,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // Borehole header card
                    AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Borehole #${widget.borehole.uniqueId}',
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${widget.borehole.village}, ${widget.borehole.district}',
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          StatusPill.fromStatus(widget.borehole.status),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Flow 1
                    _FlowSection(
                      title: 'Flow 1 - Independent Actions',
                      subtitle: 'LSC Consultation & Grievances (can be done anytime)',
                      color: AppColors.flow1,
                      items: flowOne,
                      getStatusInfo: _getSurveyStatusInfo,
                    ),

                    const SizedBox(height: 16),

                    // Flow 2
                    _FlowSection(
                      title: 'Flow 2 - Sequential Lifecycle',
                      subtitle: 'Sequence: Recce → Baseline → Rehabilitation → Monitoring',
                      color: AppColors.flow2,
                      items: flowTwo,
                      getStatusInfo: _getSurveyStatusInfo,
                      isSequential: true,
                    ),
                  ],
                ),
    );
  }
}

class _FlowSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final List<_SurveyMenuItem> items;
  final _SurveyStatusInfo Function(String) getStatusInfo;
  final bool isSequential;

  const _FlowSection({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.items,
    required this.getStatusInfo,
    this.isSequential = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            final statusInfo = getStatusInfo(item.moduleSlug);

            return _SurveyCard(
              item: item,
              stepNumber: isSequential ? index + 1 : null,
              statusInfo: statusInfo,
            );
          },
        ),
      ],
    );
  }
}

class _SurveyCard extends StatelessWidget {
  final _SurveyMenuItem item;
  final int? stepNumber;
  final _SurveyStatusInfo statusInfo;

  const _SurveyCard({
    required this.item,
    this.stepNumber,
    required this.statusInfo,
  });

  @override
  Widget build(BuildContext context) {
    // Choose styling based on status
    Color cardBg;
    Color iconBg;
    Color iconColor;
    Widget trailingIcon;
    Color nameColor;
    Color descColor;

    switch (statusInfo.status) {
      case _SurveyStatus.completed:
        cardBg = AppColors.successBg.withValues(alpha: 0.15);
        iconBg = AppColors.success.withValues(alpha: 0.1);
        iconColor = AppColors.success;
        trailingIcon = const Icon(Icons.check_circle, color: AppColors.success, size: 20);
        nameColor = AppColors.navy;
        descColor = AppColors.muted;
        break;
      case _SurveyStatus.active:
        cardBg = AppColors.surface;
        iconBg = item.color.withValues(alpha: 0.1);
        iconColor = item.color;
        trailingIcon = Icon(Icons.chevron_right, color: item.color, size: 20);
        nameColor = AppColors.navy;
        descColor = AppColors.muted;
        break;
      case _SurveyStatus.locked:
        cardBg = AppColors.background;
        iconBg = AppColors.subtle.withValues(alpha: 0.1);
        iconColor = AppColors.subtle;
        trailingIcon = const Icon(Icons.lock_outline, color: AppColors.subtle, size: 20);
        nameColor = AppColors.muted;
        descColor = AppColors.subtle;
        break;
      case _SurveyStatus.assignedToOther:
        cardBg = AppColors.background.withValues(alpha: 0.5);
        iconBg = AppColors.subtle.withValues(alpha: 0.1);
        iconColor = AppColors.subtle;
        trailingIcon = const Icon(Icons.person_outline, color: AppColors.subtle, size: 20);
        nameColor = AppColors.muted;
        descColor = AppColors.subtle;
        break;
      case _SurveyStatus.notAssigned:
        cardBg = AppColors.background.withValues(alpha: 0.3);
        iconBg = AppColors.subtle.withValues(alpha: 0.05);
        iconColor = AppColors.subtle;
        trailingIcon = const Icon(Icons.do_not_disturb_on_total_silence_outlined, color: AppColors.subtle, size: 20);
        nameColor = AppColors.subtle;
        descColor = AppColors.subtle;
        break;
    }

    return AppCard(
      onTap: statusInfo.isClickable
          ? () {
              debugPrint('TAPPED SURVEY CARD: ${item.name} (${item.moduleSlug})');
              Navigator.push(
                context,
                MaterialPageRoute(builder: item.builder),
              );
            }
          : null,
      color: cardBg,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: stepNumber != null
                ? Center(
                    child: Text(
                      '$stepNumber',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: iconColor,
                      ),
                    ),
                  )
                : Icon(
                    item.icon,
                    color: iconColor,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: nameColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (statusInfo.status == _SurveyStatus.completed)
                      const StatusPill(
                        label: 'Submitted',
                        color: AppColors.success,
                        bgColor: AppColors.successBg,
                        fontSize: 9,
                      )
                    else if (statusInfo.status == _SurveyStatus.active)
                      const StatusPill(
                        label: 'Active',
                        color: AppColors.primary,
                        bgColor: Color(0xFFE0F2FE),
                        fontSize: 9,
                      )
                    else if (statusInfo.status == _SurveyStatus.assignedToOther)
                      const StatusPill(
                        label: 'Other Member',
                        color: AppColors.muted,
                        bgColor: Color(0xFFF1F5F9),
                        fontSize: 9,
                      )
                    else if (statusInfo.status == _SurveyStatus.notAssigned)
                      const StatusPill(
                        label: 'Unassigned',
                        color: AppColors.subtle,
                        bgColor: Color(0xFFF8FAFC),
                        fontSize: 9,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statusInfo.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: descColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailingIcon,
        ],
      ),
    );
  }
}

class _SurveyMenuItem {
  final String moduleSlug;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  const _SurveyMenuItem({
    required this.moduleSlug,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.builder,
  });
}
