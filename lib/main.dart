import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// PROVIDERS
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/leave_provider.dart';
import 'screens/leave/leave_screen.dart';
import 'providers/client_provider.dart';
import 'providers/correction_provider.dart';
import 'package:hris_mobile/providers/shift_provider.dart'; 
import 'package:hris_mobile/providers/recruitment_provider.dart';

// CORE & SCREENS
import 'core/theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/select_company_screen.dart';
import 'providers/department_provider.dart'; 
import 'providers/employee_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔴 Inisialisasi locale Indonesia (tanggal, intl)
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthProvider harus didaftarkan PERTAMA
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => DepartmentProvider()), 
        ChangeNotifierProvider(create: (_) => EmployeeProvider()), 
        ChangeNotifierProvider(create: (_) => ShiftProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => CorrectionProvider()),
        ChangeNotifierProvider(create: (_) => RecruitmentProvider()),

        // LeaveProvider butuh AuthProvider, jadi harus dibuat setelah AuthProvider tersedia
        ChangeNotifierProvider(
          create: (context) => LeaveProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'HR App',
            debugShowCheckedModeBanner: false,

            // 🔴 PAKSA LOCALE INDONESIA
            locale: const Locale('id', 'ID'),

            supportedLocales: const [
              Locale('id', 'ID'),
              Locale('en', 'US'),
            ],

            // 🔴 WAJIB untuk localization
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            initialRoute: '/',
            routes: {
              '/': (context) => const LoginScreen(),
              '/home': (context) => const MainScreen(),
            },

            onGenerateRoute: (settings) {
              if (settings.name == '/select-company') {
                final companies = settings.arguments as List;
                return MaterialPageRoute(
                  builder: (_) =>
                      SelectCompanyScreen(companies: companies),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}