import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          ],
        ),
      ),
    );
  }
}
