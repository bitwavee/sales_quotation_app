import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/enquiry_provider.dart';
import 'providers/staff_provider.dart';
import 'providers/material_provider.dart';
import 'providers/measurement_provider.dart';
import 'providers/quotation_provider.dart';
import 'providers/file_provider.dart';
import 'providers/enquiry_progress_provider.dart';
import 'providers/enquiry_status_config_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/staff/staff_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EnquiryProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
        ChangeNotifierProvider(create: (_) => MaterialProvider()),
        ChangeNotifierProvider(create: (_) => MeasurementProvider()),
        ChangeNotifierProvider(create: (_) => QuotationProvider()),
        ChangeNotifierProvider(create: (_) => FileProvider()),
        ChangeNotifierProvider(create: (_) => EnquiryProgressProvider()),
        ChangeNotifierProvider(create: (_) => EnquiryStatusConfigProvider()),
      ],
      child: MaterialApp(
        title: 'Sales & Quotation',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/admin': (context) => const AdminDashboard(),
          '/staff': (context) => const StaffDashboard(),
        },
      ),
    );
  }
}