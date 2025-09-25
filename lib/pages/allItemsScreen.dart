import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:inventory_scanner/components.dart';

class AllItemsScreen extends StatelessWidget {
  const AllItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: SansText('All Items', 40.0), centerTitle: true),

      // ----- Firebase logic that pulls all data from allItems collection in Firestore -----
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('allItems')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No items found in inventory'));
          }

          final items = snapshot.data!.docs;

          // ----- Setting up the grid view for all items -----
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final data = items[index].data() as Map<String, dynamic>;
              final barcode = items[index].id;

              // ----- Dynamic card configuration for each item -----
              return Card(
                child: InkWell(
                  onTap: () {
                    _showItemDialog(context, barcode, data);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ----- Showing the image of the item, using the image URL from Firebase -----
                      if (data['imageUrl'] != null)
                        Expanded(
                          child: Image.network(
                            data['imageUrl'],
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        // ----- If not image is found, show a placeholder -----
                        Expanded(
                          child: Container(
                            color: Colors.grey[800],
                            alignment: Alignment.center,
                            child: const Icon(Icons.image, size: 50),
                          ),
                        ),
                      // ----- Item name, description and price -----
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? "Unnamed",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              data['description'] ?? "",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "\$${data['price'] ?? "0"}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ----- Dialog box that displays all of the selected item's details -----
  void _showItemDialog(
    BuildContext context,
    String barcode,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Item Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data['imageUrl'] != null)
                  Image.network(data['imageUrl'], height: 150),
                SizedBox(height: 10),
                Text('Barcode: $barcode'),
                SizedBox(height: 10),
                Text('Name: ${data['name']}'),
                Text("Description: ${data['description']}"),
                Text("Price: \$${data['price']}"),
              ],
            ),
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
}
