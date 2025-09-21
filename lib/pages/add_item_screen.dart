import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../components.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: AddItemScreen()));
}

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  String barcode = "";
  String name = "";
  String description = "";
  String price = "";

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
        title: Text('Add Item to Inventory'),
        centerTitle: true,
      ),

      // ----- Main content of the screen -----
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 170),
            SansText('Add Item to Inventory', 40.0),
            SizedBox(height: 15),
            SansText('Scan barcode to add item to inventory', 25.0),
            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
