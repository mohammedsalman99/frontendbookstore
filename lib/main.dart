import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/screens/Details/detailpage.dart';
import 'package:frontend/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open Hive box for downloads
  await Hive.openBox('downloads');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Readme',
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
