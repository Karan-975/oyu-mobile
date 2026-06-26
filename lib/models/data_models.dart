double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) {
    return double.tryParse(val) ?? 0.0;
  }
  return 0.0;
}

double? _parseDoubleNullable(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) {
    return double.tryParse(val);
  }
  return null;
}

String _parseString(dynamic val, [String fallback = '']) {
  if (val == null) return fallback;
  return val.toString();
}

bool _parseBool(dynamic val) {
  if (val == true || val == 1) return true;
  if (val is String) {
    final normalized = val.toLowerCase().trim();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

int _parseInt(dynamic val, [int fallback = 0]) {
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? fallback;
  return fallback;
}

List<Map<String, dynamic>> _parseMapList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return [];
}

// Borehole model
class Borehole {
  final String id;
  final String uniqueId;
  final String village;
  final String taluka;
  final String district;
  final String state;
  final double latitude;
  final double longitude;
  final String? waterTableDepth;
  final String? formationType;
  final String status;
  final String assignmentStatus;
  final String? ngoId;
  final String? contractorId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Borehole({
    required this.id,
    required this.uniqueId,
    required this.village,
    required this.taluka,
    required this.district,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.waterTableDepth,
    this.formationType,
    required this.status,
    required this.assignmentStatus,
    this.ngoId,
    this.contractorId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Borehole.fromJson(Map<String, dynamic> json) {
    return Borehole(
      id: json['id'] as String? ?? '',
      uniqueId: (json['unique_id'] ?? json['borehole_code'] ?? '') as String,
      village: json['village'] as String? ?? '',
      taluka: json['taluka'] as String? ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      waterTableDepth: json['water_table_depth'] as String?,
      formationType: json['formation_type'] as String?,
      status: json['status'] as String? ?? 'active',
      assignmentStatus: json['assignment_status'] as String? ?? 'pending',
      ngoId: json['ngo_id'] as String? ?? json['assigned_ngo_id'] as String?,
      contractorId:
          json['contractor_id'] as String? ?? json['assigned_contractor_id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'unique_id': uniqueId,
        'village': village,
        'taluka': taluka,
        'district': district,
        'state': state,
        'latitude': latitude,
        'longitude': longitude,
        'water_table_depth': waterTableDepth,
        'formation_type': formationType,
        'status': status,
        'assignment_status': assignmentStatus,
        'ngo_id': ngoId,
        'contractor_id': contractorId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}

// ─── Survey Module (matches actual API response from /forms/:id) ─────────────

class FieldOption {
  final String id;
  final String label;
  final String value;
  final double? score;

  FieldOption({required this.id, required this.label, required this.value, this.score});

  factory FieldOption.fromJson(Map<String, dynamic> json) {
    return FieldOption(
      id: _parseString(json['id']),
      label: _parseString(json['label']),
      value: _parseString(json['value']),
      score: _parseDoubleNullable(json['score']),
    );
  }
}

class FieldValidation {
  final String ruleType;
  final String? ruleValue;
  final String? message;

  FieldValidation({required this.ruleType, this.ruleValue, this.message});

  factory FieldValidation.fromJson(Map<String, dynamic> json) {
    return FieldValidation(
      ruleType: _parseString(json['rule_type']),
      ruleValue: json['rule_value'] as String?,
      message: json['message'] as String?,
    );
  }
}

class FieldCondition {
  final String dependsOnKey;
  final String operator;
  final String? conditionValue;
  final String action;

  FieldCondition({
    required this.dependsOnKey,
    required this.operator,
    this.conditionValue,
    required this.action,
  });

  factory FieldCondition.fromJson(Map<String, dynamic> json) {
    return FieldCondition(
      dependsOnKey: _parseString(json['depends_on_key']),
      operator: _parseString(json['operator'], 'equals'),
      conditionValue: json['condition_value']?.toString(),
      action: _parseString(json['action'], 'show'),
    );
  }
}

class SurveyField {
  final String id;
  final String fieldKey;   // API: field_key
  final String label;      // API: label
  final String fieldType;  // API: field_type (text|number|textarea|dropdown|radio|checkbox|date|gps|image|signature|file)
  final String? placeholder;
  final String? helpText;
  final bool isRequired;
  final bool hasScoring;
  final int orderIndex;
  final List<FieldOption> options;
  final List<FieldValidation> validations;
  final List<FieldCondition> conditions;

  SurveyField({
    required this.id,
    required this.fieldKey,
    required this.label,
    required this.fieldType,
    this.placeholder,
    this.helpText,
    required this.isRequired,
    required this.hasScoring,
    required this.orderIndex,
    required this.options,
    required this.validations,
    required this.conditions,
  });

  factory SurveyField.fromJson(Map<String, dynamic> json) {
    return SurveyField(
      id: _parseString(json['id']),
      fieldKey: _parseString(json['field_key'] ?? json['key']),
      label: _parseString(json['label']),
      fieldType: _parseString(json['field_type'] ?? json['type'], 'text'),
      placeholder: json['placeholder'] as String?,
      helpText: json['help_text'] as String?,
      isRequired: _parseBool(json['is_required'] ?? json['required']),
      hasScoring: _parseBool(json['has_scoring']),
      orderIndex: _parseInt(json['order_index']),
      options: _parseMapList(json['options']).map(FieldOption.fromJson).toList(),
      validations: _parseMapList(json['validations']).map(FieldValidation.fromJson).toList(),
      conditions: _parseMapList(json['conditions']).map(FieldCondition.fromJson).toList(),
    );
  }
}

class SurveySection {
  final String id;
  final String title;   // API: title
  final String? description;
  final int orderIndex;
  final List<SurveyField> fields;

  SurveySection({
    required this.id,
    required this.title,
    this.description,
    required this.orderIndex,
    required this.fields,
  });

  factory SurveySection.fromJson(Map<String, dynamic> json) {
    return SurveySection(
      id: _parseString(json['id']),
      title: _parseString(json['title']),
      description: json['description'] as String?,
      orderIndex: _parseInt(json['order_index']),
      fields: _parseMapList(json['fields']).map(SurveyField.fromJson).toList(),
    );
  }
}

class SurveyModule {
  final String id;
  final String slug;        // API: slug
  final String name;        // API: name
  final String? description;
  final bool isMultiStep;
  final List<SurveySection> sections;

  SurveyModule({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    required this.isMultiStep,
    required this.sections,
  });

  factory SurveyModule.fromJson(Map<String, dynamic> json) {
    return SurveyModule(
      id: _parseString(json['id']),
      slug: _parseString(json['slug'] ?? json['module_type']),
      name: _parseString(json['name']),
      description: json['description'] as String?,
      isMultiStep: _parseBool(json['is_multi_step']),
      sections: _parseMapList(json['sections']).map(SurveySection.fromJson).toList(),
    );
  }

  /// Flat list of all fields across all sections
  List<SurveyField> get allFields =>
      sections.expand((s) => s.fields).toList();
}

// ─── Survey Submission ────────────────────────────────────────────────────────

class SurveySubmission {
  final String? id;
  final String boreholId;
  final String surveyModuleId;   // slug or id of the form module
  final Map<String, dynamic> formData;
  final double? latitude;
  final double? longitude;
  final String status;

  SurveySubmission({
    this.id,
    required this.boreholId,
    required this.surveyModuleId,
    required this.formData,
    this.latitude,
    this.longitude,
    required this.status,
  });

  factory SurveySubmission.fromJson(Map<String, dynamic> json) {
    return SurveySubmission(
      id: json['id'] as String?,
      boreholId: json['borehole_id'] as String? ?? '',
      surveyModuleId: json['survey_module_id'] as String? ?? '',
      formData: json['form_data'] as Map<String, dynamic>? ?? {},
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'submitted',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'borehole_id': boreholId,
        'survey_module_id': surveyModuleId,
        'form_data': formData,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'status': status,
      };
}
