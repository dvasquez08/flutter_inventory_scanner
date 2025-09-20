import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

// --- Data Model ---
// Updated to include methods for Firestore data conversion
class Product {
  final String barcode;
  final String name;
  final String description;
  final String price;

  Product({
    required this.barcode,
    required this.name,
    required this.description,
    required this.price,
  });

  // Factory constructor to create a Product from a Firestore document
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Product(
      barcode: doc.id,
      name: data['name'] ?? 'No Name',
      description: data['description'] ?? 'No Description',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Method to convert a Product instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {'name': name, 'description': description, 'price': price};
  }
}

// --- Main App Entry Point ---
//Updated to initialize Firebase before running the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const InventoryScannerApp());
}

class InventoryScannerApp extends StatelessWidget {
  const InventoryScannerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Barcode Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0D47A1), // A deep, modern blue
        scaffoldBackgroundColor: const Color(
          0xFF121212,
        ), // Standard dark theme bg
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF42A5F5), // A vibrant blue for buttons/accents
          secondary: Color(0xFF90CAF9),
          surface: Color(0xFF1E1E1E), // For card backgrounds
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          color: const Color(0xFF1E1E1E),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF42A5F5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF42A5F5), width: 2),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

// Home Page: The entry point with the scan button --
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _scanBarcode() async {
    String barcodeScanRes;
    try {
      // --- Use the actual barcode scanner plugin ---
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#42A5F5',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );
      // If the user cancels, the result is '-1'.
      if (barcodeScanRes == '-1') {
        return;
      }
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get camera access.')),
      );
      return;
    }

    if (!mounted) return;

    // --- Live Firestore Logic ---
    // Get a reference to the Firestore document for the scanned barcode.
    final docRef = FirebaseFirestore.instance
        .collection('products')
        .doc(barcodeScanRes);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      // If the document exists, create a Product object from its data.
      final product = Product.fromFirestore(
        docSnap as DocumentSnapshot<Map<String, dynamic>>,
      );
      // Navigate to the details page.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProductDetailsPage(product: product),
        ),
      );
    } else {
      // If not found, show a dialog asking to add it.
      _showAddItemDialog(barcodeScanRes);
    }
  }

  void _showAddItemDialog(String barcode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: Theme.of(context).cardTheme.shape,
          title: const Text('Item Not Found'),
          content: Text(
            'The barcode "barcode" is not in the database. Would you like to add it as a new item?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Add Item'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddProductPage(barcode: barcode),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
