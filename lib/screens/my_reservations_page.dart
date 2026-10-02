import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

Future<void> _deleteReservation(String reservationId) async {
  await FirebaseFirestore.instance
      .collection('reservations')
      .doc(reservationId)
      .delete();
}

class MyReservationsPage extends StatelessWidget {
  const MyReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("My Reservations")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('reservations')
                .where('userId', isEqualTo: userId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Reservations Found."));
          }

          final reservations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final data = reservations[index].data() as Map<String, dynamic>;
              final checkIn = (data['checkIn'] as Timestamp).toDate();
              final checkOut = (data['checkOut'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(data['hotel'] ?? 'Unknown Hotel'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Room: ${data['roomType']}"),
                      Text("Guests: ${data['guests']}"),
                      Text(
                        "Check-in: ${DateFormat('yyyy-MM-dd').format(checkIn)}",
                      ),
                      Text(
                        "Check-out: ${DateFormat('yyyy-MM-dd').format(checkOut)}",
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _deleteReservation(reservations[index].id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Reservation deleted")),
                      );
                    },
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
