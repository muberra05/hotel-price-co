/*
import 'package:flutter/material.dart';
import 'dormitory_video_call_page.dart';
//sunumda otel yerine yurt odfamı göstermek için bunu oluşturmuştum
//firestore bağlantısı kurarak

class DormitoryDetailPage extends StatelessWidget {
  final Map<String, dynamic> dorm;

  const DormitoryDetailPage({super.key, required this.dorm});

  @override
  Widget build(BuildContext context) {
    final name = dorm['property']?['name'] ?? 'Dormitory';
    final image =
        dorm['property']?['photoUrls']?[0] ?? 'https://via.placeholder.com/150';
    final distance = dorm['accessibilityLabel'] ?? 'Unknown';
    final price =
        dorm['property']?['priceBreakdown']?['grossPrice']?['value']
            ?.toString() ??
        'Not Available';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: const Color.fromRGBO(39, 70, 244, 1),
      ),
      body: Column(
        children: [
          // Görsel
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Image.network(
              image,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // TabBar ve Sekmeler  kısmı
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: "Information"),
                      Tab(text: "Live Appointment"),
                    ],
                    labelColor: Color.fromRGBO(39, 70, 244, 1),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color.fromRGBO(39, 70, 244, 1),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Information Tab ksımı
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "🏠 $name",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "📍 $distance",
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "💰 $price USD",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "⚠ This data is from Firestore and may be limited.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "General Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(39, 70, 244, 1),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('• Location: $distance'),
                              Text('• Price: $price USD'),
                            ],
                          ),
                        ),
                        // Live Appointment Tab ksımı
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              CreateLiveAppointmentPage(
                                                dormId: dorm['id'] ?? 'unknown',
                                                dormName: name,
                                              ), // Yurt adı çıkıyor
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromRGBO(
                                    39,
                                    70,
                                    244,
                                    1,
                                  ),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ), //detay sayfasında saağ tarafta bunlar çıkar
                                child: const Text("Create Live Appointment"),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Starting Live Tour..."),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    67,
                                    79,
                                    238,
                                  ),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text("Start Live Tour"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateLiveAppointmentPage extends StatefulWidget {
  final String dormId;
  final String dormName;

  const CreateLiveAppointmentPage({
    super.key,
    required this.dormId,
    required this.dormName,
  });

  @override
  _CreateLiveAppointmentPageState createState() =>
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
    if (picked != null && picked != _selectedDate) {
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
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
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
        title: const Text('Live Appointment Request'),
        backgroundColor: const Color.fromRGBO(39, 70, 244, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name (Optional)', // randevu oluşturmak içimn
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => _selectDate(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.grey),
              ),
              child: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _selectTime(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.grey),
              ),
              child: Text(
                _selectedTime == null
                    ? 'Select Time'
                    : _selectedTime!.format(context),
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_selectedDate == null || _selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select both date and time'),
                    ),
                  );
                  return;
                }
                // AlertDialog ile randevu oluştuysa mesaj gösterir
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text(
                        'Appointment Created',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hotel: ${widget.dormName}'), // Yurt adı burada
                          Text(
                            'Name: ${_nameController.text.isEmpty ? "Not Provided" : _nameController.text}',
                          ),
                          Text(
                            'Date: ${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                          ),
                          Text('Time: ${_selectedTime!.format(context)}'),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Dialogu kapat
                                Navigator.pop(context); // Sayfadan geri dön
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Starting Video Call...'),
                                  ),
                                );
                              },
                              child: const Text(
                                'Start Video Call',
                                style: TextStyle(
                                  color: Color.fromRGBO(39, 70, 244, 1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  },
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
