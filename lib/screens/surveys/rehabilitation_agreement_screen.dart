import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import '../../models/data_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'dynamic_survey_form_screen.dart';

class RehabilitationAgreementScreen extends StatefulWidget {
  final Borehole borehole;
  const RehabilitationAgreementScreen({super.key, required this.borehole});

  @override
  State<RehabilitationAgreementScreen> createState() => _RehabilitationAgreementScreenState();
}

class _RehabilitationAgreementScreenState extends State<RehabilitationAgreementScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _techNameCtrl = TextEditingController(text: 'Technician');
  final _hqNameCtrl = TextEditingController(text: 'OYU Officer');
  final _headmanNameCtrl = TextEditingController();

  // Signatory details
  String? _techSelfie;
  String? _techSigPath;
  String? _hqSelfie;
  String? _hqSigPath;
  String? _headmanSelfie;
  String? _headmanSigPath;

  double? _latitude;
  double? _longitude;
  double? _accuracy;
  bool _fetchingGps = false;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    _fetchGpsLocation();
  }

  @override
  void dispose() {
    _techNameCtrl.dispose();
    _hqNameCtrl.dispose();
    _headmanNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchGpsLocation() async {
    setState(() {
      _fetchingGps = true;
      _gpsError = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _accuracy = position.accuracy;
        _fetchingGps = false;
      });
    } catch (e) {
      setState(() {
        _gpsError = e.toString().replaceAll('Exception: ', '');
        _fetchingGps = false;
      });
    }
  }

  void _simulateGpsLocation() {
    setState(() {
      _latitude = widget.borehole.latitude;
      _longitude = widget.borehole.longitude;
      _accuracy = 2.8;
      _gpsError = null;
      _fetchingGps = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulated high-accuracy GPS coordinates for Agreement.'), backgroundColor: AppColors.success),
    );
  }

  Future<void> _captureSelfie(String signatory) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (picked != null) {
        setState(() {
          if (signatory == 'tech') _techSelfie = picked.path;
          if (signatory == 'hq') _hqSelfie = picked.path;
          if (signatory == 'headman') _headmanSelfie = picked.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing selfie: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _drawSignature(String signatory) async {
    final sigController = SignatureController(
      penStrokeWidth: 4,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    final path = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Draw Signature - ${signatory.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Signature(
                  controller: sigController,
                  height: 180,
                  backgroundColor: Colors.grey.shade50,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => sigController.clear(),
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (sigController.isEmpty) return;
              final bytes = await sigController.toPngBytes();
              if (bytes != null) {
                final tempDir = Directory.systemTemp;
                final file = await File(
                        '${tempDir.path}/sig_${signatory}_${DateTime.now().millisecondsSinceEpoch}.png')
                    .create();
                await file.writeAsBytes(bytes);
                Navigator.pop(ctx, file.path);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (path != null) {
      setState(() {
        if (signatory == 'tech') _techSigPath = path;
        if (signatory == 'hq') _hqSigPath = path;
        if (signatory == 'headman') _headmanSigPath = path;
      });
    }
    sigController.dispose();
  }

  void _proceed() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all signatory names.'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_techSelfie == null || _techSigPath == null ||
        _hqSelfie == null || _hqSigPath == null ||
        _headmanSelfie == null || _headmanSigPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All signatories must provide a Selfie and a Signature.'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_latitude == null || _longitude == null || _accuracy == null || _accuracy! > 5.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A high accuracy GPS location (≤5m) is required for Carbon Agreement signing.'), backgroundColor: AppColors.error),
      );
      return;
    }

    // Prepare agreement payload
    final agreementData = {
      'agreement_signed': true,
      'agreement_technician_name': _techNameCtrl.text.trim(),
      'agreement_technician_signature': _techSigPath,
      'agreement_technician_selfie': _techSelfie,
      
      'agreement_hq_name': _hqNameCtrl.text.trim(),
      'agreement_hq_signature': _hqSigPath,
      'agreement_hq_selfie': _hqSelfie,
      
      'agreement_headman_name': _headmanNameCtrl.text.trim(),
      'agreement_headman_signature': _headmanSigPath,
      'agreement_headman_selfie': _headmanSelfie,
      
      'agreement_latitude': _latitude,
      'agreement_longitude': _longitude,
      'agreement_accuracy': _accuracy,
      'agreement_timestamp': DateTime.now().toIso8601String(),
    };

    // Redirect to DynamicSurveyFormScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DynamicSurveyFormScreen(
          borehole: widget.borehole,
          surveyCode: 'rehabilitation',
          surveyName: 'Rehabilitation Report',
          initialData: agreementData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.borehole;
    final hName = _headmanNameCtrl.text.isEmpty ? '{Headman Name}' : _headmanNameCtrl.text;
    final tName = _techNameCtrl.text.isEmpty ? '{Technician Name}' : _techNameCtrl.text;
    final qName = _hqNameCtrl.text.isEmpty ? '{HQ Officer Name}' : _hqNameCtrl.text;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Carbon Transfer Agreement'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Banner/Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Carbon Rights Handover (FRS §7.13)',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rehabilitation requires a digitally signed and geo-tagged agreement with the village headman.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Agreement Text Card
            Text(
              'Agreement Text Preview',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            AppCard(
              color: Colors.white,
              child: Text(
                '\"I, $hName, as Headman (Community Representative), alongside $tName (Technician) and $qName (OYU HQ Member), hereby confirm that I am the rightful and authorized representative of the community utilizing the borehole bearing ID ${b.uniqueId}, located at ${b.village}, ${b.district}, with geographic coordinates ${b.latitude.toStringAsFixed(6)}, ${b.longitude.toStringAsFixed(6)}, and hereby agree to transfer the environmental carbon benefits of this borehole rehabilitation program to OYU Green.\"',
                style: GoogleFonts.inter(fontSize: 13, height: 1.5, fontStyle: FontStyle.italic, color: AppColors.ink),
              ),
            ),
            const SizedBox(height: 20),

            // GPS coordinates
            Text(
              'Signing Location Location (GPS)',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        (_accuracy ?? 10) <= 5.0 ? Icons.gps_fixed : Icons.gps_not_fixed,
                        color: (_accuracy ?? 10) <= 5.0 ? AppColors.success : AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _latitude != null 
                              ? 'Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)} (Acc: ${_accuracy!.toStringAsFixed(1)}m)'
                              : (_gpsError != null ? 'Error: $_gpsError' : 'No GPS acquired.'),
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _gpsError != null ? AppColors.error : null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _fetchingGps ? null : _fetchGpsLocation,
                          icon: const Icon(Icons.my_location, size: 16),
                          label: const Text('Get GPS'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _fetchingGps ? null : _simulateGpsLocation,
                          icon: const Icon(Icons.biotech_outlined, size: 16),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                          label: const Text('Simulate Lock'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Technician Card
            _SignatoryCard(
              title: '1. Technician (User)',
              nameCtrl: _techNameCtrl,
              selfiePath: _techSelfie,
              sigPath: _techSigPath,
              onTakeSelfie: () => _captureSelfie('tech'),
              onDrawSignature: () => _drawSignature('tech'),
            ),
            const SizedBox(height: 16),

            // 2. OYU HQ Officer Card
            _SignatoryCard(
              title: '2. OYU HQ Officer',
              nameCtrl: _hqNameCtrl,
              selfiePath: _hqSelfie,
              sigPath: _hqSigPath,
              onTakeSelfie: () => _captureSelfie('hq'),
              onDrawSignature: () => _drawSignature('hq'),
            ),
            const SizedBox(height: 16),

            // 3. Headman Card
            _SignatoryCard(
              title: '3. Village Headman (Community Rep)',
              nameCtrl: _headmanNameCtrl,
              nameHint: 'Enter Headman\'s Full Name',
              selfiePath: _headmanSelfie,
              sigPath: _headmanSigPath,
              onTakeSelfie: () => _captureSelfie('headman'),
              onDrawSignature: () => _drawSignature('headman'),
              onNameChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 32),

            // Proceed Button
            ElevatedButton.icon(
              onPressed: _proceed,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Verify & Proceed to Rehabilitation Report'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SignatoryCard extends StatelessWidget {
  final String title;
  final TextEditingController nameCtrl;
  final String? nameHint;
  final String? selfiePath;
  final String? sigPath;
  final VoidCallback onTakeSelfie;
  final VoidCallback onDrawSignature;
  final ValueChanged<String>? onNameChanged;

  const _SignatoryCard({
    required this.title,
    required this.nameCtrl,
    this.nameHint,
    this.selfiePath,
    this.sigPath,
    required this.onTakeSelfie,
    required this.onDrawSignature,
    this.onNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(height: 12),

          // Name field
          TextFormField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: nameHint ?? 'Enter Signatory Name',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onChanged: onNameChanged,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Selfie capture
              Expanded(
                child: Column(
                  children: [
                    if (selfiePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(selfiePath!),
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Icon(Icons.face, color: AppColors.subtle, size: 28),
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onTakeSelfie,
                      icon: const Icon(Icons.camera_alt_outlined, size: 14),
                      label: Text(selfiePath != null ? 'Retake Selfie' : 'Selfie Photo', style: const TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size.fromHeight(36),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Signature capture
              Expanded(
                child: Column(
                  children: [
                    if (sigPath != null)
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(sigPath!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Icon(Icons.draw, color: AppColors.subtle, size: 28),
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onDrawSignature,
                      icon: const Icon(Icons.gesture, size: 14),
                      label: Text(sigPath != null ? 'Redraw Signature' : 'Sign Pad', style: const TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size.fromHeight(36),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper extension on Widget to allow border wrapping
extension BorderWrap on Widget {
  Widget wrap(BoxDecoration decoration) {
    return Container(
      decoration: decoration,
      child: this,
    );
  }
}
