import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/screens/setting/theme_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:frontend/screens/Details/detailpage.dart';
import 'package:frontend/splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox('downloads');

  final String? lastRoute = await _getLastVisitedRoute();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(initialRoute: lastRoute),
    ),
  );
}

Future<String?> _getLastVisitedRoute() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('last_route') ?? '/';
}

Future<void> _saveLastVisitedRoute(String route) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_route', route);
}

class MyApp extends StatelessWidget {
  final String? initialRoute;

  const MyApp({Key? key, this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
    );

    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Readme',
      theme: lightTheme, // Default light theme
      darkTheme: darkTheme, // Default dark theme
      themeMode: themeProvider.themeMode, // Dynamic theme switching
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        // Handle dynamic routing for detail pages
        if (settings.name != null && settings.name!.startsWith('/detail')) {
          final uri = Uri.parse(settings.name!);
          final bookId = uri.queryParameters['bookId'];

          if (bookId != null) {
            return MaterialPageRoute(
              builder: (context) => DetailPage(bookId: bookId),
              settings: RouteSettings(name: settings.name),
            );
          }
        }

        // Default route to SplashScreen
        return MaterialPageRoute(
          builder: (context) => SplashScreen(),
          settings: RouteSettings(name: '/'),
        );
      },
      navigatorObservers: [
        RouteObserver<PageRoute>(),
        _RouteObserver(),
      ],
    );
  }
}

class _RouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPopNext(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _saveLastVisitedRoute(route.settings.name ?? '/');
  }

  @override
  void didPushNext(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _saveLastVisitedRoute(previousRoute?.settings.name ?? '/');
  }
}
