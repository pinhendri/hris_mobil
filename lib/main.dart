import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// PROVIDERS
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/leave_provider.dart';
import 'providers/event_provider.dart';
import 'providers/client_provider.dart';
import 'providers/correction_provider.dart';
import 'package:hris_mobile/providers/shift_provider.dart';
import 'package:hris_mobile/providers/recruitment_provider.dart';
import 'package:hris_mobile/providers/saas_provider.dart';

// CORE & SCREENS
import 'core/theme/app_theme.dart';
import 'screens/app_bootstrap_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/select_company_screen.dart';
import 'providers/department_provider.dart';
import 'providers/employee_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize date formatting for supported app locales.
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('en_US', null);

  final languageProvider = LanguageProvider(loadOnInit: false);
  await languageProvider.loadSavedLanguage();
  final themeProvider = ThemeProvider(loadOnInit: false);
  await themeProvider.loadSavedTheme();

  runApp(
    MyApp(languageProvider: languageProvider, themeProvider: themeProvider),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.languageProvider,
    required this.themeProvider,
  });

  final LanguageProvider languageProvider;
  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthProvider harus didaftarkan PERTAMA
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => DepartmentProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => ShiftProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => CorrectionProvider()),
        ChangeNotifierProvider(create: (_) => RecruitmentProvider()),
        ChangeNotifierProvider(create: (_) => SaasProvider()),

        // LeaveProvider butuh AuthProvider, jadi harus dibuat setelah AuthProvider tersedia
        ChangeNotifierProvider(
          create: (context) =>
              LeaveProvider(Provider.of<AuthProvider>(context, listen: false)),
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, _) {
          return MaterialApp(
            title: 'HR App',
            debugShowCheckedModeBanner: false,
            locale: languageProvider.locale,
            supportedLocales: LanguageProvider.supportedLocales,

            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            routes: {
              '/': (context) => const AppBootstrapScreen(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const MainScreen(),
            },

            onGenerateRoute: (settings) {
              if (settings.name == '/select-company') {
                final companies = settings.arguments as List;
                return MaterialPageRoute(
                  builder: (_) => SelectCompanyScreen(companies: companies),
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
