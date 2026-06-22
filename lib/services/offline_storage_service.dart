import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/data_models.dart';

class OfflineStorageService {
  static const String _boreholeBoxName = 'boreholes_cache';
  static const String _draftsBoxName = 'drafts_queue';

  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Hive.openBox(_boreholeBoxName);
    await Hive.openBox(_draftsBoxName);
    _initialized = true;
  }

  // ─── Boreholes Cache ───────────────────────────────────────────────────────

  Future<void> cacheBoreholes(List<Borehole> boreholes) async {
    final box = Hive.box(_boreholeBoxName);
    final jsonList = boreholes.map((b) => b.toJson()).toList();
    await box.put('assigned_boreholes', jsonEncode(jsonList));
  }

  List<Borehole> getCachedBoreholes() {
    final box = Hive.box(_boreholeBoxName);
    final raw = box.get('assigned_boreholes') as String?;
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((item) => Borehole.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Drafts Sync Queue ────────────────────────────────────────────────────

  Future<void> saveDraft(String key, Map<String, dynamic> submissionJson) async {
    final box = Hive.box(_draftsBoxName);
    await box.put(key, jsonEncode(submissionJson));
  }

  List<Map<String, dynamic>> getDrafts() {
    final box = Hive.box(_draftsBoxName);
    final list = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final raw = box.get(key) as String?;
      if (raw != null) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          map['_draft_key'] = key; // Keep key for deletion
          list.add(map);
        } catch (_) {}
      }
    }
    return list;
  }

  Future<void> deleteDraft(String key) async {
    final box = Hive.box(_draftsBoxName);
    await box.delete(key);
  }

  Future<void> clearAll() async {
    await Hive.box(_boreholeBoxName).clear();
    await Hive.box(_draftsBoxName).clear();
  }
}
