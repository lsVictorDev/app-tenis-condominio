import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuarioAtual = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ranking"),
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .orderBy('pontos', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Erro ao carregar ranking:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final jogadores = snapshot.data?.docs ?? [];

          if (jogadores.isEmpty) {
            return const Center(
              child: Text(
                "Nenhum jogador encontrado.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jogadores.length,
            itemBuilder: (context, index) {
              final jogador =
                  jogadores[index].data() as Map<String, dynamic>;

              final nome = jogador['nome'] ?? 'Jogador';
              final pontos = jogador['pontos'] ?? 1000;
              final nivel = jogador['nivel'] ?? 'Iniciante';

              final vitorias = jogador['vitorias'] ?? 0;
              final derrotas = jogador['derrotas'] ?? 0;
              final partidas = jogador['partidas'] ?? 0;

              final uid = jogadores[index].id;
              final ehUsuarioAtual = uid == usuarioAtual?.uid;

              final posicao = index + 1;

              return _cardJogador(
                nome: nome,
                pontos: pontos,
                nivel: nivel,
                vitorias: vitorias,
                derrotas: derrotas,
                partidas: partidas,
                posicao: posicao,
                ehUsuarioAtual: ehUsuarioAtual,
              );
            },
          );
        },
      ),
    );
  }

  Widget _cardJogador({
    required String nome,
    required dynamic pontos,
    required String nivel,
    required dynamic vitorias,
    required dynamic derrotas,
    required dynamic partidas,
    required int posicao,
    required bool ehUsuarioAtual,
  }) {
    final bool primeiro = posicao == 1;
    final bool segundo = posicao == 2;
    final bool terceiro = posicao == 3;

    IconData? medalha;

    if (primeiro) {
      medalha = Icons.emoji_events;
    } else if (segundo) {
      medalha = Icons.emoji_events;
    } else if (terceiro) {
      medalha = Icons.emoji_events;
    }

    return Card(
      elevation: ehUsuarioAtual ? 6 : 3,
      margin: const EdgeInsets.only(bottom: 15),
      color: ehUsuarioAtual ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: posicao <= 3
                      ? Colors.amber.shade100
                      : Colors.grey.shade200,
                  child: medalha != null
                      ? Icon(
                          medalha,
                          color: Colors.orange.shade800,
                          size: 30,
                        )
                      : Text(
                          "$posicaoº",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nome,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          if (ehUsuarioAtual)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade900,
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "VOCÊ",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        nivel,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$pontos",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    Text(
                      "pontos",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _estatistica(
                  Icons.sports_tennis,
                  "$partidas",
                  "Partidas",
                ),
                _estatistica(
                  Icons.check_circle,
                  "$vitorias",
                  "Vitórias",
                ),
                _estatistica(
                  Icons.cancel,
                  "$derrotas",
                  "Derrotas",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _estatistica(
    IconData icone,
    String valor,
    String titulo,
  ) {
    return Column(
      children: [
        Icon(
          icone,
          size: 22,
          color: Colors.green,
        ),
        const SizedBox(height: 5),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}