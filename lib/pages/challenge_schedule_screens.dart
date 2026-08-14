import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChallengeSchedulePage extends StatefulWidget {
  final String jogadorId;
  final String nomeJogador;

  const ChallengeSchedulePage({
    super.key,
    required this.jogadorId,
    required this.nomeJogador,
  });

  @override
  State<ChallengeSchedulePage> createState() => _ChallengeSchedulePageState();
}

class _ChallengeSchedulePageState extends State<ChallengeSchedulePage> {
  DateTime _dataSelecionada = DateTime.now();

  String _quadraSelecionada = "Quadra 1";

  // IMPORTANTE:
  // O horário inicial precisa existir dentro da lista _horarios.
  String _horarioSelecionado = "17:00";

  bool _enviando = false;

  final List<String> _quadras = [
    "Quadra 1",
    "Quadra 2",
  ];

  // Cada desafio dura 2 horas.
  //
  // Os horários são disponibilizados de 2 em 2 horas
  // para evitar sobreposição entre os próprios desafios.
  //
  // Exemplos:
  // 07:00 - 09:00
  // 09:00 - 11:00
  // 11:00 - 13:00
  //
  // Assim, um horário termina exatamente quando o próximo começa.
  final List<String> _horarios = [
    "07:00",
    "09:00",
    "11:00",
    "13:00",
    "15:00",
    "17:00",
    "19:00",
    "21:00",
  ];

  Future<void> _selecionarData() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      locale: const Locale("pt", "BR"),
    );

    if (data != null) {
      setState(() {
        _dataSelecionada = data;
      });
    }
  }

  Future<void> _enviarDesafio() async {
    if (_enviando) return;

    final usuarioAtual = FirebaseAuth.instance.currentUser;

    if (usuarioAtual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Você precisa estar logado para desafiar.",
          ),
        ),
      );
      return;
    }

    if (usuarioAtual.uid == widget.jogadorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Você não pode desafiar a si mesmo.",
          ),
        ),
      );
      return;
    }

    setState(() {
      _enviando = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // ============================================================
      // 1. VERIFICA SE JÁ EXISTE DESAFIO PENDENTE PARA ESTE JOGADOR
      // ============================================================

      final desafiosPendentes = await firestore
          .collection('desafios')
          .where(
            'desafianteId',
            isEqualTo: usuarioAtual.uid,
          )
          .where(
            'status',
            isEqualTo: 'pendente',
          )
          .get();

      for (final desafio in desafiosPendentes.docs) {
        final dados = desafio.data();

        if (dados['desafiadoId'] == widget.jogadorId) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Você já enviou um desafio para este jogador.",
              ),
            ),
          );

          return;
        }
      }

      // ============================================================
      // 2. LIMITE TEMPORÁRIO DE 100 DESAFIOS NOS ÚLTIMOS 7 DIAS
      // ============================================================

      final agora = DateTime.now();

      final limite = agora.subtract(
        const Duration(days: 7),
      );

      final desafiosEnviados = await firestore
          .collection('desafios')
          .where(
            'desafianteId',
            isEqualTo: usuarioAtual.uid,
          )
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

      if (quantidadeUltimos7Dias >= 100) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Você já atingiu o limite de 100 desafios "
              "nos últimos 7 dias.",
            ),
          ),
        );

        return;
      }

      // ============================================================
      // 3. DEFINE DATA E HORÁRIO DO DESAFIO
      // ============================================================

      final dataDesafio = DateFormat(
        "yyyy-MM-dd",
      ).format(_dataSelecionada);

      final horaInicio = _horarioSelecionado;

      final hora = int.parse(
        _horarioSelecionado.split(":")[0],
      );

      final horaFim =
          "${(hora + 2).toString().padLeft(2, '0')}:00";

      final inicioNovoDesafio = hora;
      final fimNovoDesafio = hora + 2;

      // ============================================================
      // 4. VERIFICA SE A QUADRA JÁ ESTÁ OCUPADA POR UMA RESERVA
      // ============================================================

      final reservas = await firestore
          .collection('reservas')
          .where(
            'quadra',
            isEqualTo: _quadraSelecionada,
          )
          .where(
            'data',
            isEqualTo: dataDesafio,
          )
          .where(
            'status',
            isEqualTo: 'ativa',
          )
          .get();

      for (final reserva in reservas.docs) {
        final dadosReserva = reserva.data();

        final horarioExistente =
            dadosReserva['horaInicio'] as String;

        final horarioFimExistente =
            dadosReserva['horaFim'] as String;

        final inicioExistente = int.parse(
          horarioExistente.split(":")[0],
        );

        final fimExistente = int.parse(
          horarioFimExistente.split(":")[0],
        );

        // Verifica se existe sobreposição de horários.
        //
        // Exemplo:
        // Reserva: 17:00 - 19:00
        // Desafio: 17:00 - 19:00
        // CONFLITO
        //
        // Reserva: 17:00 - 19:00
        // Desafio: 19:00 - 21:00
        // NÃO há conflito.
        final existeConflito =
            inicioNovoDesafio < fimExistente &&
            fimNovoDesafio > inicioExistente;

        if (existeConflito) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Não foi possível enviar o desafio.\n"
                "${_quadraSelecionada} já está ocupada "
                "das $horarioExistente às "
                "$horarioFimExistente.",
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );

          return;
        }
      }

      // ============================================================
      // 5. CRIA O DESAFIO
      // ============================================================

      await firestore.collection('desafios').add({
        'desafianteId': usuarioAtual.uid,
        'desafiadoId': widget.jogadorId,
        'status': 'pendente',
        'data': dataDesafio,
        'quadra': _quadraSelecionada,
        'horaInicio': horaInicio,
        'horaFim': horaFim,
        'criadoEm': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Desafio enviado para ${widget.nomeJogador}!",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erro ao enviar desafio: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat(
      "dd/MM/yyyy",
    ).format(_dataSelecionada);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Agendar Desafio"),
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Icon(
              Icons.sports_tennis,
              size: 80,
              color: Colors.green,
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                "Desafiar ${widget.nomeJogador}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Escolha a data, quadra e horário da partida.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Data",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            InkWell(
              onTap: _selecionarData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                    ),

                    const SizedBox(width: 10),

                    Text(dataFormatada),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Quadra",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _quadraSelecionada,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: _quadras.map((quadra) {
                return DropdownMenuItem<String>(
                  value: quadra,
                  child: Text(quadra),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _quadraSelecionada = value;
                });
              },
            ),

            const SizedBox(height: 25),

            const Text(
              "Horário",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _horarioSelecionado,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: _horarios.map((hora) {
                final horaInicio = int.parse(
                  hora.split(":")[0],
                );

                final horaFim =
                    "${(horaInicio + 2).toString().padLeft(2, '0')}:00";

                return DropdownMenuItem<String>(
                  value: hora,
                  child: Text(
                    "$hora - $horaFim",
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _horarioSelecionado = value;
                });
              },
            ),

            const SizedBox(height: 40),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _enviando
                    ? null
                    : _enviarDesafio,
                icon: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _enviando
                      ? "ENVIANDO..."
                      : "CONFIRMAR DESAFIO",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
}