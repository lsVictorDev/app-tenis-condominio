import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../pages/home_screens.dart';
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Enquanto verifica a autenticação
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Usuário logado
          if (snapshot.hasData) {
            return const HomePage();
          }

          // Usuário não logado
          return const LoginPage();
        },
      ),
    );
  }
}