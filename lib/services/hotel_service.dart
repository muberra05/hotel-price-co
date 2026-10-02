import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hotel.dart';

class HotelService {
  final String apiKey = '98b50cbb0amsh329e0871c658edap1e14d2jsn2d990b440596';
  final String apiHost = 'booking-com15.p.rapidapi.com';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, String> get headers => {
    'X-RapidAPI-Key': apiKey,
    'X-RapidAPI-Host': apiHost,
  };

  Future<List<String>> fetchSuggestions(String query) async {
    if (query.isEmpty) return [];
    final uri = Uri.https(apiHost, '/api/v1/hotels/searchDestination', {
      'query': query,
    });

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataList = data['data'] as List<dynamic>?;
        if (dataList != null && dataList.isNotEmpty) {
          return dataList
              .map((item) => item['label'] as String? ?? 'Unknown Location')
              .toList();
        }
        return [];
      } else {
        print('Suggestions fetch failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchRegionId(String city) async {
    final uri = Uri.https(apiHost, '/api/v1/hotels/searchDestination', {
      'query': '$city',
    });

    print('City ID searching: $city - URI: $uri');

    try {
      final response = await http.get(uri, headers: headers);

      print('Response status: ${response.statusCode} - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataList = data['data'] as List<dynamic>?;
        if (dataList != null && dataList.isNotEmpty) {
          final destId = dataList[0]['dest_id']?.toString();
          final latitude = dataList[0]['latitude']?.toString();
          final longitude = dataList[0]['longitude']?.toString();
          return {
            'regionId': destId,
            'latitude': latitude,
            'longitude': longitude,
          };
        }
        return null;
      } else {
        print(
          'Failed to fetch city ID: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error fetching city ID: $e');
      return null;
    }
  }

  Future<List<dynamic>> fetchHotelsByRegionId(String regionId) async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final uri = Uri.https(apiHost, '/api/v1/hotels/searchHotels', {
      'dest_id': regionId,
      'search_type': 'city',
      'adults': '1',
      'arrival_date':
          now.toIso8601String().split('T')[0], //bize dinamik bir yapı sunuuyor.
      'departure_date':
          tomorrow.toIso8601String().split(
            'T',
          )[0], //biz tarih tanımlasaydık eeğr o tarih geçmişsse bookingden veri gelmezdi
      'currency': 'USD',
    });

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      //HTTP isteği başarılıysa aşağıdaki diğer işlemler devaö edrr
      final data = jsonDecode(response.body);
      print('Booking API Response: $data');
      print(" API response body: ${response.body}");
      final hotels = data['data']?['hotels'] ?? [];
      return hotels;
    } else {
      throw Exception(
        'Failed to fetch hotel list: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // ENönemli kısım bence
  Future<List<Hotel>> fetchHotels(String city) async {
    //Hem Booking.com API hem de Firestore'dan veri çeker.
    print(" fetchHotels called with city: $city");
    final List<Hotel> hotels = [];

    // 1. Booking API'den otelleri çek
    final cityData = await fetchRegionId(city);
    if (cityData != null && cityData['regionId'] != null) {
      final properties = await fetchHotelsByRegionId(cityData['regionId']);
      hotels.addAll(properties.map((json) => Hotel.fromJson(json)).toList());
    }

    // 2. Eğer kullanıcı "kibris" yazdıysa, Firestore'dan yurt verilerini çek
    if (city.trim().toLowerCase() == 'kibris') {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('DORMITORY')
              .where('city', isEqualTo: 'kibris')
              .get();

      final dorms =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return Hotel.fromFirestore(data);
          }).toList();

      hotels.addAll(dorms);
    }

    return hotels;
  }

  Future<List<String>> fetchHotelAmenities(String hotelId) async {
    final uri = Uri.https(apiHost, '/api/v1/hotels/getHotelDetails', {
      'hotel_id': hotelId,
      'currency': 'USD',
    });
    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final amenities = data['data']?['hotel_amenities'];

        if (amenities is List) {
          return amenities.map<String>((item) {
            return item['name'].toString(); // Örneğin: "Free Wi-Fi"
          }).toList();
        }
      } else {
        print(' fetchHotelAmenities failed: ${response.statusCode}');
      }
    } catch (e) {
      print(' Error in fetchHotelAmenities: $e');
    }

    return [];
  }
}
