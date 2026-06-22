
// User model
class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? profileImage;
  final bool isActive;
  final List<Role> roles;
  final List<Permission> permissions;
  final DateTime createdAt;
  final String? ngoName;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.profileImage,
    required this.isActive,
    required this.roles,
    required this.permissions,
    required this.createdAt,
    this.ngoName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final List<Role> parsedRoles = [];
    final rawRoles = json['roles'] ?? json['role_slugs'] ?? json['role_names'];
    if (rawRoles is List) {
      for (var r in rawRoles) {
        if (r is String) {
          parsedRoles.add(Role(id: '', name: r));
        } else if (r is Map) {
          parsedRoles.add(Role.fromJson(Map<String, dynamic>.from(r)));
        }
      }
    }

    final List<Permission> parsedPermissions = [];
    final rawPermissions = json['permissions'] ?? json['permission_slugs'];
    if (rawPermissions is List) {
      for (var p in rawPermissions) {
        if (p is String) {
          parsedPermissions.add(Permission(id: '', name: p));
        } else if (p is Map) {
          parsedPermissions.add(Permission.fromJson(Map<String, dynamic>.from(p)));
        }
      }
    }

    // Set fullName safely if firstName and lastName exist
    String fullNameVal = json['full_name'] as String? ?? json['fullName'] as String? ?? '';
    if (fullNameVal.isEmpty && (json['firstName'] != null || json['first_name'] != null)) {
      final first = json['firstName'] as String? ?? json['first_name'] as String? ?? '';
      final last = json['lastName'] as String? ?? json['last_name'] as String? ?? '';
      fullNameVal = '$first $last'.trim();
    }

    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: fullNameVal,
      phone: json['phone'] as String?,
      profileImage: json['profile_image'] as String? ?? json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      roles: parsedRoles,
      permissions: parsedPermissions,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      ngoName: json['ngo_name'] as String? ?? json['ngoName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'profile_image': profileImage,
        'is_active': isActive,
        'roles': roles.map((r) => r.toJson()).toList(),
        'permissions': permissions.map((p) => p.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'ngo_name': ngoName,
      };
}

// Role model
class Role {
  final String id;
  final String name;
  final String? description;

  Role({
    required this.id,
    required this.name,
    this.description,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['role_name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

// Permission model
class Permission {
  final String id;
  final String name;
  final String? description;

  Permission({
    required this.id,
    required this.name,
    this.description,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

// Login request model
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

// Login response model
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String? ?? json['access_token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? json['refresh_token'] as String? ?? '',
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'user': user.toJson(),
      };
}

// Refresh token response
class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;

  RefreshTokenResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      accessToken: json['accessToken'] as String? ?? json['access_token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? json['refresh_token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
}

// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) => {
        'success': success,
        'message': message,
        if (data != null) 'data': toJsonT(data as T),
        if (error != null) 'error': error,
      };
}
