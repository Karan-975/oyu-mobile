import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/data_models.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';

class DataProvider extends ChangeNotifier {
  final ApiService _apiService;
  final Logger _logger = Logger();
  
  List<Borehole> _boreholes = [];
  final Map<String, SurveyModule> _surveyModules = {};
  bool _isLoading = false;
  String? _error;

  DataProvider({required this._apiService});

  // Getters
  List<Borehole> get boreholes => _boreholes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get assigned boreholes
  Future<void> loadBoreholes() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _boreholes = await _apiService.getAssignedBoreholes();
      await OfflineStorageService().cacheBoreholes(_boreholes);
      _logger.i('Loaded and cached ${_boreholes.length} boreholes');
    } catch (e) {
      _logger.e('Error loading boreholes, falling back to cache', error: e);
      _boreholes = OfflineStorageService().getCachedBoreholes();
      if (_boreholes.isEmpty) {
        _error = _extractErrorMessage(e);
      } else {
        _error = 'Offline Mode: Loaded from cache.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new borehole
  Future<Borehole?> createBorehole(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _apiService.createBorehole(data);
      if (result != null) {
        final newBorehole = Borehole.fromJson(result);
        _boreholes.add(newBorehole);
        await OfflineStorageService().cacheBoreholes(_boreholes);
        _logger.i('Borehole created successfully: ${newBorehole.uniqueId}');
        return newBorehole;
      }
      _error = 'Failed to create borehole';
      return null;
    } catch (e) {
      _logger.e('Error creating borehole', error: e);
      _error = _extractErrorMessage(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check coordinates duplicate proximity
  List<Borehole> checkCoordinateDuplicates(double latitude, double longitude) {
    final List<Borehole> duplicates = [];
    for (final b in _boreholes) {
      final latDiff = (b.latitude - latitude).abs();
      final lngDiff = (b.longitude - longitude).abs();
      if (latDiff < 0.0005 && lngDiff < 0.0005) {
        duplicates.add(b);
      }
    }
    return duplicates;
  }

  // Get survey module
  Future<SurveyModule?> getSurveyModule(String moduleCode) async {
    try {
      final cachedModule = _surveyModules[moduleCode];
      if (cachedModule != null) {
        _logger.i('Using cached survey module: $moduleCode');
        return cachedModule;
      }

      _logger.i('Fetching survey module: $moduleCode');
      final module = await _apiService.getSurveyModule(moduleCode);
      
      if (module != null) {
        _surveyModules[moduleCode] = module;
        _logger.i('Survey module fetched and cached: $moduleCode');
      }
      
      return module;
    } catch (e) {
      _logger.e('Error fetching survey module', error: e);
      _error = _extractErrorMessage(e);
      notifyListeners();
    }
    
    return null;
  }

  // Submit survey
  Future<bool> submitSurvey(SurveySubmission submission) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _apiService.submitSurvey(submission);
      
      if (result != null) {
        _logger.i('Survey submitted successfully');
        return true;
      }
      
      _error = 'Failed to submit survey. Saving to drafts.';
      await _saveToDraftsQueue(submission);
      return false;
    } catch (e) {
      _logger.e('Error submitting survey, saving as draft', error: e);
      _error = 'Offline: Saved to drafts sync queue.';
      await _saveToDraftsQueue(submission);
      return true; // Returns true because it has been safely queued
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToDraftsQueue(SurveySubmission submission) async {
    final key = 'draft_${DateTime.now().millisecondsSinceEpoch}_${submission.boreholId}_${submission.surveyModuleId}';
    await OfflineStorageService().saveDraft(key, submission.toJson());
  }

  // Sync drafts queue
  Future<int> syncDrafts() async {
    final drafts = OfflineStorageService().getDrafts();
    if (drafts.isEmpty) return 0;
    
    _isLoading = true;
    notifyListeners();
    
    int successCount = 0;
    for (final draft in drafts) {
      final key = draft['_draft_key'] as String;
      final Map<String, dynamic> cleanDraft = Map.from(draft)..remove('_draft_key');
      final submission = SurveySubmission.fromJson(cleanDraft);
      
      try {
        final result = await _apiService.submitSurvey(submission);
        if (result != null) {
          await OfflineStorageService().deleteDraft(key);
          successCount++;
        }
      } catch (e) {
        _logger.e('Failed to sync draft: $key', error: e);
      }
    }
    
    _logger.i('Synced $successCount/${drafts.length} drafts');
    _isLoading = false;
    notifyListeners();
    
    if (successCount > 0) {
      await loadBoreholes();
    }
    return successCount;
  }

  // Upload file
  Future<String?> uploadFile(String filePath) async {
    try {
      _logger.i('Uploading file: $filePath');
      final url = await _apiService.uploadFile(filePath);
      
      if (url.isNotEmpty) {
        _logger.i('File uploaded: $url');
        return url;
      }
      
      _error = 'File upload failed';
      return null;
    } catch (e) {
      _logger.e('Error uploading file', error: e);
      _error = _extractErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  // ─── Water Testing ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> loadWaterTests(String boreholeId) async {
    try {
      _error = null;
      return await _apiService.getWaterTests(boreholeId);
    } catch (e) {
      _logger.e('Error loading water tests', error: e);
      _error = _extractErrorMessage(e);
      return [];
    }
  }

  Future<bool> logWaterTestSample({
    required String boreholeId,
    required String sampleCode,
    String? vialPhotoUrl,
    String testType = 'post_rehabilitation',
    String? testDate,
    String? sampleCollectionDate,
    String? sampleDescription,
    String? waterAppearance,
    String? testingRemarks,
    String? nearbySourceImageUrl,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final result = await _apiService.createWaterTest(
        boreholeId,
        sampleCode,
        vialPhotoUrl,
        testType: testType,
        testDate: testDate,
        sampleCollectionDate: sampleCollectionDate,
        sampleDescription: sampleDescription,
        waterAppearance: waterAppearance,
        testingRemarks: testingRemarks,
        nearbySourceImageUrl: nearbySourceImageUrl,
      );
      if (result != null) {
        _logger.i('Water test sample registered successfully');
        return true;
      }
      
      _error = 'Failed to register water test sample';
      return false;
    } catch (e) {
      _logger.e('Error registering water test sample', error: e);
      _error = _extractErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh boreholes
  Future<void> refreshBoreholes() async {
    await loadBoreholes();
  }

  // Get borehole by ID
  Borehole? getBoreholById(String id) {
    try {
      return _boreholes.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper to extract error message
  String _extractErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }

  // Clear cache
  void clearCache() {
    _surveyModules.clear();
    _logger.i('Cache cleared');
  }
}
