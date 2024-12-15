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
      primarySwatch: Colors.teal,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.teal,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black), 
        bodyMedium: TextStyle(color: Colors.black54), 
        titleLarge: TextStyle(color: Colors.black), 
      ),
      cardColor: Colors.white,
      dividerColor: Colors.grey,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.teal,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black54,
      ),
    );

    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.teal,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.teal,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white), 
        bodyMedium: TextStyle(color: Colors.white70), 
        titleLarge: TextStyle(color: Colors.white),
      ),
      cardColor: Colors.grey[900], 
      dividerColor: Colors.white24, 
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.teal,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
      ),
    );


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Readme',
      theme: lightTheme, 
      darkTheme: darkTheme, 
      themeMode: themeProvider.themeMode, 
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/detail')) {
          final uri = Uri.parse(settings.name!);
          final bookId = uri.queryParameters['bookId'];

          if (bookId != null) {
            return MaterialPageRoute(
              builder: (context) => DetailPage(bookId: bookId),
            );
          }
        }
        return MaterialPageRoute(
          builder: (context) => SplashScreen(),
        );
      },
    );
  }
}
