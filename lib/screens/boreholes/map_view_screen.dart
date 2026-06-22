import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/data_models.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'borehole_detail_screen.dart';

/// OpenStreetMap view of assigned boreholes — spec §11.4 map toggle
class MapViewScreen extends StatefulWidget {
  final List<Borehole> boreholes;
  final Borehole? focusBorehole;

  const MapViewScreen({
    super.key,
    required this.boreholes,
    this.focusBorehole,
  });

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  late final MapController _mapController;
  Borehole? _selected;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selected = widget.focusBorehole;
  }

  LatLng get _center {
    if (widget.focusBorehole != null) {
      return LatLng(widget.focusBorehole!.latitude, widget.focusBorehole!.longitude);
    }
    if (widget.boreholes.isNotEmpty) {
      final avg_lat = widget.boreholes.map((b) => b.latitude).reduce((a, b) => a + b) / widget.boreholes.length;
      final avg_lng = widget.boreholes.map((b) => b.longitude).reduce((a, b) => a + b) / widget.boreholes.length;
      return LatLng(avg_lat, avg_lng);
    }
    return const LatLng(0, 0);
  }

  Color _pinColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': case 'functional': return AppColors.success;
      case 'inactive': case 'non_functional': return AppColors.error;
      case 'under_rehabilitation': return AppColors.warning;
      default: return AppColors.info;
    }
  }

  Future<void> _navigateTo(Borehole b) async {
    final uri = Uri.parse('geo:${b.latitude},${b.longitude}?q=${b.latitude},${b.longitude}(${b.uniqueId})');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${b.latitude},${b.longitude}');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Map View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_outlined),
            tooltip: 'Center on boreholes',
            onPressed: () {
              _mapController.move(_center, 12.0);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.focusBorehole != null ? 15.0 : 10.0,
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.oyugreen.mobile',
              ),
              MarkerLayer(
                markers: widget.boreholes.map((b) {
                  final isSelected = _selected?.id == b.id;
                  return Marker(
                    point: LatLng(b.latitude, b.longitude),
                    width: isSelected ? 48 : 38,
                    height: isSelected ? 48 : 38,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selected = b);
                        _mapController.move(LatLng(b.latitude, b.longitude), 15.0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _pinColor(b.status),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
                          boxShadow: [
                            BoxShadow(
                              color: _pinColor(b.status).withValues(alpha: 0.4),
                              blurRadius: isSelected ? 16 : 8,
                              spreadRadius: isSelected ? 2 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.water_drop,
                          color: Colors.white,
                          size: isSelected ? 24 : 18,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── Legend ───────────────────────────────────────────────────────
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  const SizedBox(height: 6),
                  _LegendRow(color: AppColors.success, label: 'Functional'),
                  _LegendRow(color: AppColors.error, label: 'Non-Functional'),
                  _LegendRow(color: AppColors.warning, label: 'Rehab'),
                  _LegendRow(color: AppColors.info, label: 'Other'),
                ],
              ),
            ),
          ),

          // ── Borehole count badge ─────────────────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.water_drop, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    '${widget.boreholes.length} Borehole${widget.boreholes.length != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // ── Selected Borehole Card ────────────────────────────────────────
          if (_selected != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _BoreholeMapCard(
                borehole: _selected!,
                onNavigate: () => _navigateTo(_selected!),
                onViewDetail: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BoreholeDetailScreen(
                        borehole: _selected!,
                        currentUserId: auth.user?.id ?? '',
                      ),
                    ),
                  );
                },
                onDismiss: () => setState(() => _selected = null),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _BoreholeMapCard extends StatelessWidget {
  final Borehole borehole;
  final VoidCallback onNavigate;
  final VoidCallback onViewDetail;
  final VoidCallback onDismiss;

  const _BoreholeMapCard({
    required this.borehole,
    required this.onNavigate,
    required this.onViewDetail,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(borehole.uniqueId,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    Text('${borehole.village}, ${borehole.district}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              StatusPill.fromStatus(borehole.status),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close, size: 18, color: AppColors.subtle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_outlined, size: 16),
                  label: const Text('Navigate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onViewDetail,
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
