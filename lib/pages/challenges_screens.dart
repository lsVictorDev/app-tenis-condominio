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
                        "Erro ao carregar desafios:\n"
                        "${snapshot.error}",
                      ),
                    ),
                  );
                }

                final desafios =
                    snapshot.data?.docs ?? [];

                if (desafios.isEmpty) {
                  return _nenhumDesafioRecebido();
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
                      dadosDesafio: dados,
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

                final desafios =
                    snapshot.data?.docs ?? [];

                if (desafios.isEmpty) {
                  return _nenhumDesafioEnviado();
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
                      dadosDesafio: dados,
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

  Widget _nenhumDesafioRecebido() {
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

  Widget _nenhumDesafioEnviado() {
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
}

class _DesafioRecebidoCard
    extends StatefulWidget {
  final String desafioId;
  final String desafianteId;
  final Map<String, dynamic> dadosDesafio;

  const _DesafioRecebidoCard({
    required this.desafioId,
    required this.desafianteId,
    required this.dadosDesafio,
  });

  @override
  State<_DesafioRecebidoCard> createState() =>
      _DesafioRecebidoCardState();
}

class _DesafioRecebidoCardState
    extends State<_DesafioRecebidoCard> {
  bool _processando = false;

  Future<void> _responderDesafio(
    String novoStatus,
  ) async {
    if (_processando) return;

    setState(() {
      _processando = true;
    });

    try {
      final firestore =
          FirebaseFirestore.instance;

      // ============================================================
      // RECUSAR DESAFIO
      // ============================================================

      if (novoStatus == 'recusado') {
        await firestore
            .collection('desafios')
            .doc(widget.desafioId)
            .update({
          'status': 'recusado',
          'respondidoEm':
              FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Desafio recusado."),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      // ============================================================
      // ACEITAR DESAFIO
      //
      // IMPORTANTE:
      // O conflito de horário NÃO é mais verificado aqui.
      //
      // A validação de disponibilidade acontece quando o desafio
      // é enviado, na challenge_schedule_screens.dart.
      //
      // Ao aceitar, apenas criamos a reserva correspondente.
      // ============================================================

      final data =
          widget.dadosDesafio['data'] as String?;

      final quadra =
          widget.dadosDesafio['quadra'] as String?;

      final horaInicio =
          widget.dadosDesafio['horaInicio'] as String?;

      final horaFim =
          widget.dadosDesafio['horaFim'] as String?;

      if (data == null ||
          quadra == null ||
          horaInicio == null ||
          horaFim == null) {
        throw Exception(
          "As informações de data, horário ou quadra "
          "do desafio estão incompletas.",
        );
      }

      // ============================================================
      // BUSCA O USUÁRIO ATUAL
      // ============================================================

      final usuarioAtual =
          FirebaseAuth.instance.currentUser;

      if (usuarioAtual == null) {
        throw Exception(
          "Usuário não autenticado.",
        );
      }

      // ============================================================
      // BUSCA O JOGADOR QUE ENVIOU O DESAFIO
      // ============================================================

      final jogadorDesafiante =
          await firestore
              .collection('usuarios')
              .doc(widget.desafianteId)
              .get();

      final dadosJogador =
          jogadorDesafiante.data()
              as Map<String, dynamic>?;

      final emailDesafiante =
          dadosJogador?['email'] as String?;

      // ============================================================
      // CRIA A RESERVA DA PARTIDA
      // ============================================================

      final novaReserva =
          await firestore.collection('reservas').add({
        'usuarioId': usuarioAtual.uid,
        'email': usuarioAtual.email,
        'jogadorId': widget.desafianteId,
        'emailJogador': emailDesafiante,
        'quadra': quadra,
        'data': data,
        'horaInicio': horaInicio,
        'horaFim': horaFim,
        'tipo': 'desafio',
        'status': 'ativa',
        'desafioId': widget.desafioId,
        'criadoEm': Timestamp.now(),
      });

      // ============================================================
      // ATUALIZA O DESAFIO
      // ============================================================

      await firestore
          .collection('desafios')
          .doc(widget.desafioId)
          .update({
        'status': 'aceito',
        'respondidoEm':
            FieldValue.serverTimestamp(),
        'reservaId': novaReserva.id,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Desafio aceito e partida reservada com sucesso!",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Não foi possível aceitar o desafio:\n$e",
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

        final dadosUsuario =
            snapshot.data?.data()
                as Map<String, dynamic>?;

        final nome =
            dadosUsuario?['nome'] ?? 'Jogador';

        final pontos =
            dadosUsuario?['pontos'] ?? 1000;

        final nivel =
            dadosUsuario?['nivel'] ?? 'Iniciante';

        final data =
            widget.dadosDesafio['data'] ??
                'Não informada';

        final horaInicio =
            widget.dadosDesafio['horaInicio'] ??
                '--:--';

        final horaFim =
            widget.dadosDesafio['horaFim'] ??
                '--:--';

        final quadra =
            widget.dadosDesafio['quadra'] ??
                'Não informada';

        return Card(
          margin: const EdgeInsets.only(
            bottom: 15,
          ),
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
                              fontWeight:
                                  FontWeight.bold,
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

                const SizedBox(height: 20),

                _informacaoDesafio(
                  Icons.calendar_today,
                  "Data",
                  data,
                ),

                _informacaoDesafio(
                  Icons.access_time,
                  "Horário",
                  "$horaInicio às $horaFim",
                ),

                _informacaoDesafio(
                  Icons.sports_tennis,
                  "Quadra",
                  quadra,
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
                            : () =>
                                _responderDesafio(
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
                            : const Text(
                                "RECUSAR",
                              ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: _processando
                            ? null
                            : () =>
                                _responderDesafio(
                                  'aceito',
                                ),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.green.shade900,
                          foregroundColor:
                              Colors.white,
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
                            : const Text(
                                "ACEITAR",
                              ),
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

class _DesafioEnviadoCard
    extends StatelessWidget {
  final String desafiadoId;
  final String status;
  final Map<String, dynamic> dadosDesafio;

  const _DesafioEnviadoCard({
    required this.desafiadoId,
    required this.status,
    required this.dadosDesafio,
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

        final dadosUsuario =
            snapshot.data?.data()
                as Map<String, dynamic>?;

        final nome =
            dadosUsuario?['nome'] ?? 'Jogador';

        final data =
            dadosDesafio['data'] ??
                'Não informada';

        final horaInicio =
            dadosDesafio['horaInicio'] ??
                '--:--';

        final horaFim =
            dadosDesafio['horaFim'] ??
                '--:--';

        final quadra =
            dadosDesafio['quadra'] ??
                'Não informada';

        String statusTexto;

        switch (status) {
          case 'aceito':
            statusTexto = "Aceito";
            break;

          case 'recusado':
            statusTexto = "Recusado";
            break;

          default:
            statusTexto =
                "Aguardando resposta";
        }

        Color statusCor;

        if (status == 'aceito') {
          statusCor =
              Colors.green.shade800;
        } else if (status == 'recusado') {
          statusCor =
              Colors.red.shade700;
        } else {
          statusCor =
              Colors.orange.shade800;
        }

        return Card(
          margin: const EdgeInsets.only(
            bottom: 15,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      child: Icon(
                        Icons.sports_tennis,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                _informacaoDesafio(
                  Icons.calendar_today,
                  "Data",
                  data,
                ),

                _informacaoDesafio(
                  Icons.access_time,
                  "Horário",
                  "$horaInicio às $horaFim",
                ),

                _informacaoDesafio(
                  Icons.sports_tennis,
                  "Quadra",
                  quadra,
                ),

                const SizedBox(height: 10),

                Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    statusTexto,
                    style: TextStyle(
                      color: statusCor,
                      fontWeight:
                          FontWeight.bold,
                    ),
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

Widget _informacaoDesafio(
  IconData icone,
  String titulo,
  String valor,
) {
  return Padding(
    padding: const EdgeInsets.only(
      bottom: 10,
    ),
    child: Row(
      children: [
        Icon(
          icone,
          size: 21,
          color: Colors.green.shade800,
        ),
        const SizedBox(width: 10),
        Text(
          "$titulo: ",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(valor),
        ),
      ],
    ),
  );
}