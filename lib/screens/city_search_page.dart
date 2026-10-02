import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/hotel_service.dart';

class CitySearchPage extends StatefulWidget {
  final Function(String) onCitySelected;

  const CitySearchPage({super.key, required this.onCitySelected});

  @override
  State<CitySearchPage> createState() => _CitySearchPageState();
}

class _CitySearchPageState extends State<CitySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  final HotelService _hotelService = HotelService();

  void _search() {
    final input = _searchController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a city or hotel name')),
      );
      return;
    }

    final parts = input.split(' ');
    final city = parts.last;

    widget.onCitySelected(city); // 🔹 Geri bildiriyoruz
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visotel'),
        backgroundColor: const Color.fromARGB(255, 39, 70, 244),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TypeAheadField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'City or Hotel Name (e.g., Istanbul, Hilton)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color.fromARGB(255, 49, 80, 253),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 32, 64, 244),
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
              suggestionsCallback: (pattern) async {
                return await _hotelService.fetchSuggestions(pattern);
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text(suggestion),
                );
              },
              onSuggestionSelected: (suggestion) {
                _searchController.text = suggestion;
                _search();
              },
              noItemsFoundBuilder:
                  (context) => const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No suggestions found'),
                  ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator(
                  color: Color.fromARGB(255, 39, 70, 244),
                )
                : ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 39, 70, 244),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Search',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
