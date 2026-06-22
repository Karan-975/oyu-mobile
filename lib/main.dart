import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'services/api_service.dart';
import 'services/firebase_service.dart';
import 'services/offline_storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline storage box cache
  await OfflineStorageService().init();

  // Initialize API service
  final apiService = ApiService();

  // Initialize Firebase messaging & local notifications
  await FirebaseService().initialize(apiService);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => apiService),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(apiService: apiService),
        ),
        ChangeNotifierProvider<DataProvider>(
          create: (_) => DataProvider(apiService: apiService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OYU Green Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthenticationWrapper(),
      routes: {
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
