import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hotel_list_page.dart';
import 'favorites_page.dart';
import 'profile_page.dart';
import 'city_search_page.dart';
import 'auth_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late Widget currentMainPage;
  final Widget favoritesPage = FavoritesPage();
  final Widget profilePage = ProfilePage();

  @override
  void initState() {
    super.initState();

    currentMainPage = CitySearchPage(onCitySelected: onCitySelected);

    //İlk açılışta login yoksa gösterir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser == null) {
        _showAuthSheet(context);
      }
    });
  }

  void onCitySelected(String cityName) {
    setState(() {
      currentMainPage = HotellistPage(
        cityName: cityName,
        onBack: () {
          setState(() {
            currentMainPage = CitySearchPage(onCitySelected: onCitySelected);
          });
        },
      );
      _currentIndex = 0;
    });
  }

  void _showAuthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return AuthPage(scrollController: scrollController);
          },
        );
      },
    ).whenComplete(() {
      // ✅ Kapatılınca CitySearch'e döndür
      setState(() {
        currentMainPage = CitySearchPage(onCitySelected: onCitySelected);
        _currentIndex = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [currentMainPage, favoritesPage, profilePage];

    return Scaffold(
      body: Stack(
        children: [
          pages[_currentIndex], // var olan sayfaları (home, favorites, profile) göstermeye devam eder
          if (_currentIndex == 0) // Sadece home sayfasında görünür
            Positioned(
              bottom: 80,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/joinAsStaff');
                },
                child: const Text("Join as Staff"),
              ),
            ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home Page'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
