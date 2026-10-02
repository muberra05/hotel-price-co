import 'package:http/http.dart' as http; //http isteği için
import 'dart:convert';

class LocationService {
  final String apiKey = '98b50cbb0amsh329e0871c658edap1e14d2jsn2d990b440596';
  // konum bilgileri içim rapidapi booking.comdan aldığım api keyi  girdim.
  final String apiHost = 'hotels4.p.rapidapi.com';

  Future<String?> fetchRegionId(String cityName) async {
    final uri = Uri.https(apiHost, '/locations/v3/search', {
      'q': cityName,
      'locale': 'en_US',
      'langid': '1033', //apinin hangi dilde yanıt vereceği
      //dil seç.ekleyebilirim
      'siteid': '300000001', //global sorgular için
    });

    final response = await http.get(
      uri,
      headers: {'X-RapidAPI-Key': apiKey, 'X-RapidAPI-Host': apiHost},
      //kimlik doğrulanıyor sonra api host da hangi api çağrıl.gösteriyo.
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final sr = data['sr'] as List?;
      if (sr != null && sr.isNotEmpty) {
        return sr[0]['gaiaId'].toString();
      }
    }

    return null;
  }
}
