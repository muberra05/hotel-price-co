import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore için

import 'auth_page.dart';

class LiveAppointmentPage extends StatefulWidget {
  final String hotelName;

  const LiveAppointmentPage({super.key, required this.hotelName});

  @override
  _LiveAppointmentPageState createState() => _LiveAppointmentPageState();
}

class _LiveAppointmentPageState extends State<LiveAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<bool> ensureLoggedIn(BuildContext context) async {
    if (FirebaseAuth.instance.currentUser != null) return true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder:
              (_, scrollController) =>
                  AuthPage(scrollController: scrollController),
        );
      },
    );

    return FirebaseAuth.instance.currentUser != null;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitForm() async {
    bool isLoggedIn = await ensureLoggedIn(context);
    if (!isLoggedIn) return;

    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null) {
      final user = FirebaseAuth.instance.currentUser;

      // Firestore'a randevu kaydı oluşur
      // 1. Kanal adı üret
      String channelName =
          "ch_" + DateTime.now().millisecondsSinceEpoch.toString();
      print(
        "Hotel name written to Firestore: ${widget.hotelName.trim().toLowerCase()}", //aldığım hatanın sebebini terminalde almak için kullandım
      );

      //  2. Firestore'a randevu kaydı (KANAL ADI EKLENDİ)
      await FirebaseFirestore.instance.collection('appointments').add({
        'userId': user?.uid,
        'email': user?.email,
        'name': _nameController.text,
        'hotel': widget.hotelName.trim().toLowerCase(),
        'date': _selectedDate!.toIso8601String(),
        'time': _selectedTime!.format(context),
        'channelName': channelName, //  BU SATIR EKSTRA ekledim
        'createdAt': FieldValue.serverTimestamp(),
      });

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Appointment Created"),
            content: Text(
              "Hotel: ${widget.hotelName}\n"
              "Name: ${_nameController.text.isEmpty ? 'Not provided' : _nameController.text}\n"
              "Date: ${_selectedDate.toString().split(' ')[0]}\n"
              "Time: ${_selectedTime!.format(context)}",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Appointment Request")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Your Name (Optional)",
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectDate,
                child: Text(
                  _selectedDate == null
                      ? "Select Date"
                      : _selectedDate.toString().split(' ')[0],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _selectTime,
                child: Text(
                  _selectedTime == null
                      ? "Select Time"
                      : _selectedTime!.format(context),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text("Submit Appointment"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
