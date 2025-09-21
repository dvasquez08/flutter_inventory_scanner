import 'package:cloud_firestore/cloud_firestore.dart';
// --- Additions for Firebase and Barcode Scanning ---
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

// --- Data Model ---
// Updated to include methods for Firestore data conversion.
class Product {
  final String barcode;
  final String name;
  final String description;
  final double price;

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
// Updated to initialize Firebase before running the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // --- Initialize Firebase ---
  await Firebase.initializeApp();
  runApp(const BarcodeScannerApp());
}

class BarcodeScannerApp extends StatelessWidget {
  const BarcodeScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Barcode Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0D47A1),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF42A5F5),
          secondary: Color(0xFF90CAF9),
          surface: Color(0xFF1E1E1E),
        ),
        cardTheme: CardThemeData(
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

// --- Home Page: The entry point with the scan button ---
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
      final product = Product.fromFirestore(docSnap);
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
            'The barcode "$barcode" is not in the database. Would you like to add it as a new item?',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Scanner')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(
                Icons.qr_code_scanner_rounded,
                size: 120.0,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 40),
              const Text(
                'Ready to Scan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Press the button below to start scanning an item\'s barcode.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Scan Barcode'),
                onPressed: _scanBarcode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Product Details Page: Displays info for an existing item ---
class ProductDetailsPage extends StatelessWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for an item image
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black,
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://placehold.co/600x400/1E1E1E/FFFFFF?text=Item+Image',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Center(
                child: Icon(Icons.image, color: Colors.white30, size: 50),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              product.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text('Barcode: ${product.barcode}'),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white12),
            const SizedBox(height: 24),
            _buildInfoCard(
              context,
              icon: Icons.description_rounded,
              title: 'Description',
              content: product.description,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              icon: Icons.attach_money_rounded,
              title: 'Price',
              content: '\$${product.price.toStringAsFixed(2)}',
              isPrice: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    bool isPrice = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.secondary,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: isPrice ? 24 : 18,
                      fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Add Product Page: A form to add a new item to the database ---
class AddProductPage extends StatefulWidget {
  final String barcode;

  const AddProductPage({super.key, required this.barcode});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      // Create a new Product instance from the form data.
      final newProduct = Product(
        barcode: widget.barcode,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
      );

      // --- Live Firestore Logic ---
      // Add the new product data to Firestore, using the barcode as the document ID.
      try {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.barcode)
            .set(newProduct.toFirestore());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text} added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to the home screen.
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Barcode: ${widget.barcode}',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              _buildTextFormField(
                controller: _nameController,
                labelText: 'Item Name',
                icon: Icons.label_important_outline_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _descriptionController,
                labelText: 'Description',
                icon: Icons.description_outlined,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _priceController,
                labelText: 'Price',
                icon: Icons.attach_money_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_rounded),
                label: const Text('Save Item'),
                onPressed: _saveItem,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.white60),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }
}
