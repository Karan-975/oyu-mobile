import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:signature/signature.dart';
import '../../models/data_models.dart';
import '../../services/api_service.dart';

/// Renders backend-configured survey forms for NGO field workflows.
class DynamicSurveyFormScreen extends StatefulWidget {
  final Borehole borehole;
  final String surveyCode; // slug sent to /forms/:slug
  final String surveyName;
  final Map<String, dynamic>? initialData;
  final String? remarks;
  final bool isLocked;

  const DynamicSurveyFormScreen({
    super.key,
    required this.borehole,
    required this.surveyCode,
    required this.surveyName,
    this.initialData,
    this.remarks,
    this.isLocked = false,
  });

  @override
  State<DynamicSurveyFormScreen> createState() =>
      _DynamicSurveyFormScreenState();
}

class _DynamicSurveyFormScreenState extends State<DynamicSurveyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, SignatureController> _sigControllers = {};

  SurveyModule? _module;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  // Multi-step tracking
  int _currentStep = 0;

  // GPS
  double? _gpsLat;
  double? _gpsLng;
  bool _fetchingGps = false;

  @override
  void initState() {
    super.initState();
    _loadModule();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final c in _sigControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadModule() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final module = await api.getSurveyModule(widget.surveyCode);
      if (module == null) {
        setState(() {
          _error = 'Survey form not found. Please contact your administrator.';
          _loading = false;
        });
        return;
      }
      
      // Prefill initial data
      if (widget.initialData != null) {
        _formData.addAll(widget.initialData!);
      }

      // Prefill controllers for text/number/textarea fields
      for (final section in module.sections) {
        for (final field in section.fields) {
          final type = _normalizedType(field.fieldType);
          if (['text', 'number', 'email', 'phone', 'textarea'].contains(type)) {
            final val = widget.initialData?[field.fieldKey]?.toString() ?? '';
            _controllers[field.fieldKey] = TextEditingController(text: val);
          }
        }
      }
      
      setState(() {
        _module = module;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load survey: $e';
        _loading = false;
      });
    }
  }

  Future<void> _captureGps() async {
    setState(() => _fetchingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled.', isError: true);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permission permanently denied.', isError: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _gpsLat = pos.latitude;
        _gpsLng = pos.longitude;
      });
      _showSnack(
          'GPS captured: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}');
    } catch (e) {
      _showSnack('Failed to get GPS: $e', isError: true);
    } finally {
      setState(() => _fetchingGps = false);
    }
  }

  Future<void> _pickImage(String fieldKey, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        final cropper = ImageCropper();
        final cropped = await cropper.cropImage(
          sourcePath: picked.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.blue.shade700,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
          ],
        );
        if (cropped != null) {
          setState(() {
            _formData[fieldKey] = cropped.path;
          });
        }
      }
    } catch (e) {
      _showSnack('Error picking image: $e', isError: true);
    }
  }

  Future<void> _submit() async {
    if (widget.isLocked) {
      _showSnack('Form is locked and cannot be submitted.', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showSnack('Please fill all required fields.', isError: true);
      return;
    }
    _formKey.currentState!.save();

    // Merge text-controller values into _formData
    for (final entry in _controllers.entries) {
      _formData[entry.key] = entry.value.text.trim();
    }

    setState(() => _submitting = true);
    try {
      final api = context.read<ApiService>();

      // Upload local images/files/signatures first if online
      final Map<String, dynamic> finalFormData = Map.from(_formData);

      // Upload agreement files if they are local paths
      final agreementKeys = [
        'agreement_technician_signature',
        'agreement_technician_selfie',
        'agreement_hq_signature',
        'agreement_hq_selfie',
        'agreement_headman_signature',
        'agreement_headman_selfie'
      ];
      for (final key in agreementKeys) {
        final localPath = _formData[key];
        if (localPath is String && localPath.isNotEmpty && !localPath.startsWith('http')) {
          _showSnack('Uploading carbon agreement attachment...', isError: false);
          final uploadUrl = await api.uploadFile(localPath);
          if (uploadUrl.isNotEmpty) {
            finalFormData[key] = uploadUrl;
          } else {
            throw Exception('Failed to upload carbon agreement attachment');
          }
        }
      }

      for (final section in _module!.sections) {
        for (final field in section.fields) {
          final type = _normalizedType(field.fieldType);
          if (['image', 'file', 'signature'].contains(type)) {
            final localPath = _formData[field.fieldKey];
            if (localPath is String && localPath.isNotEmpty && !localPath.startsWith('http')) {
              _showSnack('Uploading ${field.label}...', isError: false);
              final uploadUrl = await api.uploadFile(localPath);
              if (uploadUrl.isNotEmpty) {
                finalFormData[field.fieldKey] = uploadUrl;
              } else {
                throw Exception('Failed to upload file for ${field.label}');
              }
            }
          }
        }
      }

      final submission = SurveySubmission(
        boreholId: widget.borehole.id,
        surveyModuleId: widget.surveyCode,
        formData: finalFormData,
        latitude: _gpsLat,
        longitude: _gpsLng,
        status: 'submitted',
      );
      
      final result = await api.submitSurvey(submission);
      if (!mounted) return;

      if (result != null) {
        _showSuccessDialog();
      } else {
        _showSnack('Submission failed. Please try again.', isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.check_circle, color: Colors.green, size: 40),
        ),
        title: const Text('Submitted!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          '${widget.surveyName} for Borehole #${widget.borehole.uniqueId} has been submitted successfully.\n\nIt will be reviewed by the supervisor.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _normalizedType(String type) {
    switch (type) {
      case 'text_input':
        return 'text';
      case 'numeric_input':
        return 'number';
      case 'single_choice':
        return 'radio';
      case 'multi_select':
      case 'consent_checkbox':
        return 'checkbox';
      case 'yes_no':
        return 'yes_no';
      case 'date_picker':
        return 'date';
      case 'geo_tag':
        return 'gps';
      case 'image_upload':
        return 'image';
      case 'document_upload':
        return 'file';
      case 'digital_signature':
        return 'signature';
      case 'text_with_fields':
        return 'textarea';
      default:
        return type;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.surveyName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading survey form...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadModule,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_module == null || _module!.sections.isEmpty) {
      return const Center(child: Text('No form fields configured.'));
    }

    final sections = _module!.sections;

    return Column(
      children: [
        if (widget.isLocked)
          Container(
            color: Colors.red.shade100,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.lock, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Currently being edited by another team member. Inputs are view-only.',
                    style: TextStyle(color: Colors.red.shade800, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        if (widget.remarks != null && widget.remarks!.isNotEmpty)
          Container(
            color: Colors.amber.shade100,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.feedback, color: Colors.amber.shade800, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remarks from NGO Admin:',
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.remarks!,
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _module!.isMultiStep && sections.length > 1
              ? _buildStepper(sections)
              : _buildScrollableForm(sections),
        ),
      ],
    );
  }

  // ── Single scrollable form (non-multi-step) ─────────────────────────────

  Widget _buildScrollableForm(List<SurveySection> sections) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _boreholeBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                for (final section in sections) ...[
                  _sectionHeader(section.title, section.description),
                  for (final field in section.fields)
                    _buildFieldWidget(field),
                  const SizedBox(height: 8),
                ],
                _gpsCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _submitBar(),
        ],
      ),
    );
  }

  // ── Multi-step stepper ───────────────────────────────────────────────────

  Widget _buildStepper(List<SurveySection> sections) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _boreholeBanner(),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: List.generate(sections.length, (i) {
                final isActive = i == _currentStep;
                final isDone = i < _currentStep;
                return Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isDone
                            ? Colors.green
                            : isActive
                                ? Colors.blue.shade700
                                : Colors.grey.shade300,
                        child: isDone
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey.shade600)),
                      ),
                      if (i < sections.length - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isDone
                                ? Colors.green
                                : Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Step ${_currentStep + 1}: ${sections[_currentStep].title}',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue.shade800),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                if (sections[_currentStep].description != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(sections[_currentStep].description!,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ),
                for (final field in sections[_currentStep].fields)
                  _buildFieldWidget(field),
                if (_currentStep == sections.length - 1) _gpsCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _stepperNavBar(sections),
        ],
      ),
    );
  }

  Widget _stepperNavBar(List<SurveySection> sections) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep--),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _currentStep < sections.length - 1
                ? ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _currentStep++);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  )
                : _submitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: widget.isLocked ? null : _submit,
                        icon: const Icon(Icons.send),
                        label: const Text('Submit Survey'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _boreholeBanner() {
    return Container(
      color: Colors.blue.shade700,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text(
            'Borehole #${widget.borehole.uniqueId} - ${widget.borehole.village}, ${widget.borehole.district}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String? description) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.blue.shade700, width: 4)),
            ),
            padding: const EdgeInsets.only(left: 10),
            child: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade800)),
          ),
          if (description != null && description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 4),
              child: Text(description,
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ),
        ],
      ),
    );
  }

  Widget _buildFieldWidget(SurveyField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(field),
          const SizedBox(height: 6),
          AbsorbPointer(
            absorbing: widget.isLocked,
            child: _fieldInput(field),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(SurveyField field) {
    return RichText(
      text: TextSpan(
        text: field.label,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        children: [
          if (field.isRequired)
            const TextSpan(
                text: ' *', style: TextStyle(color: Colors.red, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _fieldInput(SurveyField field) {
    switch (_normalizedType(field.fieldType)) {
      case 'text':
      case 'email':
      case 'phone':
        return _textField(field, maxLines: 1);

      case 'number':
        return _textField(field,
            maxLines: 1, keyboard: TextInputType.number);

      case 'textarea':
        return _textField(field, maxLines: 4);

      case 'dropdown':
        return _dropdownField(field);

      case 'radio':
      case 'yes_no':
        return _radioField(field);

      case 'checkbox':
        return _checkboxField(field);

      case 'date':
        return _dateField(field);

      case 'gps':
        return _gpsFieldCard(field);

      case 'image':
      case 'file':
        return _imageFieldCard(field);
        
      case 'signature':
        return _signatureFieldCard(field);

      default:
        return _textField(field, maxLines: 1);
    }
  }

  Widget _textField(SurveyField field,
      {int maxLines = 1, TextInputType? keyboard}) {
    final ctrl = _controllers[field.fieldKey] ??= TextEditingController();
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: field.placeholder ?? 'Enter ${field.label.toLowerCase()}',
        helperText: field.helpText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: field.isRequired
          ? (v) => (v == null || v.trim().isEmpty) ? '${field.label} is required' : null
          : null,
    );
  }

  Widget _dropdownField(SurveyField field) {
    return DropdownButtonFormField<String>(
      value: _formData[field.fieldKey] as String?,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        helperText: field.helpText,
      ),
      hint: Text(
        'Select ${field.label.toLowerCase()}',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      items: field.options
          .map((o) => DropdownMenuItem(
                value: o.value,
                child: Text(
                  o.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: (v) {
        setState(() {
          _formData[field.fieldKey] = v;
        });
      },
      validator: field.isRequired
          ? (v) => v == null ? '${field.label} is required' : null
          : null,
    );
  }

  Widget _radioField(SurveyField field) {
    final options = _normalizedType(field.fieldType) == 'yes_no'
        ? [
            FieldOption(id: 'yes', label: 'Yes', value: 'yes'),
            FieldOption(id: 'no', label: 'No', value: 'no'),
          ]
        : field.options;

    final val = _formData[field.fieldKey] as String?;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade300)),
      child: Column(
        children: options.map((opt) {
          return RadioListTile<String>(
            dense: true,
            title: Text(opt.label, style: const TextStyle(fontSize: 14)),
            value: opt.value,
            groupValue: val,
            onChanged: (v) => setState(() => _formData[field.fieldKey] = v),
          );
        }).toList(),
      ),
    );
  }

  Widget _checkboxField(SurveyField field) {
    final selected =
        (_formData[field.fieldKey] as List<String>?) ?? <String>[];
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade300)),
      child: Column(
        children: field.options.map((opt) {
          return CheckboxListTile(
            dense: true,
            title: Text(opt.label, style: const TextStyle(fontSize: 14)),
            value: selected.contains(opt.value),
            onChanged: (v) {
              setState(() {
                final list = List<String>.from(selected);
                if (v == true) {
                  list.add(opt.value);
                } else {
                  list.remove(opt.value);
                }
                _formData[field.fieldKey] = list;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _dateField(SurveyField field) {
    final picked = _formData[field.fieldKey] as String?;
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (d != null) {
          setState(
              () => _formData[field.fieldKey] = d.toIso8601String().split('T').first);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Text(
              picked ?? 'Select date',
              style: TextStyle(
                  color: picked != null ? Colors.black87 : Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gpsFieldCard(SurveyField field) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.blue.shade200)),
      child: ListTile(
        leading: const Icon(Icons.gps_fixed, color: Colors.blue),
        title: Text(
          _gpsLat != null
              ? '${_gpsLat!.toStringAsFixed(5)}, ${_gpsLng!.toStringAsFixed(5)}'
              : 'Tap to capture GPS location',
          style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
        ),
        trailing: _fetchingGps
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : ElevatedButton(
                onPressed: _captureGps,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12)),
                child: const Text('Capture'),
              ),
      ),
    );
  }

  Widget _imageFieldCard(SurveyField field) {
    final pickedPath = _formData[field.fieldKey] as String?;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pickedPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: pickedPath.startsWith('http')
                    ? Image.network(
                        pickedPath,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(pickedPath),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(field.fieldKey, ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Camera', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(field.fieldKey, ImageSource.gallery),
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                  ),
                ),
                if (pickedPath != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => setState(() => _formData.remove(field.fieldKey)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _signatureFieldCard(SurveyField field) {
    final pickedPath = _formData[field.fieldKey] as String?;
    final sigController = _sigControllers[field.fieldKey] ??= SignatureController(
      penStrokeWidth: 4,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pickedPath != null) ...[
              const Text('Signature Captured:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: pickedPath.startsWith('http')
                      ? Image.network(
                          pickedPath,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        )
                      : Image.file(
                          File(pickedPath),
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => setState(() => _formData.remove(field.fieldKey)),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Clear Signature'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
              ),
            ] else ...[
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Signature(
                    controller: sigController,
                    height: 150,
                    backgroundColor: Colors.grey.shade50,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (sigController.isEmpty) return;
                      final bytes = await sigController.toPngBytes();
                      if (bytes != null) {
                        final tempDir = Directory.systemTemp;
                        final file = await File(
                                '${tempDir.path}/sig_${DateTime.now().millisecondsSinceEpoch}.png')
                            .create();
                        await file.writeAsBytes(bytes);
                        setState(() {
                          _formData[field.fieldKey] = file.path;
                        });
                      }
                    },
                    child: const Text('Save Signature', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => sigController.clear(),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _gpsCard() {
    return Card(
      elevation: 0,
      color: Colors.green.shade50,
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.green.shade200)),
      child: ListTile(
        leading: Icon(Icons.my_location, color: Colors.green.shade700),
        title: Text(
          _gpsLat != null
              ? 'GPS: ${_gpsLat!.toStringAsFixed(5)}, ${_gpsLng!.toStringAsFixed(5)}'
              : 'Capture your current GPS location',
          style: TextStyle(fontSize: 13, color: Colors.green.shade800),
        ),
        subtitle: const Text('Optional - attaches your location to this submission',
            style: TextStyle(fontSize: 11)),
        trailing: _fetchingGps
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : ElevatedButton(
                onPressed: _captureGps,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12)),
                child: Text(_gpsLat != null ? 'Re-capture' : 'Capture GPS'),
              ),
      ),
    );
  }

  Widget _submitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: _submitting
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton.icon(
              onPressed: widget.isLocked ? null : _submit,
              icon: const Icon(Icons.send),
              label: const Text('Submit Survey',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
    );
  }
}
