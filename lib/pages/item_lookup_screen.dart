import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../components.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: ItemLookupScreen()));
}

class ItemLookupScreen extends StatefulWidget {
  const ItemLookupScreen({super.key});

  @override
  State<ItemLookupScreen> createState() => _ItemLookupScreenState();
}

class _ItemLookupScreenState extends State<ItemLookupScreen> {
  String barcode = "";

  Future<void> _openScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (result != null && result is String) {
      setState(() => barcode = result);
      _lookupItem(result);
    }
  }

  Future<void> _lookupItem(String scannedBarcode) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('allItems')
          .doc(scannedBarcode)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _showItemDialog(scannedBarcode, data);
      } else {
        _showNotFoundDialog(scannedBarcode);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showItemDialog(String barcode, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Item Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Barcode: $barcode'),
              SizedBox(height: 8),
              Text('Name: ${data["name"]}'),
              Text('Description: ${data["description"]}'),
              Text('Price: ${data["price"]}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showNotFoundDialog(String scannedBarcode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Item Not Found'),
          content: const Text(
            'No item was found for this barcode. Would you like to add it to inventory?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddItemDialog(scannedBarcode);
              },
              child: const Text('Add Item'),
            ),
          ],
        );
      },
    );
  }

  void _showAddItemDialog(String scannedBarcode) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Barcode: $scannedBarcode'),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                final price = priceController.text.trim();

                if (name.isEmpty || description.isEmpty || price.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('allItem')
                      .doc(scannedBarcode)
                      .set({
                        'name': name,
                        'description': description,
                        'price': price,
                      });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item added successfully')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // These variables capture the device's screen dimensions.
    // They are used here for adjusting the size of containers and adding responsiveness.
    var heightDevice = MediaQuery.of(context).size.height;
    var widthDevice = MediaQuery.of(context).size.width;
    return Scaffold(
      // ----- App bar and title section -----
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        title: Text(
          'Item Lookup',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w300),
        ),
        centerTitle: true,
      ),

      // ----- Main content of the item lookup screen -----
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 170),
            SansText('Check Inventory Item', 40.0),
            SizedBox(height: 15),
            SansText('Scan barcode to lookup item', 25.0),
            SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _openScanner,
              icon: const Icon(Icons.barcode_reader),
              label: const Text('Scan Barcode'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----- Fullscreen barcode scanner -----
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isScanned = false;

  void _handleBarcode(BarcodeCapture capture) {
    if (_isScanned) return;
    final value = capture.barcodes.first.rawValue;
    if (value != null) {
      setState(() => _isScanned = true);
      Navigator.pop(context, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan Barcode',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: MobileScanner(onDetect: _handleBarcode),
    );
  }
}
