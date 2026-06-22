import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../models/data_models.dart';

class WaterTestingScreen extends StatefulWidget {
  final Borehole borehole;
  const WaterTestingScreen({super.key, required this.borehole});

  @override
  State<WaterTestingScreen> createState() => _WaterTestingScreenState();
}

class _WaterTestingScreenState extends State<WaterTestingScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _waterTests = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = context.read<DataProvider>();
      final tests = await provider.loadWaterTests(widget.borehole.id);
      setState(() {
        _waterTests = tests;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openRegisterSampleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RegisterSampleSheet(
        borehole: widget.borehole,
        onSuccess: () {
          Navigator.pop(ctx);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Water Quality Testing'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const AppLoader()
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          'Error loading water tests',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header Card
                    AppCard(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.biotech, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Borehole #${widget.borehole.uniqueId}',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${widget.borehole.village}, ${widget.borehole.district}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _openRegisterSampleSheet,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Register', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Past Water Quality Reports',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                    const SizedBox(height: 10),

                    if (_waterTests.isEmpty)
                      AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.waves_outlined, size: 40, color: AppColors.subtle.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                'No water tests registered yet.',
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _openRegisterSampleSheet,
                                child: const Text('Register First Sample Now'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _waterTests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final test = _waterTests[index];
                          return _WaterTestCard(test: test);
                        },
                      ),
                  ],
                ),
    );
  }
}

class _WaterTestCard extends StatelessWidget {
  final Map<String, dynamic> test;
  const _WaterTestCard({required this.test});

  @override
  Widget build(BuildContext context) {
    final dateStr = test['submission_date'] ?? test['created_at'] ?? '';
    final code = test['sample_code'] ?? 'N/A';
    final status = (test['status'] ?? 'submitted').toString().toLowerCase();

    // Check if parameters exist
    final ph = test['param_ph'];
    final ec = test['param_ec'];
    final tds = test['param_tds'];
    final turbidity = test['param_turbidity'];
    final hasResults = ph != null || ec != null || tds != null;

    Color statusColor;
    Color statusBg;
    String statusLabel = status.replaceAll('_', ' ').toUpperCase();

    if (status == 'report_uploaded' || status == 'published') {
      statusColor = AppColors.success;
      statusBg = AppColors.successBg;
    } else if (status == 'rejected') {
      statusColor = AppColors.error;
      statusBg = AppColors.errorBg;
    } else {
      statusColor = AppColors.warning;
      statusBg = AppColors.warningBg;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample Code: $code',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Collected on: ${dateStr.toString().split('T').first}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          if (hasResults) ...[
            Text(
              'Lab Report Parameters',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ParameterWidget(label: 'pH', value: ph?.toString() ?? '—', unit: ''),
                _ParameterWidget(label: 'EC', value: ec?.toString() ?? '—', unit: 'µS/cm'),
                _ParameterWidget(label: 'TDS', value: tds?.toString() ?? '—', unit: 'mg/L'),
                _ParameterWidget(label: 'Turbidity', value: turbidity?.toString() ?? '—', unit: 'NTU'),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.hourglass_empty, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lab analysis in progress. Lab report details will be populated once uploaded.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ParameterWidget extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _ParameterWidget({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: GoogleFonts.inter(fontSize: 8, color: AppColors.subtle),
          ),
      ],
    );
  }
}

class _RegisterSampleSheet extends StatefulWidget {
  final Borehole borehole;
  final VoidCallback onSuccess;

  const _RegisterSampleSheet({
    required this.borehole,
    required this.onSuccess,
  });

  @override
  State<_RegisterSampleSheet> createState() => _RegisterSampleSheetState();
}

class _RegisterSampleSheetState extends State<_RegisterSampleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  
  String? _vialPhotoPath;
  String? _nearbySourcePhotoPath;
  String _testType = 'post_rehabilitation';
  String? _testDate;
  String? _sampleCollectionDate;
  String? _waterAppearance;
  bool _submitting = false;

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _descriptionCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _takeVialPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (picked != null) {
        setState(() => _vialPhotoPath = picked.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _takeNearbySourcePhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked != null) setState(() => _nearbySourcePhotoPath = picked.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _pickDate(bool sampleDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    final value = picked.toIso8601String().split('T').first;
    setState(() {
      if (sampleDate) {
        _sampleCollectionDate = value;
      } else {
        _testDate = value;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_testDate == null || _sampleCollectionDate == null || _vialPhotoPath == null || _nearbySourcePhotoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test date, collection date, and both required images must be provided.'), backgroundColor: AppColors.error),
      );
      return;
    }
    
    setState(() => _submitting = true);
    try {
      final provider = context.read<DataProvider>();

      // 1. Upload photo if present
      String? uploadUrl;
      if (_vialPhotoPath != null) {
        uploadUrl = await provider.uploadFile(_vialPhotoPath!);
        if (uploadUrl == null) {
          throw Exception('Failed to upload vial photo.');
        }
      }
      final nearbySourceUrl = await provider.uploadFile(_nearbySourcePhotoPath!);
      if (nearbySourceUrl == null) {
        throw Exception('Failed to upload nearby water source image.');
      }

      // 2. Register sample collection
      final success = await provider.logWaterTestSample(
        boreholeId: widget.borehole.id,
        sampleCode: _barcodeCtrl.text.trim(),
        vialPhotoUrl: uploadUrl,
        testType: _testType,
        testDate: _testDate,
        sampleCollectionDate: _sampleCollectionDate,
        sampleDescription: _descriptionCtrl.text.trim(),
        waterAppearance: _waterAppearance,
        testingRemarks: _remarksCtrl.text.trim(),
        nearbySourceImageUrl: nearbySourceUrl,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Water sample registered successfully!'), backgroundColor: AppColors.success),
        );
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to register sample.'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Register Water Sample Vial',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 4),
            Text(
              'Capture the required water testing details and supporting images.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _testType,
              decoration: const InputDecoration(labelText: 'Test Type *'),
              items: const [
                DropdownMenuItem(value: 'pre_rehabilitation', child: Text('Pre-Rehabilitation')),
                DropdownMenuItem(value: 'post_rehabilitation', child: Text('Post-Rehabilitation')),
              ],
              onChanged: (value) => setState(() => _testType = value ?? _testType),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _DateField(label: 'Test Date *', value: _testDate, onTap: () => _pickDate(false))),
                const SizedBox(width: 10),
                Expanded(child: _DateField(label: 'Sample Collection *', value: _sampleCollectionDate, onTap: () => _pickDate(true))),
              ],
            ),
            const SizedBox(height: 16),

            // Barcode Input
            TextFormField(
              controller: _barcodeCtrl,
              decoration: const InputDecoration(
                labelText: 'Vial Barcode / Sample ID *',
                hintText: 'e.g. VIAL-987213',
                prefixIcon: Icon(Icons.qr_code_scanner),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Barcode/ID is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Sample Description', hintText: 'Describe the sample and collection point'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _waterAppearance,
              decoration: const InputDecoration(labelText: 'Water Appearance'),
              items: const ['Clear', 'Cloudy', 'Yellow-Brown', 'Green', 'Coloured', 'Other']
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _waterAppearance = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Testing Remarks'),
            ),
            const SizedBox(height: 16),

            // Photo Capture
            Text(
              'Borehole Water Image *',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_vialPhotoPath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_vialPhotoPath!),
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.biotech, color: AppColors.subtle, size: 28),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takeVialPhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_vialPhotoPath != null ? 'Retake Photo' : 'Capture Vial Photo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Nearby Water Source Image *', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_nearbySourcePhotoPath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(_nearbySourcePhotoPath!), height: 80, width: 80, fit: BoxFit.cover),
                  )
                else
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                    child: const Icon(Icons.water_outlined, color: AppColors.subtle, size: 28),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takeNearbySourcePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_nearbySourcePhotoPath != null ? 'Retake Photo' : 'Capture Source Photo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: _submitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Submit Sample Registration'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text(value ?? 'Select', overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
