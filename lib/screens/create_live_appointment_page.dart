/*import 'package:flutter/material.dart';
import 'dormitory_video_call_page.dart';
import 'dart:async';

class CreateLiveAppointmentPage extends StatefulWidget {
  final String dormId;
  final String dormName;

  const CreateLiveAppointmentPage({
    Key? key,
    required this.dormId,
    required this.dormName,
  }) : super(key: key);

  @override
  State<CreateLiveAppointmentPage> createState() =>
      _CreateLiveAppointmentPageState();
}

class _CreateLiveAppointmentPageState extends State<CreateLiveAppointmentPage> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _startVideoCall(BuildContext context) async {
    final name =
        _nameController.text.trim().isEmpty
            ? "Not Provided"
            : _nameController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DormitoryVideoCallPage(
              dormId: widget.dormId,
              dormName: widget.dormName,
              userName: name,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Live Appointment'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name (optional)', //
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => _selectDate(context),
              child: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
            OutlinedButton(
              onPressed: () => _selectTime(context),
              child: Text(
                _selectedTime == null
                    ? 'Select Time'
                    : _selectedTime!.format(context),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_selectedDate == null || _selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please select both date and time',
                      ), // tarih ve saat seçeriz
                    ),
                  );
                  return;
                }

                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text('Appointment Created'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dormitory: ${widget.dormName}'),
                            Text(
                              'Name: ${_nameController.text.trim().isEmpty ? "Not Provided" : _nameController.text}',
                            ),
                            Text(
                              'Date: ${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                            ),
                            Text('Time: ${_selectedTime!.format(context)}'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pop(); // Alert dialog kapanıyor
                              _startVideoCall(
                                context,
                              ); // burada video call başlatılıyor
                            },
                            child: const Text('Start Video Call'),
                          ),
                        ],
                      ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(39, 70, 244, 1),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
*/
