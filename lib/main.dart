import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/screens/setting/theme_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:frontend/screens/Details/detailpage.dart';
import 'package:frontend/splash.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox('downloads');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Handle dynamic routing for detail pages
        if (settings.name != null && settings.name!.startsWith('/detail')) {
          final uri = Uri.parse(settings.name!);
          final bookId = uri.queryParameters['bookId'];

          if (bookId != null) {
            return MaterialPageRoute(
              builder: (context) => DetailPage(bookId: bookId),
            );
          }
        }

        // Default route to SplashScreen
        return MaterialPageRoute(
          builder: (context) => SplashScreen(),
        );
      },
    );
  }
}
