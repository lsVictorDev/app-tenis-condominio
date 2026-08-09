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
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      setState(() {
        _carregando = false;
      });
      return;
    }

    final uid = usuario.uid;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!doc.exists) {
        setState(() {
          _carregando = false;
        });
        return;
      }

      _dadosUsuario = doc.data();

      _telefoneController.text = _dadosUsuario?['telefone'] ?? '';

      _blocoController.text = _dadosUsuario?['bloco'] ?? '';

      _apartamentoController.text = _dadosUsuario?['apartamento'] ?? '';

      _nivel = _dadosUsuario?['nivel'] ?? 'Iniciante';

      if (!mounted) return;

      setState(() {
        _carregando = false;
      });
    } catch (e) {
      debugPrint("======================================");
      debugPrint("ERRO AO CARREGAR PERFIL");
      debugPrint(e.toString());
      debugPrint("======================================");

      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao carregar perfil:\n$e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _salvarPerfil() async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) return;

    final uid = usuario.uid;

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

  Widget _estatistica(String valor, String titulo, IconData icone) {
    return Expanded(
      child: Column(
        children: [
          Icon(icone, color: Colors.green.shade900, size: 24),
          const SizedBox(height: 6),
          Text(
            valor,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
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

    final pontos = _dadosUsuario?['pontos'] ?? 1000;
    final vitorias = _dadosUsuario?['vitorias'] ?? 0;
    final derrotas = _dadosUsuario?['derrotas'] ?? 0;
    final partidas = _dadosUsuario?['partidas'] ?? 0;

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

            const SizedBox(height: 15),

            Center(
              child: Text(
                _dadosUsuario?['nome'] ?? 'Jogador',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 5),

            Center(
              child: Text(
                _dadosUsuario?['nivel'] ?? 'Iniciante',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              ),
            ),

            const SizedBox(height: 25),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 10,
                ),
                child: Column(
                  children: [
                    const Text(
                      "Estatísticas",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        _estatistica(
                          pontos.toString(),
                          "Pontos",
                          Icons.emoji_events,
                        ),
                        _estatistica(
                          partidas.toString(),
                          "Partidas",
                          Icons.sports_tennis,
                        ),
                        _estatistica(
                          vitorias.toString(),
                          "Vitórias",
                          Icons.check_circle,
                        ),
                        _estatistica(
                          derrotas.toString(),
                          "Derrotas",
                          Icons.cancel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Informações pessoais",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

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
                if (valor == null) return;

                setState(() {
                  _nivel = valor;
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

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
