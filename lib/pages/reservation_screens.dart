import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  DateTime _dataSelecionada = DateTime.now();

  String _quadraSelecionada = "Quadra 1";
  String _horarioSelecionado = "18:00";

  bool _reservando = false;

  final List<String> _quadras = [
    "Quadra 1",
    "Quadra 2",
  ];

  final List<String> _horarios = [
    "07:00",
    "08:00",
    "09:00",
    "10:00",
    "11:00",
    "12:00",
    "13:00",
    "14:00",
    "15:00",
    "16:00",
    "17:00",
    "18:00",
    "19:00",
    "20:00",
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

  Future<void> _reservarQuadra() async {
    if (_reservando) return;

    setState(() {
      _reservando = true;
    });

    try {
      final usuario = FirebaseAuth.instance.currentUser;

      if (usuario == null) {
        throw Exception("Usuário não autenticado.");
      }

      final dataReserva =
          DateFormat("yyyy-MM-dd").format(_dataSelecionada);

      final horaInicio = _horarioSelecionado;

      final hora = int.parse(
        _horarioSelecionado.split(":")[0],
      );

      final horaFim =
          "${(hora + 2).toString().padLeft(2, '0')}:00";

      final inicioNovaReserva = hora;
      final fimNovaReserva = hora + 2;

      final reservas = await FirebaseFirestore.instance
          .collection("reservas")
          .where("quadra", isEqualTo: _quadraSelecionada)
          .where("data", isEqualTo: dataReserva)
          .where("status", isEqualTo: "ativa")
          .get();

      for (final reserva in reservas.docs) {
        final dados = reserva.data();

        final horarioExistente =
            dados["horaInicio"] as String;

        final horarioFimExistente =
            dados["horaFim"] as String;

        final inicioExistente = int.parse(
          horarioExistente.split(":")[0],
        );

        final fimExistente = int.parse(
          horarioFimExistente.split(":")[0],
        );

        final existeConflito =
            inicioNovaReserva < fimExistente &&
            fimNovaReserva > inicioExistente;

        if (existeConflito) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Quadra indisponível. "
                "Ela já está reservada das "
                "$horarioExistente às "
                "$horarioFimExistente.",
              ),
            ),
          );

          return;
        }
      }

      await FirebaseFirestore.instance
          .collection("reservas")
          .add({
        "usuarioId": usuario.uid,
        "email": usuario.email,
        "quadra": _quadraSelecionada,
        "data": dataReserva,
        "horaInicio": horaInicio,
        "horaFim": horaFim,
        "tipo": "reserva",
        "status": "ativa",
        "criadoEm": Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Reserva realizada com sucesso!",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erro ao reservar: $e",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _reservando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada =
        DateFormat("dd/MM/yyyy").format(_dataSelecionada);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservar Quadra"),
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
                  borderRadius:
                      BorderRadius.circular(12),
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
                return DropdownMenuItem(
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
                return DropdownMenuItem(
                  value: hora,
                  child: Text(hora),
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
                icon: _reservando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _reservando
                      ? "VERIFICANDO..."
                      : "RESERVAR",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.green.shade900,
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    _reservando ? null : _reservarQuadra,
              ),
            ),
          ],
        ),
      ),
    );
  }
}