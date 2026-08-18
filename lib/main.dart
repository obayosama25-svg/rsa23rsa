import 'package:sudacards/theme/app_colors.dart';
import 'package:sudacards/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_links/app_links.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/payment_confirm_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // منطق مسح البيانات القديمة (مرة واحدة فقط) لضمان التوافق مع التعديلات الجديدة
  final prefs = await SharedPreferences.getInstance();
  bool mappingDone = prefs.getBool('data_structure_updated_v2') ?? false;

  if (!mappingDone) {
    await DatabaseService().clearAll();
    await prefs.clear(); // مسح الـ Preferences أيضاً
    await prefs.setBool('data_structure_updated_v2', true);
    debugPrint('[SYSTEM] تمت تهيئة البيانات القديمة لضمان التوافق ✅');
  }

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Check initial link if app was cold-started
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) _handleLink(uri);
    });

    // Listen to links while app is running or in background
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    if (uri.scheme == 'sudacard' && uri.host == 'invoice') {
      final id = uri.queryParameters['id'];
      if (id != null && id.isNotEmpty) {
        // We use a delayed push so the navigator has time to build first
        Future.delayed(const Duration(milliseconds: 500), () {
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => PaymentConfirmScreen(invoiceId: id),
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'سوداكارد',
          themeMode: currentMode,

          // Light Theme Definition
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.lightBackground,
            primaryColor: AppColors.primaryBlue,
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              secondary: AppColors.primaryGreen,
              surface: AppColors.lightSurface,
              error: AppColors.errorRed,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: AppColors.textDark),
              bodyMedium: TextStyle(color: AppColors.textDark),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Dark Theme Definition
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.darkBackground,
            primaryColor: AppColors.primaryGreen,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryGreen,
              secondary: AppColors.primaryBlue,
              surface: AppColors.darkSurface,
              error: AppColors.errorRed,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: AppColors.textPremium),
              bodyMedium: TextStyle(color: AppColors.textDimmed),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Arabic RTL Config
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar', 'AE')],
          locale: const Locale('ar', 'AE'),
          home: const SplashScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        );
      },
    );
  }
}
