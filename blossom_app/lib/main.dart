import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mom\'s Salon',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE91E63),
            primary: const Color(0xFFE91E63), // Pink
            secondary: const Color(0xFF9C27B0), // Lavender/Purple
            surface: Colors.white,
            background: const Color(0xFFFFF0F5), // Lavender Blush
          ),
          scaffoldBackgroundColor: const Color(0xFFFFF0F5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFE91E63),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shadowColor: Colors.pink.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF9C27B0),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}