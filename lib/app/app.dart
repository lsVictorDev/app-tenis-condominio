import 'package:flutter/material.dart';
import '../pages/login_screens.dart';

class TenisCondominioApp extends StatelessWidget {
  const TenisCondominioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tênis Condomínio',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const LoginPage(),
    );
  }
}