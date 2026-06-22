import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/data_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'borehole_detail_screen.dart';
import 'map_view_screen.dart';

class BoreholesListScreen extends StatefulWidget {
  const BoreholesListScreen({super.key});

  @override
  State<BoreholesListScreen> createState() => _BoreholesListScreenState();
}

class _BoreholesListScreenState extends State<BoreholesListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
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
        title: const Text('My Boreholes'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Map View',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MapViewScreen(boreholes: data.boreholes),
                ),
              );
            },
          ),
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
                hintText: 'Search by code, village, district...',
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

          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${boreholes.length} borehole${boreholes.length == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          Expanded(
            child: data.isLoading && data.boreholes.isEmpty
                ? const AppLoader()
                : boreholes.isEmpty
                    ? AppEmptyState(
                        icon: Icons.water_drop_outlined,
                        title: _search.isNotEmpty ? 'No Results' : 'No Boreholes Assigned',
                        description: _search.isNotEmpty
                            ? 'Try a different search term.'
                            : 'Boreholes assigned to you will appear here.',
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
                          itemBuilder: (context, i) => _BoreholeCard(borehole: boreholes[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _BoreholeCard extends StatelessWidget {
  final Borehole borehole;

  const _BoreholeCard({required this.borehole});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id ?? '';
    return AppCard(
      onTap: () {
        debugPrint('TAPPED BOREHOLE: ${borehole.uniqueId}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BoreholeDetailScreen(
              borehole: borehole,
              currentUserId: currentUserId,
            ),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 22),
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
                    const Spacer(),
                    StatusPill.fromStatus(borehole.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${borehole.village}, ${borehole.district}',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.gps_fixed, size: 12, color: AppColors.subtle),
                    const SizedBox(width: 4),
                    Text(
                      '${borehole.latitude.toStringAsFixed(4)}, ${borehole.longitude.toStringAsFixed(4)}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.subtle),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.subtle),
        ],
      ),
    );
  }
}