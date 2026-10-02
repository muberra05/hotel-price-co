import 'package:flutter/material.dart'; // Material Desig ve temel UI araçlarını kullanmak için
import 'package:firebase_app_check/firebase_app_check.dart';
// sadece güvenilir kaynaklardan erişilmesini sağlar
import 'package:firebase_core/firebase_core.dart'; //firebase bağlantısıiçin

import 'screens/splash_screen.dart';
import 'screens/home_page.dart';
import 'screens/join_as_staff_page.dart'; //canlı aramada personelin oteli göstermesi için

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // emülatör için debug
    appleProvider: AppleProvider.debug,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel Live Preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFFDF8FF),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomePage(),
        '/joinAsStaff':
            (context) =>
                const JoinAsStaffPage(), //oteli göstereecek personelin bağlanması için
      },
    );
  }
}
