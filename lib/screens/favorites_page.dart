import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  final String userId = 'user123';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Geri git
          },
        ),
        title: const Text('Favorites'),
        backgroundColor: const Color.fromRGBO(39, 70, 244, 1),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('FAVORITES')
                .doc(userId)
                .collection('hotels')
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = snapshot.data!.docs;

          if (favorites.isEmpty) {
            return const Center(child: Text("No favorites yet."));
          }

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final data = favorites[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: Image.network(
                    data['photo'],
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(data['name'] ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('\$${data['price']} USD'),
                      Text('📍 ${data['distance']}'),
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
}
