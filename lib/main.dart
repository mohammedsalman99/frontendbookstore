import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/Details/detailpage.dart';
import 'package:frontend/splash.dart';
import 'package:frontend/providers/ continue_books_provider.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContinueBooksProvider()),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
