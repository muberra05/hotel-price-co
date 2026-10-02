import 'dart:convert';

class Hotel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> images;
  final double? starRating; // Nullable
  final double? reviewScore; // 🧑‍💼
  final String? distance; // Nullable
  final int? price; // Nullable
  final String provider; // "Booking.com" veya "Dormitory"
  final bool breakfastIncluded;
  final bool freeCancellation;
  final List<Map<String, dynamic>> otherPrices;
  final String staffId;

  Hotel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.images,
    this.starRating,
    this.reviewScore, //kullanıcı puanını da ekledim
    this.distance,
    this.price,
    required this.provider,
    required this.breakfastIncluded,
    required this.freeCancellation,
    required this.otherPrices,
    required this.staffId,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];
    var photoUrls = json['property']?['photoUrls'] as List<dynamic>?;
    if (photoUrls != null) {
      imagesList =
          photoUrls
              .map((url) => url.toString())
              .where((url) => url.isNotEmpty)
              .toList();
    }

    double? starRating;
    double? reviewScore;

    // ⭐️ YILDIZ PUANI
    if (json['property']?['accuratePropertyClass'] != null) {
      starRating = double.tryParse(
        json['property']['accuratePropertyClass'].toString(),
      );
      print('Star Rating found: $starRating');
    } else {
      final starMatch = RegExp(
        r'(\d+)\s*(?:out of 5 stars)',
      ).firstMatch(json['accessibilityLabel'] ?? '');
      if (starMatch != null) {
        starRating = double.tryParse(starMatch.group(1)!);
        print('Star rating from accessibilityLabel: $starRating');
      } else {
        print('No star rating found.');
      }
    }

    // 🧑‍💼 MÜŞTERİ MEMNUNİYET PUANI
    if (json['property']?['reviewScore'] != null) {
      reviewScore = double.tryParse(json['property']['reviewScore'].toString());
      print('Review Score found: $reviewScore');
    }

    String? distance;
    if (json['accessibilityLabel'] != null) {
      final kmMatch = RegExp(
        r'(\d+\.\d+|\d+)\s?km\s?(?:from\s?(?:centre|center))',
      ).firstMatch(json['accessibilityLabel']);
      final mMatch = RegExp(
        r'(\d+\.\d+|\d+)\s?m\s?(?:from\s?(?:centre|center))',
      ).firstMatch(json['accessibilityLabel']);

      if (kmMatch != null) {
        distance = kmMatch.group(1)! + ' km';
        print('📍 Distance information from API: $distance');
      } else if (mMatch != null) {
        final meters = double.tryParse(mMatch.group(1)!);
        if (meters != null) {
          distance = (meters / 1000).toStringAsFixed(1) + ' km';
          print(
            '📍 Distance information from API: $distance (converted from ${mMatch.group(1)} m)',
          );
        }
      } else {
        print(
          '📍 No distance found in accessibilityLabel: ${json['accessibilityLabel']}',
        );
      }
    }
    if (distance == null) {
      print('📍 Distance information from API: Unknown Distance');
      distance = 'Unknown Distance';
    }

    int? price;
    if (json['property']?['priceBreakdown']?['grossPrice']?['value'] != null) {
      price =
          (json['property']['priceBreakdown']['grossPrice']['value'] as num?)
              ?.toInt();
      print('Price found: $price');
    }

    return Hotel(
      id: json['hotel_id']?.toString() ?? '',
      name: json['property']?['name'] ?? json['hotel_name'] ?? '',
      description: json['property']?['description'] ?? '',
      imageUrl:
          imagesList.isNotEmpty
              ? imagesList[0]
              : 'https://via.placeholder.com/150',
      images: imagesList,
      starRating: starRating,
      reviewScore: reviewScore,
      distance: distance,
      price: price,
      provider: 'Booking.com',
      breakfastIncluded: false,
      freeCancellation:
          json['property']?['policies']?['freeCancellation'] ?? false,
      otherPrices: [],
      staffId: '',
    );
  }

  factory Hotel.fromFirestore(Map<String, dynamic> data) {
    List<String> images =
        [
          data['image1']?.toString() ?? '',
          data['image2']?.toString() ?? '',
          data['image3']?.toString() ?? '',
          data['image4']?.toString() ?? '',
          data['image5']?.toString() ?? '',
        ].where((url) => url.isNotEmpty).toList();

    if (data['images'] != null) {
      if (data['images'] is String) {
        try {
          final imagesJson = jsonDecode(data['images']);
          images.addAll(
            (imagesJson as List)
                .map((e) => e.toString())
                .where((e) => e.isNotEmpty),
          );
        } catch (_) {}
      } else if (data['images'] is List) {
        images.addAll(
          (data['images'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty),
        );
      }
    }

    return Hotel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl:
          images.isNotEmpty ? images[0] : 'https://via.placeholder.com/150',
      images: images,
      starRating:
          data['rating'] != null ? (data['rating'] as num).toDouble() : null,
      distance: data['distance']?.toString(),
      price: data['price'] != null ? (data['price'] as num).toInt() : null,
      provider: 'Dormitory',
      breakfastIncluded: false,
      freeCancellation: false,
      otherPrices: [],
      staffId: data['staffId'] ?? '',
    );
  }
}
