import 'package:evoltsoft_2/Authentication/Splash_Screen.dart'; // Ensure the path is correct
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyD4KcBe_CoJggHBWFlg5n15kGJvo1dEfIA",
      appId: "1:966117448786:android:dfb30a2dd1338b48b0938b",
      messagingSenderId: "966117448786",
      projectId: "evoltsoft-faefb",
    ),
  );

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
