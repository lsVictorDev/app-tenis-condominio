import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _telefoneController = TextEditingController();

  final TextEditingController _blocoController = TextEditingController();

  final TextEditingController _apartamentoController = TextEditingController();

  String _nivel = "Iniciante";

  Map<String, dynamic>? _dadosUsuario;
  bool _carregando = true;

  Future<void> _carregarDados() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();

    if (!doc.exists) return;

    _dadosUsuario = doc.data();

    _telefoneController.text = _dadosUsuario?['telefone'] ?? '';

    _blocoController.text = _dadosUsuario?['bloco'] ?? '';

    _apartamentoController.text = _dadosUsuario?['apartamento'] ?? '';

    _nivel = _dadosUsuario?['nivel'] ?? 'Iniciante';

    setState(() {
      _carregando = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _salvarPerfil() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'telefone': _telefoneController.text.trim(),
        'bloco': _blocoController.text.trim(),
        'apartamento': _apartamentoController.text.trim(),
        'nivel': _nivel,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Perfil atualizado com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint("======================================");
      debugPrint("ERRO AO SALVAR PERFIL");
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      debugPrint("======================================");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao atualizar perfil:\n$e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _telefoneController.dispose();
    _blocoController.dispose();
    _apartamentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Meu Perfil"),
          backgroundColor: Colors.green.shade900,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meu Perfil"),
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const CircleAvatar(radius: 45, child: Icon(Icons.person, size: 50)),

            const SizedBox(height: 30),

            TextFormField(
              initialValue: _dadosUsuario?['nome'] ?? '',
              enabled: false,
              decoration: const InputDecoration(
                labelText: "Nome",
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              initialValue: _dadosUsuario?['email'] ?? '',
              enabled: false,
              decoration: const InputDecoration(
                labelText: "E-mail",
                prefixIcon: Icon(Icons.email),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Telefone",
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _blocoController,
              decoration: const InputDecoration(
                labelText: "Bloco",
                prefixIcon: Icon(Icons.apartment),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _apartamentoController,
              decoration: const InputDecoration(
                labelText: "Apartamento",
                prefixIcon: Icon(Icons.home),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _nivel,
              decoration: const InputDecoration(
                labelText: "Nível",
                prefixIcon: Icon(Icons.sports_tennis),
              ),
              items: const [
                DropdownMenuItem(value: "Iniciante", child: Text("Iniciante")),
                DropdownMenuItem(
                  value: "Intermediário",
                  child: Text("Intermediário"),
                ),
                DropdownMenuItem(value: "Avançado", child: Text("Avançado")),
                DropdownMenuItem(
                  value: "Competitivo",
                  child: Text("Competitivo"),
                ),
              ],
              onChanged: (valor) {
                setState(() {
                  _nivel = valor!;
                });
              },
            ),

            const SizedBox(height: 35),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _salvarPerfil,
                icon: const Icon(Icons.save),
                label: const Text("SALVAR ALTERAÇÕES"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
