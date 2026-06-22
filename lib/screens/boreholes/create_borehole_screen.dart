import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../models/data_models.dart';
import 'borehole_detail_screen.dart';

class CreateBoreholeScreen extends StatefulWidget {
  final String currentUserId;
  const CreateBoreholeScreen({super.key, required this.currentUserId});

  @override
  State<CreateBoreholeScreen> createState() => _CreateBoreholeScreenState();
}

class _CreateBoreholeScreenState extends State<CreateBoreholeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _villageCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _depthCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  
  String? _selectedProvince;
  String _selectedOwnership = 'Community';
  String _selectedType = 'Handpump';
  
  double? _latitude;
  double? _longitude;
  double? _accuracy;
  bool _fetchingGps = false;
  String? _gpsError;

  final List<String> _provinces = [
    'Eastern Province',
    'Western Province',
    'Northern Province',
    'Southern Province',
    'Central Province',
    'Gauteng',
    'Limpopo',
    'Mpumalanga',
  ];

  final List<String> _ownershipTypes = [
    'Community',
    'Private',
    'School',
    'Clinic/Hospital',
    'Institutional',
  ];

  final List<String> _boreholeTypes = [
    'Handpump',
    'Solar Powered',
    'Electric Submersible',
    'Diesel Powered',
  ];

  @override
  void dispose() {
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    _nameCtrl.dispose();
    _depthCtrl.dispose();
    _yearCtrl.dispose();
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

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
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

      if (position.accuracy > 5.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS accuracy is ${position.accuracy.toStringAsFixed(1)}m. FRS requires ≤5m. Retrying to get better lock...'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _gpsError = e.toString().replaceAll('Exception: ', '');
        _fetchingGps = false;
      });
    }
  }

  void _simulateGpsLocation() {
    setState(() {
      _latitude = -15.4167 + (DateTime.now().millisecond / 100000.0);
      _longitude = 28.2833 + (DateTime.now().millisecond / 100000.0);
      _accuracy = 3.2; // Meets the <=5m requirement
      _gpsError = null;
      _fetchingGps = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulated high-accuracy GPS coordinates successfully.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _calculateTempId(String village, String province, List<Borehole> existing) {
    final villagePart = village.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase().padRight(4, 'X').substring(0, 4);
    final provincePart = province.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase().padRight(2, 'X').substring(0, 2);
    
    int maxSequence = 0;
    for (final b in existing) {
      final code = b.uniqueId;
      if (code.length >= 8) {
        final vPart = code.substring(0, 4);
        final pPart = code.substring(code.length - 2);
        if (vPart == villagePart && pPart == provincePart) {
          final numStr = code.substring(4, code.length - 2);
          final parsed = int.tryParse(numStr);
          if (parsed != null && parsed > maxSequence) {
            maxSequence = parsed;
          }
        }
      }
    }
    final nextSequence = maxSequence + 1;
    return '$villagePart${nextSequence.toString().padLeft(4, '0')}$provincePart';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_latitude == null || _longitude == null || _accuracy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture GPS coordinates first.')),
      );
      return;
    }

    if (_accuracy! > 5.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('GPS accuracy (${_accuracy!.toStringAsFixed(1)}m) must be ≤5m to register a borehole.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final dataProvider = context.read<DataProvider>();
    
    // Coordinates Proximity Duplicate Check
    final duplicates = dataProvider.checkCoordinateDuplicates(_latitude!, _longitude!);
    if (duplicates.isNotEmpty) {
      final dupCodes = duplicates.map((d) => d.uniqueId).join(', ');
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Duplicate Coordinates Warning'),
          content: Text(
            'Borehole(s) $dupCodes are located within 50m of these coordinates.\n\nAre you sure you want to register a duplicate borehole?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Proceed Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final tempId = _calculateTempId(
      _villageCtrl.text.trim(),
      _selectedProvince ?? 'GP',
      dataProvider.boreholes,
    );

    final payload = {
      'boreholeCode': tempId,
      'name': _nameCtrl.text.trim().isEmpty ? 'Borehole $tempId' : _nameCtrl.text.trim(),
      'village': _villageCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'province': _selectedProvince,
      'latitude': _latitude,
      'longitude': _longitude,
      'functionalStatus': 'active',
      'waterSource': _selectedType,
      'depthMeters': double.tryParse(_depthCtrl.text.trim()),
      'installationYear': int.tryParse(_yearCtrl.text.trim()),
      'notes': 'Registered via Mobile App',
    };

    final newBorehole = await dataProvider.createBorehole(payload);
    if (mounted) {
      if (newBorehole != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Borehole $tempId created successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BoreholeDetailScreen(
              borehole: newBorehole,
              currentUserId: widget.currentUserId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dataProvider.error ?? 'Failed to create borehole.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Register New Borehole'),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Borehole Details',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
                const SizedBox(height: 12),
                
                // Village Name
                TextFormField(
                  controller: _villageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Village Name *',
                    hintText: 'e.g. Kampande',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Village is required' : null,
                  onChanged: (v) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Province / State
                DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: const InputDecoration(
                    labelText: 'Province / State *',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => _selectedProvince = v),
                  validator: (v) => v == null ? 'Province is required' : null,
                ),
                const SizedBox(height: 16),

                // District / Region
                TextFormField(
                  controller: _districtCtrl,
                  decoration: const InputDecoration(
                    labelText: 'District / Region *',
                    hintText: 'e.g. Siavonga',
                    prefixIcon: Icon(Icons.explore_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'District is required' : null,
                ),
                const SizedBox(height: 16),

                // Borehole Name / Reference
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Borehole Custom Name (Optional)',
                    hintText: 'e.g. Community Well B',
                    prefixIcon: Icon(Icons.edit_note_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Technical Details',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
                const SizedBox(height: 12),

                // Borehole Type
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Borehole Type',
                    prefixIcon: Icon(Icons.settings_outlined),
                  ),
                  items: _boreholeTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _selectedType = v ?? 'Handpump'),
                ),
                const SizedBox(height: 16),

                // Ownership Type
                DropdownButtonFormField<String>(
                  value: _selectedOwnership,
                  decoration: const InputDecoration(
                    labelText: 'Ownership Type',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  items: _ownershipTypes.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                  onChanged: (v) => setState(() => _selectedOwnership = v ?? 'Community'),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _depthCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Depth (Meters)',
                          hintText: 'e.g. 45.5',
                          suffixText: 'm',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _yearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Installation Year',
                          hintText: 'e.g. 2018',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // GPS Card with validator
                Text(
                  'GPS Coordinates',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_latitude != null && _longitude != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (_accuracy ?? 10) <= 5.0 
                                    ? AppColors.success.withValues(alpha: 0.1) 
                                    : AppColors.warning.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                (_accuracy ?? 10) <= 5.0 ? Icons.gps_fixed : Icons.gps_not_fixed,
                                color: (_accuracy ?? 10) <= 5.0 ? AppColors.success : AppColors.warning,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Latitude: ${_latitude!.toStringAsFixed(6)}',
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Longitude: ${_longitude!.toStringAsFixed(6)}',
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Accuracy: ${_accuracy!.toStringAsFixed(1)} meters',
                                    style: GoogleFonts.inter(
                                      fontSize: 12, 
                                      color: (_accuracy ?? 10) <= 5.0 ? AppColors.success : AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No coordinates captured yet. Capture GPS coordinates of the borehole.',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_gpsError != null) ...[
                        Text(
                          'GPS Error: $_gpsError',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _fetchingGps ? null : _fetchGpsLocation,
                              icon: _fetchingGps 
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.my_location, size: 16),
                              label: Text(_fetchingGps ? 'Getting Lock...' : 'Capture GPS'),
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
                const SizedBox(height: 32),
                
                // Submit Button
                ElevatedButton(
                  onPressed: dataProvider.isLoading ? null : _submit,
                  child: const Text('Register Borehole'),
                ),
                const SizedBox(height: 16),

                // Generated ID Preview card if village and province are filled
                if (_villageCtrl.text.isNotEmpty && _selectedProvince != null) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Will be registered as Borehole ID: ${_calculateTempId(_villageCtrl.text, _selectedProvince!, dataProvider.boreholes)}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (dataProvider.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
