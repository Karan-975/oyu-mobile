import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/auth_models.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final Logger _logger = Logger();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  AuthProvider({required this._apiService}) {
    _apiService.onSessionExpired = () {
      _logger.w('Session expired callback received in AuthProvider');
      _user = null;
      _isAuthenticated = false;
      notifyListeners();
    };
    _initializeAuth();
  }

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // Initialize authentication from stored tokens
  Future<void> _initializeAuth() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final hasTokens = await _apiService.loadTokensFromStorage();
      if (hasTokens) {
        final user = await _apiService.getProfile();
        if (user != null) {
          final hasMobileRole = user.roles.any((role) =>
              role.name == 'ngo_team_member');
          if (hasMobileRole) {
            _user = user;
            _isAuthenticated = true;
            _logger.i('User authenticated: ${user.email}');
            FirebaseService().registerCurrentToken();
          } else {
            _logger.w('User ${user.email} does not have NGO member access. Clearing tokens.');
            await _apiService.clearTokens();
            _user = null;
            _isAuthenticated = false;
          }
        } else {
          await _apiService.clearTokens();
          _isAuthenticated = false;
        }
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      _logger.e('Auth initialization error', error: e);
      _error = 'Failed to initialize authentication';
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.login(email, password);
      
      final hasMobileRole = response.user.roles.any((role) =>
          role.name == 'ngo_team_member');

      if (!hasMobileRole) {
        await _apiService.clearTokens();
        _user = null;
        _isAuthenticated = false;
        _error = 'Access Denied: Mobile app is restricted to NGO Team Members.';
        notifyListeners();
        return false;
      }

      _user = response.user;
      _isAuthenticated = true;
      _error = null;
      
      _logger.i('Login successful for: ${response.user.email}');
      FirebaseService().registerCurrentToken();
      
      notifyListeners();
      return true;
    } catch (e) {
      _logger.e('Login error', error: e);
      _error = _extractErrorMessage(e);
      _isAuthenticated = false;
      _user = null;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _isLoading = true;
      await FirebaseService().deleteToken();
      await _apiService.logout();
      
      _user = null;
      _isAuthenticated = false;
      _error = null;
      
      _logger.i('Logout successful');
      notifyListeners();
    } catch (e) {
      _logger.e('Logout error', error: e);
      _error = _extractErrorMessage(e);
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    try {
      if (!_isAuthenticated) return;
      
      final user = await _apiService.getProfile();
      if (user != null) {
        _user = user;
        _logger.i('Profile refreshed');
      } else {
        await logout();
      }
    } catch (e) {
      _logger.e('Profile refresh error', error: e);
      _error = _extractErrorMessage(e);
    }
    notifyListeners();
  }

  // Check if user has specific role
  bool hasRole(String roleName) {
    if (_user == null) return false;
    return _user!.roles.any((role) => role.name == roleName);
  }

  // Check if user has any of the specified roles
  bool hasAnyRole(List<String> roleNames) {
    if (_user == null) return false;
    return _user!.roles
        .any((role) => roleNames.contains(role.name));
  }

  // Check if user is super admin
  bool get isSuperAdmin => hasRole('super_admin');

  // Check if user is NGO team member
  bool get isNgoTeamMember => hasRole('ngo_team_member');

  // Check if user is contractor
  bool get isContractorUser => false;

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
}
