import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventory_scanner/pages/Home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const InventoryScanner());
}

class InventoryScanner extends StatelessWidget {
  const InventoryScanner({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF0D47A1);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventory Scanner',
      theme: ThemeData(
        brightness: Brightness.dark,
        // ----- This will be the main color for theme consistency -----
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        // ----- The default font for the entire app -----
        textTheme: GoogleFonts.openSansTextTheme(ThemeData.dark().textTheme),
        // ----- Style for all elevated buttons ------
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: seedColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // ----- Style for all text form field decorations -----
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: seedColor),
          ),
        ),
        // ----- Style for the cards used on all pages -----
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const Home(),
    );
  }
}
