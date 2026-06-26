import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import '../models/auth_models.dart';
import '../models/data_models.dart';

class ApiService {
  late Dio _dio;
  late Dio _refreshDio; // Separate instance for refresh to avoid interceptor loop
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  
  String? _accessToken;
  String? _refreshToken;
  Future<String?>? _refreshFuture;

  VoidCallback? onSessionExpired;

  ApiService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectionTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectionTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LoggingInterceptor(_logger));
    }
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    _logger.i('Request: ${options.method} ${options.path}');
    if (_accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }
    return handler.next(options);
  }

  Future<void> _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    _logger.i('Response: ${response.statusCode} ${response.requestOptions.path}');
    return handler.next(response);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    _logger.e('Error: ${err.message}', error: err);

    final isAuthRequest = err.requestOptions.path == ApiConfig.loginEndpoint ||
        err.requestOptions.path == ApiConfig.refreshEndpoint;

    if (err.response?.statusCode == 401 && !isAuthRequest) {
      _logger.w('Unauthorized (401) - Token may be expired');

      final requestAuth = err.requestOptions.headers['Authorization'];
      if (requestAuth != null && requestAuth != 'Bearer $_accessToken') {
        _logger.i('Token already refreshed by another request, retrying request');
        try {
          final response = await _retryRequest(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(DioException(
            requestOptions: err.requestOptions,
            error: e,
          ));
        }
      }

      if (_refreshFuture == null) {
        _logger.i('Initiating token refresh');
        _refreshFuture = _refreshAccessToken().then((tokens) {
          _refreshFuture = null;
          return tokens?.accessToken;
        }).catchError((e) {
          _refreshFuture = null;
          return null;
        });
      }

      try {
        final newAccessToken = await _refreshFuture;
        if (newAccessToken != null) {
          _logger.i('Token refreshed, retrying request');
          final response = await _retryRequest(err.requestOptions);
          return handler.resolve(response);
        } else {
          _logger.w('Refresh token failed, clearing tokens');
          await clearTokens();
          onSessionExpired?.call();
          return handler.next(err);
        }
      } catch (e) {
        _logger.e('Refresh token failed with error, clearing tokens', error: e);
        await clearTokens();
        onSessionExpired?.call();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) {
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $_accessToken',
      },
    );
    return _dio.request(
      requestOptions.path,
      options: options,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
    );
  }

  Future<RefreshTokenResponse?> _refreshAccessToken() async {
    try {
      _logger.i('Refreshing access token');

      if (_refreshToken == null) {
        _logger.w('No refresh token available');
        return null;
      }

      final response = await _refreshDio.post(
        ApiConfig.refreshEndpoint,
        data: {'refreshToken': _refreshToken},
      );

      if (response.statusCode == 200) {
        final newTokens = RefreshTokenResponse.fromJson(
          _getMapData(response.data),
        );

        _accessToken = newTokens.accessToken;
        _refreshToken = newTokens.refreshToken;

        await _secureStorage.write(key: 'access_token', value: _accessToken!);
        await _secureStorage.write(key: 'refresh_token', value: _refreshToken!);

        _logger.i('Token refreshed successfully');
        return newTokens;
      }
    } catch (e) {
      _logger.e('Error refreshing token', error: e);
    }

    return null;
  }

  // ── Authentication ─────────────────────────────────────────────────────────

  Future<LoginResponse> login(String email, String password) async {
    try {
      _logger.i('Attempting login for: $email');

      final response = await _dio.post(
        ApiConfig.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final loginResponse = LoginResponse.fromJson(_getMapData(response.data));

        _accessToken = loginResponse.accessToken;
        _refreshToken = loginResponse.refreshToken;

        await _secureStorage.write(key: 'access_token', value: _accessToken!);
        await _secureStorage.write(key: 'refresh_token', value: _refreshToken!);

        _logger.i('Login successful');
        return loginResponse;
      }

      throw Exception('Login failed: ${response.statusCode}');
    } on DioException catch (e) {
      _logger.e('Login error', error: e);
      throw Exception(_extractApiErrorMessage(e));
    } catch (e) {
      _logger.e('Login error', error: e);
      rethrow;
    }
  }

  String _extractApiErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    switch (error.response?.statusCode) {
      case 401:
        return 'Invalid email or password.';
      case 403:
        return 'Access denied for this account.';
      case 404:
        return 'Login service not found. Please check API configuration.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  Future<User?> getProfile() async {
    try {
      _logger.i('Fetching user profile');
      final response = await _dio.get(ApiConfig.meEndpoint);
      if (response.statusCode == 200) {
        return User.fromJson(_getMapData(response.data));
      }
    } catch (e) {
      _logger.e('Error fetching profile', error: e);
    }
    return null;
  }

  Future<void> logout() async {
    try {
      _logger.i('Logging out');
      if (_accessToken != null) {
        await _dio.post(ApiConfig.logoutEndpoint);
      }
      await clearTokens();
      _logger.i('Logout successful');
    } catch (e) {
      _logger.e('Error during logout', error: e);
      await clearTokens();
    }
  }

  // ── Boreholes ──────────────────────────────────────────────────────────────

  Future<List<Borehole>> getAssignedBoreholes() async {
    try {
      _logger.i('Fetching assigned boreholes');
      final response = await _dio.get(ApiConfig.boreholesEndpoint);
      if (response.statusCode == 200) {
        final data = _getListData(response.data);
        final boreholes = data
            .map((b) => Borehole.fromJson(b as Map<String, dynamic>))
            .toList();
        _logger.i('Boreholes fetched: ${boreholes.length}');
        return boreholes;
      }
    } catch (e) {
      _logger.e('Error fetching boreholes', error: e);
    }
    return [];
  }

  Future<Map<String, dynamic>?> createBorehole(Map<String, dynamic> data) async {
    try {
      _logger.i('Creating borehole: ${data['name'] ?? data['borehole_code']}');
      final response = await _dio.post(ApiConfig.boreholesEndpoint, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _getMapData(response.data);
      }
    } on DioException catch (e) {
      _logger.e('Error creating borehole', error: e);
      throw Exception(_extractApiErrorMessage(e));
    } catch (e) {
      _logger.e('Error creating borehole', error: e);
      rethrow;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getBoreholeAssignments(String boreholeId) async {
    try {
      _logger.i('Fetching borehole assignments: $boreholeId');
      final response = await _dio.get('${ApiConfig.boreholesEndpoint}/$boreholeId/assignments');
      if (response.statusCode == 200) {
        final data = _getListData(response.data);
        return data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      _logger.e('Error fetching borehole assignments', error: e);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getBoreholeSurveys(String boreholeId) async {
    try {
      _logger.i('Fetching borehole surveys: $boreholeId');
      final response = await _dio.get('${ApiConfig.boreholesEndpoint}/$boreholeId/surveys');
      if (response.statusCode == 200) {
        final data = _getListData(response.data);
        return data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      _logger.e('Error fetching borehole surveys', error: e);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getBoreholeRehabilitation(String boreholeId) async {
    try {
      _logger.i('Fetching borehole rehabilitation records: $boreholeId');
      final response = await _dio.get('${ApiConfig.boreholesEndpoint}/$boreholeId/rehabilitation');
      if (response.statusCode == 200) {
        final data = _getListData(response.data);
        return data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      _logger.e('Error fetching borehole rehabilitation records', error: e);
    }
    return [];
  }

  // ── Surveys ────────────────────────────────────────────────────────────────

  Future<SurveyModule?> getSurveyModule(String moduleCode) async {
    try {
      _logger.i('Fetching survey module: $moduleCode');

      final response = await _dio.get('${ApiConfig.formsEndpoint}/$moduleCode');

      if (response.statusCode == 200) {
        dynamic raw = response.data;
        if (raw is String) raw = jsonDecode(raw);
        if (raw is Map && raw.containsKey('data')) raw = raw['data'];
        final surveyModule = SurveyModule.fromJson(Map<String, dynamic>.from(raw as Map));
        _logger.i('Survey module fetched: ${surveyModule.name} (${surveyModule.sections.length} sections)');
        return surveyModule;
      }
    } catch (e) {
      _logger.e('Error fetching survey module', error: e);
    }
    return null;
  }

  Future<SurveySubmission?> submitSurvey(SurveySubmission submission) async {
    try {
      _logger.i('Submitting survey for borehole: ${submission.boreholId}');

      if (submission.surveyModuleId == 'grievance') {
        final rawCategory = submission.formData['category'];
        final category = rawCategory is List
            ? rawCategory.map((value) => value.toString()).join(', ')
            : rawCategory?.toString();
        final description = submission.formData['description']?.toString() ?? '';
        final supportingDetails = Map<String, dynamic>.from(submission.formData)
          ..remove('description');
        final response = await _dio.post(
          ApiConfig.grievancesEndpoint,
          data: {
            'borehole_id': submission.boreholId,
            'title': submission.formData['grievance_title'] ??
                submission.formData['title'] ??
                (category?.isNotEmpty == true ? category : 'Field grievance report'),
            'description': supportingDetails.isEmpty
                ? description
                : '$description\n\nSupporting details: ${jsonEncode(supportingDetails)}',
            'category': category,
            'priority': submission.formData['priority'] ?? 'medium',
          },
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          return SurveySubmission(
            boreholId: submission.boreholId,
            surveyModuleId: submission.surveyModuleId,
            formData: submission.formData,
            status: 'submitted',
          );
        }
        return null;
      }

      if (submission.surveyModuleId == 'water_testing') {
        final response = await _dio.post(
          ApiConfig.waterTestingEndpoint,
          data: {
            'borehole_id': submission.boreholId,
            'test_type': submission.formData['test_type'] ?? 'post_rehabilitation',
            'test_date': submission.formData['test_date'],
            'sample_collection_date': submission.formData['sample_collection_date'],
            'sample_code': submission.formData['sample_code'],
            'sample_description': submission.formData['sample_description'],
            'water_appearance': submission.formData['water_appearance'],
            'testing_remarks': submission.formData['testing_remarks'],
            'borehole_water_image_url': submission.formData['borehole_water_images'],
            'nearby_source_image_url': submission.formData['nearby_water_source_images'],
            'supporting_attachment_url': submission.formData['supporting_attachments'],
            'collected_by': submission.formData['collected_by'],
            'status': 'submitted',
          },
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          return SurveySubmission(
            boreholId: submission.boreholId,
            surveyModuleId: submission.surveyModuleId,
            formData: submission.formData,
            status: 'submitted',
          );
        }
        return null;
      }
      if (submission.surveyModuleId == 'rehabilitation') {
        final response = await _dio.post(
          ApiConfig.rehabilitationEndpoint,
          data: {
            'borehole_id': submission.boreholId,
            'stage': submission.formData['stage'] ?? 'pre_assessment',
            'status': submission.formData['status'] ?? 'completed',
            'start_date': submission.formData['start_date'],
            'end_date': submission.formData['end_date'],
            'description': submission.formData['activities_performed'] ??
                submission.formData['description'] ??
                jsonEncode(submission.formData),
          },
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          return SurveySubmission(
            boreholId: submission.boreholId,
            surveyModuleId: submission.surveyModuleId,
            formData: submission.formData,
            status: 'submitted',
          );
        }
        return null;
      }

      final response = await _dio.post(
        ApiConfig.submitSurveyEndpoint,
        data: {
          'borehole_id': submission.boreholId,
          'survey_module_id': submission.surveyModuleId,
          'form_data': submission.formData,
          if (submission.latitude != null) 'latitude': submission.latitude,
          if (submission.longitude != null) 'longitude': submission.longitude,
          'status': submission.status,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.i('Survey submitted successfully');
        return SurveySubmission(
          boreholId: submission.boreholId,
          surveyModuleId: submission.surveyModuleId,
          formData: submission.formData,
          status: 'submitted',
        );
      }
    } catch (e) {
      _logger.e('Error submitting survey', error: e);
    }
    return null;
  }

  // ── Water Testing ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getWaterTests(String boreholeId) async {
    try {
      _logger.i('Fetching water tests for borehole: $boreholeId');
      final response = await _dio.get(ApiConfig.waterTestingEndpoint, queryParameters: {'boreholeId': boreholeId});
      if (response.statusCode == 200) {
        final data = _getListData(response.data);
        return data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      _logger.e('Error fetching water tests', error: e);
    }
    return [];
  }

  Future<Map<String, dynamic>?> createWaterTest(
    String boreholeId,
    String sampleCode,
    String? vialPhotoUrl,
    {
    String testType = 'post_rehabilitation',
    String? testDate,
    String? sampleCollectionDate,
    String? sampleDescription,
    String? waterAppearance,
    String? testingRemarks,
    String? nearbySourceImageUrl,
    String? supportingAttachmentUrl,
    }
  ) async {
    try {
      _logger.i('Creating water test sample for borehole: $boreholeId');
      final response = await _dio.post(
        ApiConfig.waterTestingEndpoint,
        data: {
          'borehole_id': boreholeId,
          'test_type': testType,
          'test_date': testDate,
          'sample_collection_date': sampleCollectionDate,
          'sample_code': sampleCode,
          'sample_description': sampleDescription,
          'water_appearance': waterAppearance,
          'testing_remarks': testingRemarks,
          'borehole_water_image_url': vialPhotoUrl,
          'nearby_source_image_url': nearbySourceImageUrl,
          'supporting_attachment_url': supportingAttachmentUrl,
          'vial_photo_url': vialPhotoUrl,
          'status': 'submitted',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return _getMapData(response.data);
      }
    } catch (e) {
      _logger.e('Error creating water test', error: e);
    }
    return null;
  }

  // ── File Upload ────────────────────────────────────────────────────────────

  Future<String> uploadFile(String filePath) async {
    try {
      _logger.i('Uploading file: $filePath');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(ApiConfig.uploadFileEndpoint, data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic parsed = response.data;
        if (parsed is String) {
          try { parsed = jsonDecode(parsed); } catch (_) {}
        }
        String? fileUrl;
        if (parsed is Map) {
          final data = parsed['data'];
          fileUrl = (data is Map ? data['url'] : parsed['url']) as String?;
        }
        _logger.i('File uploaded: $fileUrl');
        return fileUrl ?? '';
      }
    } catch (e) {
      _logger.e('Error uploading file', error: e);
    }
    return '';
  }

  // ── FCM ────────────────────────────────────────────────────────────────────

  Future<bool> registerFcmToken(String token, {String? deviceInfo}) async {
    try {
      final data = <String, dynamic>{'token': token};
      if (deviceInfo != null) data['deviceInfo'] = deviceInfo;
      final response = await _dio.post(ApiConfig.fcmTokenEndpoint, data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _logger.e('Error registering FCM token', error: e);
      return false;
    }
  }

  Future<bool> unregisterFcmToken(String token) async {
    try {
      final response = await _dio.delete(ApiConfig.fcmTokenEndpoint, data: {'token': token});
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _logger.e('Error unregistering FCM token', error: e);
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _getMapData(dynamic responseData) {
    dynamic parsed = responseData;
    if (parsed is String) {
      try { parsed = jsonDecode(parsed); } catch (_) { return {}; }
    }
    if (parsed is Map) {
      if (parsed.containsKey('data') && parsed['data'] is Map) {
        return Map<String, dynamic>.from(parsed['data'] as Map);
      }
      return Map<String, dynamic>.from(parsed);
    }
    return {};
  }

  List<dynamic> _getListData(dynamic responseData) {
    dynamic parsed = responseData;
    if (parsed is String) {
      try { parsed = jsonDecode(parsed); } catch (_) { return []; }
    }
    if (parsed is Map) {
      final data = parsed['data'];
      if (data is List) return data;
      if (data is Map && data['data'] is List) return data['data'] as List;
      if (parsed['items'] is List) return parsed['items'] as List;
      if (parsed['records'] is List) return parsed['records'] as List;
      if (parsed['results'] is List) return parsed['results'] as List;
    }
    if (parsed is List) return parsed;
    return [];
  }

  // ── Token Management ───────────────────────────────────────────────────────

  Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  Future<bool> loadTokensFromStorage() async {
    try {
      _accessToken = await _secureStorage.read(key: 'access_token');
      _refreshToken = await _secureStorage.read(key: 'refresh_token');
      _logger.i('Tokens loaded from secure storage');
      return _accessToken != null && _refreshToken != null;
    } catch (e) {
      _logger.e('Error loading tokens', error: e);
      return false;
    }
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _accessToken != null;
}

// ── Logging Interceptor ────────────────────────────────────────────────────────

class LoggingInterceptor extends Interceptor {
  final Logger logger;
  LoggingInterceptor(this.logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.d(
      'REQUEST[${options.method}] => PATH: ${options.path}\n'
      'DATA: ${options.data}',
    );
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.d(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}\n'
      'MESSAGE: ${err.message}',
    );
    super.onError(err, handler);
  }
}
