import 'dart:convert';
import 'dart:io';

// Firebase Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
// Flutter Imports
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
// Package Imports for image uploading and barcode scanning
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Importing the dart file that contains reusable functions
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

  // ----- Opens barcode scanner and triggers the item lookup if item is found -----
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

  // Looks up the item in the Firestore database. If found, it brings up the item.
  // If the item is not found, it asks if you want to add by triggering the itemNotFound dialog
  Future<void> _lookupItem(String scannedBarcode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('allItems')
          .doc(scannedBarcode)
          .get();

      Navigator.pop(context); // Close loading spinner

      if (doc.exists) {
        _showItemDialog(scannedBarcode, doc.data()!);
      } else {
        _showNotFoundDialog(scannedBarcode);
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
  // ----- The dialog box that opens the item information when a barcode is scanned -----

  void _showItemDialog(String barcode, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Item Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['imageUrl'] != null)
                  Image.network(data['imageUrl'], height: 150),
                const SizedBox(height: 8),
                Text('Barcode: $barcode'),
                const SizedBox(height: 8),
                Text('Name: ${data["name"]}'),
                Text('Description: ${data["description"]}'),
                Text('Price: \$${data["price"]}'),
              ],
            ),
          ),
          actions: [
            // ----- Edit Item Button -----
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditItemDialog(barcode, data);
              },
              child: const Text('Edit'),
            ),

            // ----- Delete Item Button -----
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Delete Item?'),
                      content: const Text(
                        'Are you sure you want to delete this item? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  // Delete from Firestore
                  await FirebaseFirestore.instance
                      .collection('allItems')
                      .doc(barcode)
                      .delete();

                  // Optionally delete image from Storage
                  if (data['imageUrl'] != null) {
                    try {
                      final ref = FirebaseStorage.instance.refFromURL(
                        data['imageUrl'],
                      );
                      await ref.delete();
                    } catch (e) {
                      debugPrint("Image delete failed: $e");
                    }
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Item deleted')));
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),

            // ----- Check eBay Button -----
            TextButton(
              onPressed: () {
                _fetchEbayData(
                  context,
                  data['name'] ?? '',
                  data['description'] ?? '',
                  barcode,
                );
              },
              child: const Text('Check eBay'),
            ),

            // ----- Close Dialog Box Button -----
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ----- Opens the dialog box that allows for editing the fields and image of the existing item -----
  void _showEditItemDialog(String barcode, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name']);
    final descriptionController = TextEditingController(
      text: data['description'],
    );
    final priceController = TextEditingController(text: data['price']);
    File? selectedImage;
    String? existingImageUrl = data['imageUrl'];

    // Opens camera or gallery for image selection inside the edit dialog.
    Future<void> _pickImage(ImageSource source, StateSetter setState) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          selectedImage = File(pickedFile.path);
          existingImageUrl = null; // Replace existing image
        });
      }
    }

    // Uploads selected image to Firebase Storage and returns its download URL.
    Future<String?> _uploadImage(File imageFile, String barcode) async {
      try {
        final storageRef = FirebaseStorage.instance.ref().child(
          'item_images/$barcode.jpg',
        );
        await storageRef.putFile(imageFile);
        return await storageRef.getDownloadURL();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
        return null;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Barcode: $barcode'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    if (selectedImage != null)
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.file(selectedImage!, height: 120),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                setState(() => selectedImage = null),
                          ),
                        ],
                      )
                    else if (existingImageUrl != null)
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.network(existingImageUrl!, height: 120),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                setState(() => existingImageUrl = null),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _pickImage(ImageSource.camera, setState),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _pickImage(ImageSource.gallery, setState),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ],
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
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    String? imageUrl = existingImageUrl;
                    if (selectedImage != null) {
                      imageUrl = await _uploadImage(selectedImage!, barcode);
                    }

                    await FirebaseFirestore.instance
                        .collection('allItems')
                        .doc(barcode)
                        .update({
                          'name': name,
                          'description': description,
                          'price': price,
                          'imageUrl': imageUrl,
                        });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item updated successfully'),
                      ),
                    );
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Shows a dialog when no item is found and offers to add a new one.
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

  // ----- Function that fetches the item information from eBay -----
  Future<void> _fetchEbayData(
    BuildContext context,
    String name,
    String description,
    String barcode,
  ) async {
    // Replace with your n8n webhook URL
    const webhookUrl = 'https://your-n8n-instance/webhook/ebay-lookup';

    try {
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'description': description,
          'barcode': barcode,
        }),
      );

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body);

        // Show the results in a new dialog
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("eBay Results"),
              content: SizedBox(
                width: double.maxFinite,
                child: results.isEmpty
                    ? const Text("No results found.")
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return Card(
                            child: ListTile(
                              leading: item['imageUrl'] != null
                                  ? Image.network(
                                      item['imageUrl'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.image_not_supported),
                              title: Text(item['title'] ?? 'No Title'),
                              subtitle: Text("Price: \$${item['price']}"),
                              onTap: () {
                                // If n8n returns a link to the listing, open it
                                if (item['url'] != null) {}
                              },
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      } else {
        throw Exception("Failed to fetch eBay data");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching eBay data: $e")));
    }
  }

  void _showAddItemDialog(String scannedBarcode) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    File? selectedImage;

    // ----- The function that allows you to upload from gallery or take picture with camera -----
    Future<void> _pickImage(ImageSource source) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          selectedImage = File(pickedFile.path);
        });
      }
    }

    // Uploads image for new item and returns the Firebase Storage URL.
    Future<String?> _uploadImage(File imageFile, String barcode) async {
      try {
        final storageRef = FirebaseStorage.instance.ref().child(
          'item_images/$barcode.jpg',
        );

        // Upload the file to Firebase Storage
        final uploadTask = await storageRef.putFile(imageFile);

        // Get the public download URL
        final downloadUrl = await storageRef.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
        return null;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 10),
                    if (selectedImage != null)
                      Image.file(selectedImage!, height: 120),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ],
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

                    if (name.isEmpty ||
                        description.isEmpty ||
                        price.isEmpty ||
                        selectedImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields'),
                        ),
                      );
                      return;
                    }

                    final imageUrl = await _uploadImage(
                      selectedImage!,
                      scannedBarcode,
                    );

                    if (imageUrl != null) {
                      await FirebaseFirestore.instance
                          .collection('allItems')
                          .doc(scannedBarcode)
                          .set({
                            'name': name,
                            'description': description,
                            'price': price,
                            'imageUrl': imageUrl,
                          });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Item added successfully'),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
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
      body: SingleChildScrollView(
        child: Container(
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
