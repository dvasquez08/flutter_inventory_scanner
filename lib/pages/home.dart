import 'package:flutter/material.dart';
import 'package:inventory_scanner/components.dart';
import 'package:inventory_scanner/pages/add_item_screen.dart';
import 'package:inventory_scanner/pages/item_lookup_screen.dart';

// ----- Main entry point for this page -----
void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

// ----- Reusable action card widget for the home screen -----
class ActionCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final IconData icon;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.title,
    required this.subTitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SansText(title, 20.0),
                    SizedBox(height: 4),
                    SansText(subTitle, 14.0),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ----- App bar and title section -----
      appBar: AppBar(
        title: SansText('Inventory Dashboard', 40.0),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // ----- The body of the scaffold that contains the main content of the screen -----
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              SansText('Welcome', 28.0),
              SansText('What would you like to do?', 32.0),
              SizedBox(height: 40),

              // ----- ActionCard for addind items -----
              ActionCard(
                title: 'Add New Item',
                subTitle: 'Scan a barcode to add a new item',
                icon: Icons.add_to_photos_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddItemScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              // ------ ActionCard for looking up items -----
              ActionCard(
                title: 'Lookup Item',
                subTitle: 'Scan a barcode to view or edit details',
                icon: Icons.search_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ItemLookupScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
