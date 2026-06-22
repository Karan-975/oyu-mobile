import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'survey_selection_screen.dart';

class SurveysHubScreen extends StatefulWidget {
  const SurveysHubScreen({super.key});

  @override
  State<SurveysHubScreen> createState() => _SurveysHubScreenState();
}

class _SurveysHubScreenState extends State<SurveysHubScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final currentUserId = user?.id ?? '';

    final boreholes = data.boreholes.where((b) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return b.uniqueId.toLowerCase().contains(q) ||
          b.village.toLowerCase().contains(q) ||
          b.district.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Borehole Surveys'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: data.loadBoreholes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search borehole to start survey...',
                prefixIcon: const Icon(Icons.search, size: 19),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Header count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Choose a borehole to fill its surveys',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  '${boreholes.length} assigned',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          Expanded(
            child: data.isLoading && data.boreholes.isEmpty
                ? const AppLoader()
                : boreholes.isEmpty
                    ? AppEmptyState(
                        icon: Icons.assignment_outlined,
                        title: _search.isNotEmpty ? 'No Matching Boreholes' : 'No Survey Assignments',
                        description: _search.isNotEmpty
                            ? 'No boreholes match your search criteria.'
                            : 'Boreholes with active survey assignments will show up here.',
                        actionLabel: 'Refresh',
                        onAction: data.loadBoreholes,
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: data.loadBoreholes,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: boreholes.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final borehole = boreholes[i];
                            return AppCard(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SurveySelectionScreen(
                                    borehole: borehole,
                                    currentUserId: currentUserId,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              borehole.uniqueId,
                                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
                                            ),
                                            const SizedBox(width: 8),
                                            StatusPill.fromStatus(borehole.status),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${borehole.village}, ${borehole.district}',
                                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.subtle),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
