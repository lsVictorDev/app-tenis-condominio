import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'challenge_schedule_screens.dart';

class PlayerProfilePage extends StatelessWidget {
  final String jogadorId;
  final Map<String, dynamic> jogador;

  const PlayerProfilePage({
    super.key,
    required this.jogadorId,
    required this.jogador,
  });

  Future<void> _desafiarJogador(BuildContext context) async {
    final usuarioAtual = FirebaseAuth.instance.currentUser;

    if (usuarioAtual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Você precisa estar logado para desafiar."),
        ),
      );
      return;
    }

    // Impede o usuário de desafiar a si mesmo.
    if (usuarioAtual.uid == jogadorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Você não pode desafiar a si mesmo.")),
      );
      return;
    }

    final nomeJogador = jogador['nome'] ?? 'Jogador';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Desafiar jogador"),
        content: Text("Deseja realmente desafiar $nomeJogador?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade900,
              foregroundColor: Colors.white,
            ),
            child: const Text("Desafiar"),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final firestore = FirebaseFirestore.instance;

      // Busca desafios enviados pelo usuário atual
      // que ainda estão pendentes.
      final desafiosPendentes = await firestore
          .collection('desafios')
          .where('desafianteId', isEqualTo: usuarioAtual.uid)
          .where('status', isEqualTo: 'pendente')
          .get();

      // Verifica se já existe um desafio pendente
      // para esse mesmo jogador.
      for (final desafio in desafiosPendentes.docs) {
        final dados = desafio.data();

        if (dados['desafiadoId'] == jogadorId) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Você já enviou um desafio para este jogador."),
            ),
          );

          return;
        }
      }

      // Limite de 2 desafios enviados nos últimos 7 dias.
      final agora = DateTime.now();
      final limite = agora.subtract(const Duration(days: 7));

      final desafiosEnviados = await firestore
          .collection('desafios')
          .where('desafianteId', isEqualTo: usuarioAtual.uid)
          .get();

      int quantidadeUltimos7Dias = 0;

      for (final desafio in desafiosEnviados.docs) {
        final dados = desafio.data();
        final criadoEm = dados['criadoEm'];

        if (criadoEm is Timestamp) {
          final dataDesafio = criadoEm.toDate();

          if (dataDesafio.isAfter(limite)) {
            quantidadeUltimos7Dias++;
          }
        }
      }

      if (quantidadeUltimos7Dias >= 2) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Você já atingiu o limite de 2 desafios "
              "nos últimos 7 dias.",
            ),
          ),
        );

        return;
      }

      // Cria o desafio.
      await firestore.collection('desafios').add({
        'desafianteId': usuarioAtual.uid,
        'desafiadoId': jogadorId,
        'status': 'pendente',
        'criadoEm': Timestamp.now(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Desafio enviado para $nomeJogador!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao enviar desafio: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = jogador['nome'] ?? 'Jogador';
    final pontos = jogador['pontos'] ?? 1000;
    final nivel = jogador['nivel'] ?? 'Iniciante';
    final vitorias = jogador['vitorias'] ?? 0;
    final derrotas = jogador['derrotas'] ?? 0;
    final partidas = jogador['partidas'] ?? 0;

    final usuarioAtual = FirebaseAuth.instance.currentUser;
    final ehUsuarioAtual = usuarioAtual?.uid == jogadorId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil do Jogador"),
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const CircleAvatar(radius: 55, child: Icon(Icons.person, size: 60)),

            const SizedBox(height: 20),

            Center(
              child: Text(
                nome,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                nivel,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
            ),

            const SizedBox(height: 30),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "$pontos",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const Text("pontos", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _estatistica(Icons.sports_tennis, "$partidas", "Partidas"),
                    _estatistica(Icons.check_circle, "$vitorias", "Vitórias"),
                    _estatistica(Icons.cancel, "$derrotas", "Derrotas"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Não mostra o botão para desafiar a si mesmo.
            if (!ehUsuarioAtual)
              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChallengeSchedulePage(
                          jogadorId: jogadorId,
                          nomeJogador: nome,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.sports_tennis),
                  label: const Text(
                    "DESAFIAR JOGADOR",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade900,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _estatistica(IconData icone, String valor, String titulo) {
    return Column(
      children: [
        Icon(icone, color: Colors.green, size: 24),
        const SizedBox(height: 5),
        Text(
          valor,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          titulo,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
