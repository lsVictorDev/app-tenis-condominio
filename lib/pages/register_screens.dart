import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
  if (_nameController.text.trim().isEmpty ||
      _emailController.text.trim().isEmpty ||
      _passwordController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Preencha todos os campos."),
      ),
    );
    return;
  }

  try {
    // Cria usuário no Firebase Authentication
    UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Obtém o UID do usuário criado
    final uid = userCredential.user!.uid;

    // Salva os dados no Cloud Firestore
    await _firestore.collection('usuarios').doc(uid).set({
      'uid': uid,
      'nome': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'criadoEm': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Conta criada com sucesso!"),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  } on FirebaseAuthException catch (e) {
    String mensagem;

    switch (e.code) {
      case 'email-already-in-use':
        mensagem = "Este e-mail já está cadastrado.";
        break;
      case 'invalid-email':
        mensagem = "E-mail inválido.";
        break;
      case 'weak-password':
        mensagem = "A senha deve ter pelo menos 6 caracteres.";
        break;
      default:
        mensagem = e.message ?? "Erro ao criar conta.";
    }

    if (!mounted) return;

    debugPrint("=======================================");
    debugPrint("FIREBASE REGISTER ERROR");
    debugPrint("Code: ${e.code}");
    debugPrint("Message: ${e.message}");
    debugPrint("=======================================");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  } catch (e) {
    debugPrint("=======================================");
    debugPrint("FIRESTORE ERROR");
    debugPrint(e.toString());
    debugPrint("=======================================");

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erro inesperado: $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade900,
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Criar conta"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.person_add, color: Colors.white, size: 80),

              const SizedBox(height: 20),

              const Text(
                "Cadastro",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Nome completo",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "E-mail",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Senha",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade900,
                  ),
                  child: const Text(
                    "CRIAR CONTA",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text(
                  "Já tenho uma conta",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
