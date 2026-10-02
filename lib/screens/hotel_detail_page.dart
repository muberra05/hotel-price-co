import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'live_appointment_page.dart';
import 'package:hotel/screens/video_call_page.dart';
import 'reservation_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HotelDetailPage extends StatefulWidget {
  final Map<String, dynamic> hotel;

  const HotelDetailPage({super.key, required this.hotel});

  @override
  _HotelDetailPageState createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  int selectedButtonIndex = -1;
  String? _channelName;
  bool _isChannelLoading = false;
  @override
  void initState() {
    super.initState();
    _fetchLatestChannelName(); // firestoredan canlı görüşme için Kanal verisini alırız.
  }

  Future<void> _fetchLatestChannelName() async {
    setState(() {
      _isChannelLoading = true;
    });
    final normalizedName =
        (widget.hotel['property']?['name'] ??
                widget.hotel['hotel_name'] ??
                'Hotel')
            .toString()
            .trim()
            .toLowerCase();
    print("Sorgulanan otel adi: $normalizedName");

    final snapshot =
        await FirebaseFirestore.instance
            .collection('appointments')
            .where('hotel', isEqualTo: normalizedName)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _channelName = snapshot.docs.first['channelName'];
      });
    }

    setState(() {
      _isChannelLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;

    final String hotelName =
        hotel['property']?['name'] ?? hotel['hotel_name'] ?? 'Hotel';

    final List<String> photos =
        hotel['property']?['photoUrls']?.cast<String>() ?? [];

    final String city =
        hotel['city']?.toString() ??
        hotel['property']?['location']?['city'] ??
        'Unknown';

    final String price =
        hotel['property']?['priceBreakdown']?['grossPrice']?['value']
            ?.toString() ??
        'Not Available';

    final String distance =
        RegExp(
          r'(\d+(\.\d+)?)\s?km',
        ).firstMatch(hotel['accessibilityLabel'] ?? '')?.group(0) ??
        'Unknown distance';

    final double reviewScore =
        double.tryParse(
          hotel['property']?['reviewScore']?.toString() ?? '0.0',
        ) ??
        0.0;

    final String? rawStar =
        hotel['property']?['accuratePropertyClass']?.toString() ??
        hotel['property']?['starRating']?.toString();

    final double starRating = double.tryParse(rawStar ?? '0.0') ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(hotelName), //bu kısım otel bilgilerini gösteriyor
        backgroundColor: const Color.fromRGBO(39, 70, 244, 1),
      ),
      body: Column(
        children: [
          CarouselSlider(
            //otelin fotoğraflarını getirmek için
            items:
                photos.map((url) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
            options: CarouselOptions(
              height: 250.0,
              enlargeCenterPage: true,
              autoPlay: true,
            ),
          ),
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
                    labelColor: Colors.blueAccent,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blueAccent,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hotelName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  RatingBarIndicator(
                                    rating: starRating,
                                    itemCount: 5,
                                    itemSize: 20.0,
                                    itemBuilder:
                                        (context, _) => const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${starRating.toStringAsFixed(1)} Stars',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '⭐ ${reviewScore.toStringAsFixed(1)} / 10',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "General Information",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('• Location: $city'),
                              Text('• Distance: $distance from center'),
                              const SizedBox(height: 16),
                              const Text(
                                "Booking Details",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('• Price: \$${price} USD'),
                              Text('• Check-in: 15:00'),
                              Text('• Check-out: 12:00'),
                              const SizedBox(height: 16),

                              // ➕ Eklenen detaylı içerik burası
                              const Text(
                                "Hotel Facilities",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("• Café"),
                              Text("• Lobby"),
                              Text("• Fast Check-in / Check-out"),
                              Text("• Elevator"),
                              Text("• Parking"),
                              Text("• Terrace"),
                              Text("• Hotel Bar"),
                              Text("• Pool Bar"),
                              Text("• Outdoor Swimming Pool"),
                              Text("• Conference Rooms"),
                              Text("• Non-smoking Rooms"),
                              Text("• Restaurant"),
                              Text("• 24-hour Reception"),
                              Text("• Snack Bar"),
                              Text("• Laundry Service"),
                              Text("• Shared Wi-Fi"),
                              Text("• Room Service"),
                              Text("• 24-Hour Room Service"),
                              Text("• Washing Machine"),
                              Text("• Fax/Modem Access"),
                              Text("• Hotel Doctor"),
                              Text("• Car Rental"),
                              Text("• Concierge"),
                              Text("• Airport Shuttle"),
                              Text("• Free Wi-Fi (common areas)"),
                              Text("• Pool"),
                              Text("• Luggage Storage"),
                              Text("• Daily Housekeeping"),
                              Text("• Free Wi-Fi"),
                              Text("• Breakfast"),
                              Text("• Children's Pool"),
                              const SizedBox(height: 16),

                              const Text(
                                "Room Features",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("• Balcony"),
                              Text("• Shower"),
                              Text("• Ironing Board"),
                              Text("• Openable Windows"),
                              Text("• Television"),
                              Text("• Hair Dryer"),
                              Text("• Central Heating"),
                              Text("• Air Conditioning"),
                              Text("• Makeup Mirror"),
                              Text("• Mini Bar"),
                              Text("• Satellite TV"),
                              Text("• Seating Area"),
                              Text("• Telephone"),
                              Text("• Safe Box"),
                              Text("• Cable TV"),
                              Text("• Wi-Fi"),
                              Text("• Refrigerator"),
                              Text("• Free Wi-Fi (in room)"),
                              Text("• Flat-screen TV"),
                              const SizedBox(height: 16),

                              const Text(
                                "Sports Facilities",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("• Bicycle Rental"),
                              const SizedBox(height: 16),

                              const Text(
                                "For Children",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("• Children's Playground"),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedButtonIndex = 0;
                                  });
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => LiveAppointmentPage(
                                            hotelName:
                                                hotel['property']?['name'] ??
                                                widget.hotel['hotel_name'] ??
                                                'Hotel',
                                          ),
                                    ),
                                  ).then((_) {
                                    _fetchLatestChannelName(); // 🔁 Firestore'dan tekrar çek
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      selectedButtonIndex == 0
                                          ? Colors.blue
                                          : Colors.grey[300],
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text("Create Live Appointment"),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (_channelName == null) {
                                    //eğer kanal yoksa uyarı varsa videopage e geçiyoruz
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "No channel found for this hotel.",
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    selectedButtonIndex = 1;
                                  });
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => VideoCallPage(
                                            channelName: _channelName!,
                                            isStaff:
                                                false, // 👈 çünkü bu kullanıcı tarafı
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      selectedButtonIndex == 1
                                          ? Colors.blue
                                          : Colors.grey[300],
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text("Start Live Tour"),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedButtonIndex = 2;
                                  });
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ReservationPage(
                                            hotelName:
                                                hotel['property']?['name'] ??
                                                hotel['hotel_name'] ??
                                                'Hotel',
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      selectedButtonIndex == 2
                                          ? Colors.blue
                                          : Colors.grey[300],
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text("Make Reservation"),
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
