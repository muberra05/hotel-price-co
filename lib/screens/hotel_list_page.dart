import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore için eklendi
import '../models/hotel.dart'; // Hotel modeli için ekledim
import '../services/hotel_service.dart'; // HotelService için ekledim
import 'hotel_detail_page.dart';

//import 'dormitory_detail_page.dart';

class HotellistPage extends StatefulWidget {
  final String cityName;
  final String hotelFilter;
  final VoidCallback? onBack; // Bir önceki city search page e geri dönmek için
  const HotellistPage({
    super.key,
    required this.cityName,
    this.hotelFilter = '', // seçimleri opsiyonel hale getirmek için
    this.onBack,
  });

  @override
  State<HotellistPage> createState() => _HotellistPageState();
}

class _HotellistPageState extends State<HotellistPage> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> originalItems =
      []; // Orijinal verileri depolamak için
  bool loading = true;
  String? error;
  Set<String> favoriteHotelIds = {}; // Favori otel ID'lerini tutar
  Future<void> fetchFavorites() async {
    //firestoredanfavori otelleir alır
    final String userId = 'user123';
    final snapshot =
        await FirebaseFirestore.instance
            .collection('FAVORITES')
            .doc(userId)
            .collection('hotels')
            .get();

    setState(() {
      favoriteHotelIds = snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  // Sıralama durumları
  List<String> selectedSortOptions = [];
  List<String> tempSortOptions = [];
  List<String> sortOptions = [
    'Recommended',
    'Distance to City Center (Near to Far)',
    'Distance to City Center (Far to Near)',
    'Star Rating (High to Low)',
    'Price (Low to High)',
    'Price (High to Low)',
  ];

  // Filtreleme durumları
  TextEditingController minPriceController = TextEditingController();
  TextEditingController maxPriceController = TextEditingController();
  List<String> selectedRoomTypes = [];
  bool hasPool = false;
  bool hasSpa = false;
  bool hasRestaurant = false;
  bool hasWifi = false;
  bool hasParking = false;
  bool hasPetFriendly = false;
  bool hasDormitory = false; // Yeni eklenen filtre
  double minReviewScore = 0.0; // Gerçek filtre
  double tempMinReviewScore = 0.0; // Geçici (slider için)

  // Filtreleme için geçici durumlar Uygula butonu için
  TextEditingController tempMinPriceController = TextEditingController();
  TextEditingController tempMaxPriceController = TextEditingController();
  List<String> tempRoomTypes = [];
  bool tempHasPool = false;
  bool tempHasSpa = false;
  bool tempHasRestaurant = false;
  bool tempHasWifi = false;
  bool tempHasParking = false;
  bool tempIsPetFriendly = false;
  bool tempHasDormitory = false; // Yeni eklenen geçici durum
  List<String> roomTypes = [
    'Single Room',
    'Double Room',
    'Family Room',
    'Suite Room',
  ];

  // Sort ve Filtreleme paneli
  bool isSortPanelVisible = false;
  bool isFilterPanelVisible = false;

  @override
  void initState() {
    super.initState();
    loadData();
    fetchFavorites();
  }

  bool _isFavorite(Map<String, dynamic> hotel) {
    final hotelId = (hotel['id'] ?? hotel['property']?['name']).toString();
    return favoriteHotelIds.contains(hotelId);
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      error = null;
    });

    if (originalItems.isEmpty) {
      final hotelService = HotelService();

      // Booking ve Firestore'dan tüm otelleri al
      final combinedHotels = await hotelService.fetchHotels(widget.cityName);

      // Gelen her oteli Map'e dönüştür
      originalItems = [];
      for (var hotel in combinedHotels) {
        List<String> amenities = [];

        if (hotel.provider != 'Dormitory' && hotel.id != null) {
          amenities = await hotelService.fetchHotelAmenities(hotel.id);
        }

        originalItems.add({
          'id': hotel.id,
          'property': {
            'name': hotel.name,
            'photoUrls': hotel.images,
            'priceBreakdown': {
              'grossPrice': {'value': hotel.price},
            },
            'amenities': amenities,
            'description': hotel.description,
            'provider': hotel.provider,
            'accuratePropertyClass': hotel.starRating,
            'reviewScore': hotel.reviewScore,
          },
          'accessibilityLabel': hotel.distance ?? '0.0 km',
        });
      }
    }

    var list = List<Map<String, dynamic>>.from(originalItems);

    if (widget.hotelFilter.isNotEmpty) {
      list =
          list.where((hotel) {
            final name = hotel['property']?['name']?.toLowerCase() ?? '';
            return name.contains(widget.hotelFilter.toLowerCase());
          }).toList();
    }

    list =
        list.where((hotel) {
          String priceRaw =
              hotel['property']?['priceBreakdown']?['grossPrice']?['value']
                  ?.toString() ??
              hotel['price']?.toString() ??
              '0.0';
          double price = double.tryParse(priceRaw) ?? 0.0;

          double minPrice = double.tryParse(minPriceController.text) ?? 0.0;
          double maxPrice =
              double.tryParse(maxPriceController.text) ?? double.infinity;

          if (price < minPrice || price > maxPrice) return false;

          String roomType =
              hotel['property']?['roomDetails']?.toString() ?? 'Unknown';
          if (selectedRoomTypes.isNotEmpty &&
              !selectedRoomTypes.contains(roomType))
            return false;

          List<dynamic> amenities = hotel['property']?['amenities'] ?? [];
          bool hotelHasPool = amenities.contains('POOL');
          bool hotelHasSpa = amenities.contains('SPA');
          bool hotelHasRestaurant = amenities.contains('RESTAURANT');
          bool hotelHasWifi = amenities.contains('WIFI');
          bool hotelHasParking = amenities.contains('PARKING');
          bool hotelIsPetFriendly = amenities.contains('PET_FRIENDLY');

          if (hasPool && !hotelHasPool) return false;
          if (hasSpa && !hotelHasSpa) return false;
          if (hasRestaurant && !hotelHasRestaurant) return false;
          if (hasWifi && !hotelHasWifi) return false;
          if (hasParking && !hotelHasParking) return false;
          if (hasPetFriendly && !hotelIsPetFriendly) return false;

          bool isDormitory = hotel['property']?['provider'] == 'Dormitory';
          if (hasDormitory && !isDormitory)
            return false; // "Dormitory" filtresini eklemek için
          double reviewScore =
              double.tryParse(
                hotel['property']?['reviewScore']?.toString() ?? '0.0',
              ) ??
              0.0;
          if (reviewScore < minReviewScore) return false;
          return true;
        }).toList();

    if (selectedSortOptions.isNotEmpty) {
      list.sort((a, b) {
        if (selectedSortOptions.contains('Recommended')) {
          double starA =
              double.tryParse(
                a['property']?['accuratePropertyClass']?.toString() ??
                    a['property']?['starRating']?.toString() ??
                    '0.0',
              ) ??
              0.0;
          double starB =
              double.tryParse(
                b['property']?['accuratePropertyClass']?.toString() ??
                    b['property']?['starRating']?.toString() ??
                    '0.0',
              ) ??
              0.0;
          double priceA =
              double.tryParse(
                a['property']?['priceBreakdown']?['grossPrice']?['value']
                        ?.toString() ??
                    a['price']?.toString() ??
                    '0.0',
              ) ??
              0.0;
          double priceB =
              double.tryParse(
                b['property']?['priceBreakdown']?['grossPrice']?['value']
                        ?.toString() ??
                    b['price']?.toString() ??
                    '0.0',
              ) ??
              0.0;

          double scoreA = starA * 1000 - priceA;
          double scoreB = starB * 1000 - priceB;
          return scoreB.compareTo(scoreA);
        }

        for (String sortOption in selectedSortOptions) {
          if (sortOption == 'Price (Low to High)') {
            double priceA =
                double.tryParse(
                  a['property']?['priceBreakdown']?['grossPrice']?['value']
                          ?.toString() ??
                      a['price']?.toString() ??
                      '0.0',
                ) ??
                0.0;
            double priceB =
                double.tryParse(
                  b['property']?['priceBreakdown']?['grossPrice']?['value']
                          ?.toString() ??
                      b['price']?.toString() ??
                      '0.0',
                ) ??
                0.0;
            int result = priceA.compareTo(priceB);
            if (result != 0) return result;
          } else if (sortOption == 'Price (High to Low)') {
            double priceA =
                double.tryParse(
                  a['property']?['priceBreakdown']?['grossPrice']?['value']
                          ?.toString() ??
                      a['price']?.toString() ??
                      '0.0',
                ) ??
                0.0;
            double priceB =
                double.tryParse(
                  b['property']?['priceBreakdown']?['grossPrice']?['value']
                          ?.toString() ??
                      b['price']?.toString() ??
                      '0.0',
                ) ??
                0.0;
            int result = priceB.compareTo(priceA);
            if (result != 0) return result;
          } else if (sortOption == 'Star Rating (High to Low)') {
            double starA =
                double.tryParse(
                  a['property']?['accuratePropertyClass']?.toString() ??
                      a['property']?['starRating']?.toString() ??
                      '0.0',
                ) ??
                0.0;
            double starB =
                double.tryParse(
                  b['property']?['accuratePropertyClass']?.toString() ??
                      b['property']?['starRating']?.toString() ??
                      '0.0',
                ) ??
                0.0;
            int result = starB.compareTo(starA);
            if (result != 0) return result;
          } else if (sortOption == 'Distance to City Center (Near to Far)') {
            String accessibilityLabelA = a['accessibilityLabel'] ?? '';
            String accessibilityLabelB = b['accessibilityLabel'] ?? '';
            RegExp distanceRegex = RegExp(r'(\d+(\.\d+)?)\s?km');
            Match? matchA = distanceRegex.firstMatch(accessibilityLabelA);
            Match? matchB = distanceRegex.firstMatch(accessibilityLabelB);
            double distanceA =
                matchA != null
                    ? double.tryParse(matchA.group(1) ?? '0.0') ?? 0.0
                    : 999.0;
            double distanceB =
                matchB != null
                    ? double.tryParse(matchB.group(1) ?? '0.0') ?? 0.0
                    : 999.0;
            int result = distanceA.compareTo(distanceB);
            if (result != 0) return result;
          } else if (sortOption == 'Distance to City Center (Far to Near)') {
            String accessibilityLabelA = a['accessibilityLabel'] ?? '';
            String accessibilityLabelB = b['accessibilityLabel'] ?? '';
            RegExp distanceRegex = RegExp(r'(\d+(\.\d+)?)\s?km');
            Match? matchA = distanceRegex.firstMatch(accessibilityLabelA);
            Match? matchB = distanceRegex.firstMatch(accessibilityLabelB);
            double distanceA =
                matchA != null
                    ? double.tryParse(matchA.group(1) ?? '0.0') ?? 0.0
                    : 999.0;
            double distanceB =
                matchB != null
                    ? double.tryParse(matchB.group(1) ?? '0.0') ?? 0.0
                    : 999.0;
            int result = distanceB.compareTo(distanceA);
            if (result != 0) return result;
          }
        }
        return 0;
      });
    }

    setState(() {
      items = list;
      loading = false;
      if (items.isEmpty) {
        error = 'No hotels found.'; //otel bulunamadıysa
      }
    });
  }

  void showSortPanel() {
    setState(() {
      isSortPanelVisible = !isSortPanelVisible;
      if (isSortPanelVisible) {
        tempSortOptions = List.from(selectedSortOptions);
        isFilterPanelVisible = false;
      }
    });
  }

  // filtrelemeyle ilgili özellikler
  void showFilterPanel() {
    setState(() {
      isFilterPanelVisible = !isFilterPanelVisible;
      if (isFilterPanelVisible) {
        tempMinPriceController.text = minPriceController.text;
        tempMaxPriceController.text = maxPriceController.text;
        tempRoomTypes = List.from(selectedRoomTypes);
        tempHasPool = hasPool;
        tempHasSpa = hasSpa;
        tempHasRestaurant = hasRestaurant;
        tempHasWifi = hasWifi;
        tempHasParking = hasParking;
        tempIsPetFriendly = hasPetFriendly;
        tempHasDormitory = hasDormitory; // Yeni eklenen
        isSortPanelVisible = false;
      }
    });
  }

  void toggleFavorite(String hotelId, Map<String, dynamic> hotelData) async {
    final String userId = 'user123';
    final ref = FirebaseFirestore.instance
        .collection('FAVORITES')
        .doc(userId)
        .collection('hotels')
        .doc(hotelId);

    if (favoriteHotelIds.contains(hotelId)) {
      await ref.delete();
      setState(() => favoriteHotelIds.remove(hotelId));
    } else {
      await ref.set({
        'name': hotelData['property']['name'] ?? '',
        'photo': hotelData['property']['photoUrls'][0] ?? '',
        'price':
            hotelData['property']['priceBreakdown']['grossPrice']['value'] ??
            '',
        'distance': hotelData['accessibilityLabel'] ?? '',
      });
      setState(() => favoriteHotelIds.add(hotelId));
    }
  }

  Future<void> toggleFavoriteInFirestore(Map<String, dynamic> hotel) async {
    //favoriye ekleme kaldırma
    final String userId = 'user123';
    final String hotelId =
        (hotel['id'] ?? hotel['property']?['name']).toString();

    final docRef = FirebaseFirestore.instance
        .collection('FAVORITES')
        .doc(userId)
        .collection('hotels')
        .doc(hotelId);

    final snapshot = await docRef.get();

    if (snapshot.exists) {
      await docRef.delete();
      favoriteHotelIds.remove(hotelId);
    } else {
      await docRef.set({
        'name': hotel['property']['name'] ?? '',
        'photo': hotel['property']['photoUrls'][0] ?? '',
        'price':
            hotel['property']['priceBreakdown']['grossPrice']['value'] ?? '',
        'distance': hotel['accessibilityLabel'] ?? '',
      });
      favoriteHotelIds.add(hotelId);
    }

    setState(() {}); // UI'yi güncelle
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Visotel - ${widget.cityName}')),
        body: Center(child: Text(error!, style: const TextStyle(fontSize: 18))),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!(); // 🔙 Geri dönüş fonksiyonunu çalıştır
            }
          },
        ),
        title: Text('Visotel - ${widget.cityName}'),
        backgroundColor: const Color.fromRGBO(39, 70, 244, 1),
        elevation: 0,
      ),

      body: Column(
        children: [
          // Sort & Filtreleme kısmı
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: showSortPanel,
                  child: Row(
                    children: [
                      Icon(
                        isSortPanelVisible
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Sort',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: showFilterPanel,
                  child: Row(
                    children: [
                      Icon(
                        isFilterPanelVisible
                            ? Icons.filter_list_off
                            : Icons.filter_list,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sıralama Paneli
          if (isSortPanelVisible)
            Container(
              color: Colors.white,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    children: [
                      ...sortOptions.map((option) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 0.0,
                          ),
                          title: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: Checkbox(
                            value: tempSortOptions.contains(option),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  if (option == 'Recommended') {
                                    tempSortOptions.clear();
                                    tempSortOptions.add(option);
                                  } else {
                                    tempSortOptions.remove('Recommended');
                                    tempSortOptions.add(option);
                                  }
                                } else {
                                  tempSortOptions.remove(option);
                                }
                              });
                            },
                            shape: const CircleBorder(),
                            activeColor: Colors.blueAccent,
                          ),
                          onTap: () {
                            setState(() {
                              if (tempSortOptions.contains(option)) {
                                tempSortOptions.remove(option);
                              } else {
                                if (option == 'Recommended') {
                                  tempSortOptions.clear();
                                  tempSortOptions.add(option);
                                } else {
                                  tempSortOptions.remove('Recommended');
                                  tempSortOptions.add(option);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                tempSortOptions.clear();
                                selectedSortOptions.clear();
                                isSortPanelVisible = false;
                              });
                              loadData();
                            },
                            child: const Text(
                              'Clear', //yapılan seçimleri geri alabiliriz
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedSortOptions = List.from(
                                  tempSortOptions,
                                );
                                isSortPanelVisible = false;
                              });
                              loadData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Filtreleme Paneli
          if (isFilterPanelVisible)
            Container(
              color: Colors.white,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price Range (USD)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: tempMinPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Min Price',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: tempMaxPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Max Price',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Room Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...roomTypes.map((type) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 0.0,
                          ),
                          title: Text(
                            type,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: Checkbox(
                            value: tempRoomTypes.contains(type),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  tempRoomTypes.add(type);
                                } else {
                                  tempRoomTypes.remove(type);
                                }
                              });
                            },
                            shape: const CircleBorder(),
                            activeColor: Colors.blueAccent,
                          ),
                          onTap: () {
                            setState(() {
                              if (tempRoomTypes.contains(type)) {
                                tempRoomTypes.remove(type);
                              } else {
                                tempRoomTypes.add(type);
                              }
                            });
                          },
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      const Text(
                        'Minimum Customer Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: tempMinReviewScore,
                        min: 0.0,
                        max: 10.0,
                        divisions: 20,
                        label: tempMinReviewScore.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            tempMinReviewScore = value;
                          });
                        },
                      ),

                      const Text(
                        'Hotel Features',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 0.0,
                        ),
                        title: const Text(
                          'Has Pool',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        trailing: Checkbox(
                          value: tempHasPool,
                          onChanged: (bool? value) {
                            setState(() {
                              tempHasPool = value ?? false;
                            });
                          },
                          shape: const CircleBorder(),
                          activeColor: Colors.blueAccent,
                        ),
                        onTap: () {
                          setState(() {
                            tempHasPool = !tempHasPool;
                          });
                        },
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 0.0,
                        ),
                        title: const Text(
                          'Has Spa',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        trailing: Checkbox(
                          value: tempHasSpa,
                          onChanged: (bool? value) {
                            setState(() {
                              tempHasSpa = value ?? false;
                            });
                          },
                          shape: const CircleBorder(),
                          activeColor: Colors.blueAccent,
                        ),
                        onTap: () {
                          setState(() {
                            tempHasSpa = !tempHasSpa;
                          });
                        },
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 0.0,
                        ),
                        title: const Text(
                          'Has Restaurant',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        trailing: Checkbox(
                          value: tempHasRestaurant,
                          onChanged: (bool? value) {
                            setState(() {
                              tempHasRestaurant = value ?? false;
                            });
                          },
                          shape: const CircleBorder(),
                          activeColor: Colors.blueAccent,
                        ),
                        onTap: () {
                          setState(() {
                            tempHasRestaurant = !tempHasRestaurant;
                          });
                        },
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 0.0,
                        ),
                        title: const Text(
                          'Free Wi-Fi',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        trailing: Checkbox(
                          value: tempHasWifi,
                          onChanged: (bool? value) {
                            setState(() {
                              tempHasWifi = value ?? false;
                            });
                          },
                          shape: const CircleBorder(),
                          activeColor: Colors.blueAccent,
                        ),
                        onTap: () {
                          setState(() {
                            tempHasWifi = !tempHasWifi;
                          });
                        },
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 0.0,
                        ),
                        title: const Text(
                          'Parking Available',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        trailing: Checkbox(
                          value: tempHasParking,
                          onChanged: (bool? value) {
                            setState(() {
                              tempHasParking = value ?? false;
                            });
                          },
                          shape: const CircleBorder(),
                          activeColor: Colors.blueAccent,
                        ),
                        onTap: () {
                          setState(() {
                            tempHasParking = !tempHasParking;
                          });
                        },
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 0.0,
                        ),
                        title: const Text(
                          'Pet Friendly',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        trailing: Checkbox(
                          value: tempIsPetFriendly,
                          onChanged: (bool? value) {
                            setState(() {
                              tempIsPetFriendly = value ?? false;
                            });
                          },
                          shape: const CircleBorder(),
                          activeColor: Colors.blueAccent,
                        ),
                        onTap: () {
                          setState(() {
                            tempIsPetFriendly = !tempIsPetFriendly;
                          });
                        },
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 0.0,
                        ),
                        title: const Text(
                          'Dormitory',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        trailing: Checkbox(
                          value: tempHasDormitory,
                          onChanged:
                              (bool? value) => setState(
                                () => tempHasDormitory = value ?? false,
                              ),
                          shape: const CircleBorder(),
                          activeColor: Colors.blueAccent,
                        ),
                        onTap:
                            () => setState(
                              () => tempHasDormitory = !tempHasDormitory,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                tempMinPriceController.clear();
                                tempMaxPriceController.clear();
                                tempRoomTypes.clear();
                                tempHasPool = false;
                                tempHasSpa = false;
                                tempHasRestaurant = false;
                                tempHasWifi = false;
                                tempHasParking = false;
                                tempIsPetFriendly = false;
                                tempHasDormitory = false;
                                tempMinReviewScore = 0.0;
                                minReviewScore = 0.0;
                                minPriceController.clear();
                                maxPriceController.clear();
                                selectedRoomTypes.clear();
                                hasPool = false;
                                hasSpa = false;
                                hasRestaurant = false;
                                hasWifi = false;
                                hasParking = false;
                                hasPetFriendly = false;
                                hasDormitory = false;
                                isFilterPanelVisible = false;
                              });
                              loadData();
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                //filtreleme
                                minPriceController.text =
                                    tempMinPriceController.text;
                                maxPriceController.text =
                                    tempMaxPriceController.text;
                                minReviewScore = tempMinReviewScore;
                                selectedRoomTypes = List.from(tempRoomTypes);
                                hasPool = tempHasPool;
                                hasSpa = tempHasSpa;
                                hasRestaurant = tempHasRestaurant;
                                hasWifi = tempHasWifi;
                                hasParking = tempHasParking;
                                hasPetFriendly = tempIsPetFriendly;
                                hasDormitory = tempHasDormitory;
                                isFilterPanelVisible = false;
                              });
                              loadData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // otel listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, i) {
                var h = items[i];
                String provider = h['property']?['provider'] ?? 'Booking.com';

                if (provider == 'Dormitory') {
                  // verileri tanımlıyoruz
                  String name = h['property']?['name'] ?? 'Dormitory';
                  String imageUrl =
                      h['property']?['photoUrls']?[0] ??
                      'https://via.placeholder.com/150';
                  String distance = h['accessibilityLabel'] ?? 'Unknown';
                  String priceRaw =
                      h['property']?['priceBreakdown']?['grossPrice']?['value']
                          ?.toString() ??
                      'Not Available';

                  //  ListTile içindeki onTap'i yazıyoruz
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      onTap: () {
                        /* Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DormitoryDetailPage(dorm: h),
                          ),
                        );*/
                      },
                      leading: Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("📍 $distance"),
                          Text(
                            priceRaw != 'Not Available'
                                ? "\$$priceRaw USD"
                                : "Fiyat bilgisi yok",
                          ),
                          const Text(
                            "Dormitory (Firestore)",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // BOOKING.COM OTELLERİ
                  String hotelName =
                      h['property']?['name'] ?? h['hotel_name'] ?? 'Hotel';
                  String priceRaw =
                      h['property']?['priceBreakdown']?['grossPrice']?['value']
                          ?.toString() ??
                      'Not Available';
                  String price =
                      priceRaw == 'Not Available'
                          ? priceRaw
                          : double.parse(priceRaw).toStringAsFixed(2);
                  String starRating =
                      h['property']?['accuratePropertyClass']?.toString() ??
                      h['property']?['starRating']?.toString() ??
                      'No Rating';
                  double starRatingValue = double.tryParse(starRating) ?? 0.0;
                  double reviewScoreValue =
                      double.tryParse(
                        h['property']?['reviewScore']?.toString() ??
                            h['reviewScore']?.toString() ??
                            '0.0',
                      ) ??
                      0.0;
                  String accessibilityLabel = h['accessibilityLabel'] ?? '';
                  RegExp distanceRegex = RegExp(r'(\d+(\.\d+)?)\s?km');
                  Match? match = distanceRegex.firstMatch(accessibilityLabel);
                  String distance =
                      match != null
                          ? match.group(0) ?? 'Unknown Distance'
                          : 'Unknown Distance';
                  String imageUrl =
                      h['property']?['photoUrls']?[0] ??
                      'https://via.placeholder.com/150';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => HotelDetailPage(
                                hotel: h,
                              ), //seçilen otele basınca detay say,yönlendirir
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center, // Card içeriğini yatayda ortalar
                        crossAxisAlignment:
                            CrossAxisAlignment.center, // Dikeyde hizalar
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              imageUrl,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover, // Görsel card içinde kalır
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          hotelName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ), // Kalp ile otelin ismi arasında boşluk
                                      IconButton(
                                        icon: Icon(
                                          _isFavorite(h)
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color:
                                              _isFavorite(h)
                                                  ? Colors.red
                                                  : Colors.grey,
                                        ),
                                        onPressed:
                                            () => toggleFavoriteInFirestore(h),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      ...List.generate(
                                        5,
                                        (index) => Icon(
                                          index < starRatingValue.floor()
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.yellow,
                                          size: 16,
                                        ),
                                      ),
                                      if (starRatingValue % 1 != 0)
                                        const Icon(
                                          Icons.star_half,
                                          color: Colors.yellow,
                                          size: 16,
                                        ),
                                      const SizedBox(width: 4),
                                      Text(
                                        starRatingValue > 0
                                            ? '${starRatingValue.toStringAsFixed(1)}'
                                            : '0.0',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.emoji_emotions_rounded,
                                        size: 16,
                                        color:
                                            reviewScoreValue >= 8.0
                                                ? Colors.green
                                                : reviewScoreValue >= 6.0
                                                ? Colors.orange
                                                : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${reviewScoreValue.toStringAsFixed(1)} / 10',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              reviewScoreValue >= 8.0
                                                  ? Colors.green
                                                  : reviewScoreValue >= 6.0
                                                  ? Colors.orange
                                                  : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "\$$price USD",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "📍 $distance from center",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> getCity(String cityName) async {
    print('getcity called: $cityName');
    var url = Uri.https(
      'booking-com15.p.rapidapi.com',
      '/api/v1/hotels/searchDestination',
      {'query': cityName},
    );
    var res = await http.get(
      url,
      headers: {
        'X-RapidAPI-Key': '98b50cbb0amsh329e0871c658edap1e14d2jsn2d990b440596',
        'X-RapidAPI-Host': 'booking-com15.p.rapidapi.com',
      },
    );
    print('CityId status: ${res.statusCode}');
    print('CityId body: ${res.body}');
    if (res.statusCode == 200) {
      var decoded = jsonDecode(res.body);
      var data = decoded['data'];
      if (data is List && data.isNotEmpty) {
        // Şehir olanı al
        var cityItem = data.firstWhere(
          (item) => item['dest_type'] == 'city',
          orElse: () => null,
        );
        if (cityItem != null) {
          return cityItem['city_ufi']?.toString() ??
              cityItem['dest_id']?.toString();
        }
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getList(String cityId) async {
    //bookingden veri çekmek için
    var now = DateTime.now();
    var arrivaldate = now.add(Duration(days: 1));
    var departureDate = now.add(Duration(days: 2));

    String arrival =
        "${arrivaldate.year}-${arrivaldate.month.toString().padLeft(2, '0')}-${arrivaldate.day.toString().padLeft(2, '0')}";
    String departure =
        "${departureDate.year}-${departureDate.month.toString().padLeft(2, '0')}-${departureDate.day.toString().padLeft(2, '0')}";

    var url = Uri.https(
      'booking-com15.p.rapidapi.com',
      '/api/v1/hotels/searchHotels',
      {
        'dest_id': cityId,
        'search_type': 'city',
        'adults': '1',
        'arrival_date': arrival,
        'departure_date': departure,
        'currency': 'USD',
      },
    );
    var res = await http.get(
      url,
      headers: {
        'X-RapidAPI-Key': '98b50cbb0amsh329e0871c658edap1e14d2jsn2d990b440596',
        'X-RapidAPI-Host': 'booking-com15.p.rapidapi.com',
      },
    );
    if (res.statusCode == 200) {
      var decoded = jsonDecode(res.body);
      var data = decoded['data'];
      final hotelsRaw = data?['hotels'];
      if (hotelsRaw is List && hotelsRaw.isNotEmpty) {
        return List<Map<String, dynamic>>.from(hotelsRaw);
      }
      if (hotelsRaw is List && hotelsRaw.isNotEmpty) {
        print("incoming JSON output : ${jsonEncode(hotelsRaw[0])}");
        return List<Map<String, dynamic>>.from(hotelsRaw);
      } else {
        print("🔥 hotelsRaw empty or null!");
      }
    }
    return [];
  }
}
