import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/data_models.dart';
import '../../services/api_service.dart';
import 'dynamic_survey_form_screen.dart';
import 'rehabilitation_agreement_screen.dart';

class RecceSurveyScreen extends StatelessWidget {
  final Borehole borehole;

  const RecceSurveyScreen({super.key, required this.borehole});

  @override
  Widget build(BuildContext context) {
    return _SurveyStartScreen(
      borehole: borehole,
      surveyCode: 'recce',
      title: 'Recce Survey',
      subtitle: 'First field visit and borehole identification',
      color: const Color(0xFF0D9488),
      icon: Icons.travel_explore,
      sections: const [
        'Confirm borehole identity and location',
        'Record current functionality status',
        'Capture water access and usage observations',
        'Attach GPS before final submission',
      ],
    );
  }
}

class BaselineSurveyScreen extends StatelessWidget {
  final Borehole borehole;

  const BaselineSurveyScreen({super.key, required this.borehole});

  @override
  Widget build(BuildContext context) {
    return _SurveyStartScreen(
      borehole: borehole,
      surveyCode: 'baseline_survey',
      title: 'Baseline Survey',
      subtitle: 'Household and community baseline data',
      color: const Color(0xFF2563EB),
      icon: Icons.fact_check_outlined,
      sections: const [
        'Collect household survey responses',
        'Record community representative details',
        'Capture consent and signature fields where configured',
        'Review all answers before submitting',
      ],
    );
  }
}

class LscSurveyScreen extends StatelessWidget {
  final Borehole borehole;

  const LscSurveyScreen({super.key, required this.borehole});

  @override
  Widget build(BuildContext context) {
    return _SurveyStartScreen(
      borehole: borehole,
      surveyCode: 'lsc',
      title: 'LSC Consultation',
      subtitle: 'Stakeholder consultation and community feedback',
      color: const Color(0xFFD97706),
      icon: Icons.groups_2_outlined,
      sections: const [
        'Record meeting and stakeholder details',
        'Capture feedback from the community',
        'Note concerns, support, and next steps',
        'Submit consultation record for review',
      ],
    );
  }
}

class MonitoringSurveyScreen extends StatelessWidget {
  final Borehole borehole;

  const MonitoringSurveyScreen({super.key, required this.borehole});

  @override
  Widget build(BuildContext context) {
    return _SurveyStartScreen(
      borehole: borehole,
      surveyCode: 'monitoring_survey',
      title: 'Monitoring Survey',
      subtitle: 'Post-rehabilitation condition and impact tracking',
      color: const Color(0xFF16A34A),
      icon: Icons.monitor_heart_outlined,
      sections: const [
        'Check current borehole status',
        'Record water access improvements',
        'Capture cost, fuel, health, and social impact data',
        'Submit monitoring evidence for review',
      ],
    );
  }
}

class GrievanceSurveyScreen extends StatelessWidget {
  final Borehole borehole;

  const GrievanceSurveyScreen({super.key, required this.borehole});

  @override
  Widget build(BuildContext context) {
    return _SurveyStartScreen(
      borehole: borehole,
      surveyCode: 'grievance',
      title: 'Grievance Report',
      subtitle: 'Report a field issue with context and evidence',
      color: const Color(0xFFDC2626),
      icon: Icons.report_problem_outlined,
      sections: const [
        'Describe the issue clearly',
        'Add reporter and borehole context',
        'Capture photos or GPS fields if configured',
        'Submit so the admin team can review and resolve',
      ],
    );
  }
}

class NgoRehabilitationScreen extends StatelessWidget {
  final Borehole borehole;

  const NgoRehabilitationScreen({super.key, required this.borehole});

  @override
  Widget build(BuildContext context) {
    return _SurveyStartScreen(
      borehole: borehole,
      surveyCode: 'rehabilitation',
      title: 'Rehabilitation Report',
      subtitle: 'NGO member field repair, testing, handover, and evidence',
      color: const Color(0xFF7C3AED),
      icon: Icons.handyman_outlined,
      sections: const [
        'Record borehole and field worker details',
        'Capture pre-rehabilitation defects and photos',
        'Document repair activities and replaced parts',
        'Submit post-rehabilitation testing and handover evidence',
      ],
    );
  }
}

class _SurveyStartScreen extends StatelessWidget {
  final Borehole borehole;
  final String surveyCode;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<String> sections;

  const _SurveyStartScreen({
    required this.borehole,
    required this.surveyCode,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: color,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  subtitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Borehole ${borehole.uniqueId} - ${borehole.village}, ${borehole.district}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _InfoPanel(
                  title: 'Before you start',
                  child: Column(
                    children: [
                      for (final section in sections)
                        _ChecklistRow(label: section, color: color),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _InfoPanel(
                  title: 'Borehole details',
                  child: Column(
                    children: [
                      _DetailRow(label: 'Code', value: borehole.uniqueId),
                      _DetailRow(label: 'Village', value: borehole.village),
                      _DetailRow(label: 'District', value: borehole.district),
                      _DetailRow(
                        label: 'Coordinates',
                        value:
                            '${borehole.latitude.toStringAsFixed(5)}, ${borehole.longitude.toStringAsFixed(5)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (surveyCode == 'rehabilitation') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RehabilitationAgreementScreen(
                          borehole: borehole,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DynamicSurveyFormScreen(
                          borehole: borehole,
                          surveyCode: surveyCode,
                          surveyName: title,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text(
                  'Continue to Form',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String label;
  final Color color;

  const _ChecklistRow({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                height: 1.3,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not available' : value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BasicInfoVerificationScreen extends StatefulWidget {
  final Borehole borehole;
  const BasicInfoVerificationScreen({super.key, required this.borehole});

  @override
  State<BasicInfoVerificationScreen> createState() => _BasicInfoVerificationScreenState();
}

class _BasicInfoVerificationScreenState extends State<BasicInfoVerificationScreen> {
  bool _confirmed = false;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check the confirmation box to proceed.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final api = context.read<ApiService>();
      final submission = SurveySubmission(
        boreholId: widget.borehole.id,
        surveyModuleId: 'basic_info',
        formData: {
          'confirmed': true,
          'comments': _commentCtrl.text.trim(),
          'timestamp': DateTime.now().toIso8601String(),
        },
        status: 'submitted',
      );
      final result = await api.submitSurvey(submission);
      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Basic Information Verified!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit verification.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.borehole;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Basic Information Verification'),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Verify Borehole Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You must confirm the technical and geographic coordinates are correct before conducting any surveys.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),
                _InfoPanel(
                  title: 'Technical Details',
                  child: Column(
                    children: [
                      _DetailRow(label: 'Borehole ID', value: b.uniqueId),
                      _DetailRow(label: 'Village', value: b.village),
                      _DetailRow(label: 'Taluka / District', value: '${b.taluka} / ${b.district}'),
                      _DetailRow(label: 'Province / State', value: b.state),
                      _DetailRow(label: 'Latitude', value: b.latitude.toString()),
                      _DetailRow(label: 'Longitude', value: b.longitude.toString()),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Observations / Comments',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _commentCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter any comments about GPS correctness or village location...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  value: _confirmed,
                  onChanged: (v) => setState(() => _confirmed = v ?? false),
                  title: const Text(
                    'I confirm that the technical and geographic coordinates above are correct.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: _submitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm & Verify', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
