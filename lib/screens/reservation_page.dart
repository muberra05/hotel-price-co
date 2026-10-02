import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReservationPage extends StatefulWidget {
  final String hotelName;

  const ReservationPage({super.key, required this.hotelName});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  String? _roomType;
  int _guestCount = 1;

  final List<String> roomTypes = ['Single', 'Double', 'Suite'];

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  Future<void> _submitReservation() async {
    if (_checkInDate == null || _checkOutDate == null || _roomType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please complete all fields.')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('reservations').add({
      'userId': user?.uid,
      'email': user?.email,
      'hotel': widget.hotelName,
      'checkIn': _checkInDate,
      'checkOut': _checkOutDate,
      'roomType': _roomType,
      'guests': _guestCount,
      'createdAt': Timestamp.now(),
    });
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Reservation Created"),
            content: Text(
              "Hotel: ${widget.hotelName}\n"
              "Room Type: $_roomType\n"
              "Guests: $_guestCount\n"
              "Check-in: ${DateFormat('yyyy-MM-dd').format(_checkInDate!)}\n"
              "Check-out: ${DateFormat('yyyy-MM-dd').format(_checkOutDate!)}",
            ),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Make Reservation")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Hotel: ${widget.hotelName}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),

            Text("Check-in Date"),
            ElevatedButton(
              onPressed: () => _selectDate(context, true),
              child: Text(
                _checkInDate == null
                    ? "Select Date"
                    : DateFormat('yyyy-MM-dd').format(_checkInDate!),
              ),
            ),
            SizedBox(height: 16),

            Text("Check-out Date"),
            ElevatedButton(
              onPressed: () => _selectDate(context, false),
              child: Text(
                _checkOutDate == null
                    ? "Select Date"
                    : DateFormat('yyyy-MM-dd').format(_checkOutDate!),
              ),
            ),
            SizedBox(height: 16),

            Text("Room Type"),
            DropdownButton<String>(
              value: _roomType,
              hint: Text("Select Room Type"),
              isExpanded: true,
              items:
                  roomTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
              onChanged: (value) => setState(() => _roomType = value),
            ),
            SizedBox(height: 16),

            Text("Number of Guests"),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed:
                      _guestCount > 1
                          ? () => setState(() => _guestCount--)
                          : null,
                ),
                Text('$_guestCount'),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => setState(() => _guestCount++),
                ),
              ],
            ),
            SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submitReservation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Submit Reservation"),
            ),
          ],
        ),
      ),
    );
  }
}
