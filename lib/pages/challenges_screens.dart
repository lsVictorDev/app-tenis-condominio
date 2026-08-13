import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChallengesPage extends StatelessWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuarioAtual = FirebaseAuth.instance.currentUser;

    if (usuarioAtual == null) {
      return const Scaffold(
        body: Center(
          child: Text("Usuário não autenticado."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Desafios"),
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Desafios recebidos",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('desafios')
                  .where(
                    'desafiadoId',
                    isEqualTo: usuarioAtual.uid,
                  )
                  .where(
                    'status',
                    isEqualTo: 'pendente',
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "Erro ao carregar desafios:\n${snapshot.error}",
                      ),
                    ),
                  );
                }

                final desafios = snapshot.data?.docs ?? [];

                if (desafios.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Nenhum desafio recebido",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Quando outro jogador desafiar você, "
                            "o desafio aparecerá aqui.",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: desafios.map((desafio) {
                    final dados =
                        desafio.data()
                            as Map<String, dynamic>;

                    final desafianteId =
                        dados['desafianteId'] as String;

                    return _DesafioRecebidoCard(
                      desafioId: desafio.id,
                      desafianteId: desafianteId,
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 30),

            const Text(
              "Meus desafios",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('desafios')
                  .where(
                    'desafianteId',
                    isEqualTo: usuarioAtual.uid,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "Erro ao carregar seus desafios:\n"
                        "${snapshot.error}",
                      ),
                    ),
                  );
                }

                final desafios = snapshot.data?.docs ?? [];

                if (desafios.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(Icons.sports_tennis),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Nenhum desafio enviado",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Os desafios que você enviar "
                                  "aparecerão aqui.",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: desafios.map((desafio) {
                    final dados =
                        desafio.data()
                            as Map<String, dynamic>;

                    final desafiadoId =
                        dados['desafiadoId'] as String;

                    final status =
                        dados['status'] ?? 'pendente';

                    return _DesafioEnviadoCard(
                      desafiadoId: desafiadoId,
                      status: status,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DesafioRecebidoCard extends StatefulWidget {
  final String desafioId;
  final String desafianteId;

  const _DesafioRecebidoCard({
    required this.desafioId,
    required this.desafianteId,
  });

  @override
  State<_DesafioRecebidoCard> createState() =>
      _DesafioRecebidoCardState();
}

class _DesafioRecebidoCardState
    extends State<_DesafioRecebidoCard> {
  bool _processando = false;

  Future<void> _responderDesafio(String novoStatus) async {
    if (_processando) return;

    setState(() {
      _processando = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('desafios')
          .doc(widget.desafioId)
          .update({
        'status': novoStatus,
        'respondidoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            novoStatus == 'aceito'
                ? "Desafio aceito!"
                : "Desafio recusado.",
          ),
          backgroundColor: novoStatus == 'aceito'
              ? Colors.green
              : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Não foi possível responder ao desafio:\n$e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.desafianteId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final dados =
            snapshot.data?.data()
                as Map<String, dynamic>?;

        final nome = dados?['nome'] ?? 'Jogador';
        final pontos = dados?['pontos'] ?? 1000;
        final nivel = dados?['nivel'] ?? 'Iniciante';

        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$nivel • $pontos pontos",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Este jogador desafiou você!",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _processando
                            ? null
                            : () => _responderDesafio(
                                  'recusado',
                                ),
                        child: _processando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("RECUSAR"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _processando
                            ? null
                            : () => _responderDesafio(
                                  'aceito',
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.green.shade900,
                          foregroundColor: Colors.white,
                        ),
                        child: _processando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("ACEITAR"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DesafioEnviadoCard extends StatelessWidget {
  final String desafiadoId;
  final String status;

  const _DesafioEnviadoCard({
    required this.desafiadoId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(desafiadoId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final dados =
            snapshot.data?.data()
                as Map<String, dynamic>?;

        final nome = dados?['nome'] ?? 'Jogador';

        String statusTexto;

        switch (status) {
          case 'aceito':
            statusTexto = "Aceito";
            break;
          case 'recusado':
            statusTexto = "Recusado";
            break;
          default:
            statusTexto = "Aguardando resposta";
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.sports_tennis),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        statusTexto,
                        style: TextStyle(
                          color: status == 'aceito'
                              ? Colors.green.shade800
                              : status == 'recusado'
                                  ? Colors.red.shade700
                                  : Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}