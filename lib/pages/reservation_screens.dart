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
  bool _carregandoHorarios = false;

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

  Set<String> _horariosOcupados = {};

  Future<void> _carregarHorariosOcupados() async {
    setState(() {
      _carregandoHorarios = true;
      _horariosOcupados = {};
    });

    try {
      final dataReserva =
          DateFormat("yyyy-MM-dd").format(_dataSelecionada);

      final reservas = await FirebaseFirestore.instance
          .collection("reservas")
          .where(
            "quadra",
            isEqualTo: _quadraSelecionada,
          )
          .where(
            "data",
            isEqualTo: dataReserva,
          )
          .where(
            "status",
            isEqualTo: "ativa",
          )
          .get();

      final Set<String> horariosOcupados = {};

      for (final reserva in reservas.docs) {
        final dados = reserva.data();

        final horaInicio =
            dados["horaInicio"] as String;

        final horaFim =
            dados["horaFim"] as String;

        final inicio =
            int.parse(horaInicio.split(":")[0]);

        final fim =
            int.parse(horaFim.split(":")[0]);

        for (int hora = inicio; hora < fim; hora++) {
          horariosOcupados.add(
            "${hora.toString().padLeft(2, '0')}:00",
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _horariosOcupados = horariosOcupados;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Não foi possível verificar os horários: $e",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregandoHorarios = false;
        });
      }
    }
  }

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

      await _carregarHorariosOcupados();
    }
  }

  Future<void> _reservarQuadra() async {
    if (_reservando) return;

    setState(() {
      _reservando = true;
    });

    try {
      final usuario =
          FirebaseAuth.instance.currentUser;

      if (usuario == null) {
        throw Exception("Usuário não autenticado.");
      }

      final dataReserva =
          DateFormat("yyyy-MM-dd")
              .format(_dataSelecionada);

      final horaInicio =
          _horarioSelecionado;

      final hora = int.parse(
        _horarioSelecionado.split(":")[0],
      );

      final horaFim =
          "${(hora + 2).toString().padLeft(2, '0')}:00";

      final inicioNovaReserva = hora;
      final fimNovaReserva = hora + 2;

      final reservas =
          await FirebaseFirestore.instance
              .collection("reservas")
              .where(
                "quadra",
                isEqualTo: _quadraSelecionada,
              )
              .where(
                "data",
                isEqualTo: dataReserva,
              )
              .where(
                "status",
                isEqualTo: "ativa",
              )
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
                "$horarioFimExistente. "
                "Você pode reservar novamente "
                "a partir das $horarioFimExistente.",
              ),
            ),
          );

          await _carregarHorariosOcupados();

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

      await _carregarHorariosOcupados();
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

  Widget _horarioButton(String horario) {
    final ocupado =
        _horariosOcupados.contains(horario);

    final selecionado =
        _horarioSelecionado == horario;

    return GestureDetector(
      onTap: ocupado
          ? null
          : () {
              setState(() {
                _horarioSelecionado = horario;
              });
            },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: ocupado
              ? Colors.red.shade50
              : selecionado
                  ? Colors.green.shade900
                  : Colors.green.shade50,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: ocupado
                ? Colors.red.shade300
                : selecionado
                    ? Colors.green.shade900
                    : Colors.green.shade300,
            width: selecionado ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              ocupado
                  ? Icons.lock_outline
                  : selecionado
                      ? Icons.check_circle
                      : Icons.access_time,
              color: ocupado
                  ? Colors.red.shade700
                  : selecionado
                      ? Colors.white
                      : Colors.green.shade900,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              horario,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ocupado
                    ? Colors.red.shade700
                    : selecionado
                        ? Colors.white
                        : Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              ocupado
                  ? "Ocupado"
                  : "Disponível",
              style: TextStyle(
                fontSize: 11,
                color: ocupado
                    ? Colors.red.shade700
                    : selecionado
                        ? Colors.white70
                        : Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarHorariosOcupados();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada =
        DateFormat("dd/MM/yyyy")
            .format(_dataSelecionada);

    final horaSelecionada = int.parse(
      _horarioSelecionado.split(":")[0],
    );

    final horaFimSelecionada =
        "${(horaSelecionada + 2).toString().padLeft(2, '0')}:00";

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Reservar Quadra"),
        backgroundColor:
            Colors.green.shade900,
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

            const SizedBox(height: 25),

            const Text(
              "Data",
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            InkWell(
              onTap: _selecionarData,
              borderRadius:
                  BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 18,
                ),
                decoration:
                    BoxDecoration(
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
                    Text(
                      dataFormatada,
                      style:
                          const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.edit_calendar,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Quadra",
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _quadraSelecionada,
              decoration:
                  const InputDecoration(
                border:
                    OutlineInputBorder(),
              ),
              items:
                  _quadras.map((quadra) {
                return DropdownMenuItem(
                  value: quadra,
                  child: Text(quadra),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _quadraSelecionada =
                      value;
                });

                _carregarHorariosOcupados();
              },
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Horários",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (_carregandoHorarios)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              "Cada reserva tem duração de 2 horas.",
              style: TextStyle(
                color:
                    Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 15),

            if (_carregandoHorarios)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 30,
                ),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount:
                    _horarios.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.65,
                ),
                itemBuilder:
                    (context, index) {
                  return _horarioButton(
                    _horarios[index],
                  );
                },
              ),

            const SizedBox(height: 30),

            Container(
              padding:
                  const EdgeInsets.all(18),
              decoration:
                  BoxDecoration(
                color:
                    Colors.green.shade50,
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color:
                      Colors.green.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Resumo da reserva",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(dataFormatada),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(
                        Icons.sports_tennis,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        _quadraSelecionada,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        "$_horarioSelecionado às "
                        "$horaFimSelecionada",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 55,
              child:
                  ElevatedButton.icon(
                icon: _reservando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check,
                      ),
                label: Text(
                  _reservando
                      ? "VERIFICANDO..."
                      : "CONFIRMAR RESERVA",
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.green.shade900,
                  foregroundColor:
                      Colors.white,
                ),
                onPressed: _reservando
                    ? null
                    : _reservarQuadra,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color:
                      Colors.green.shade700,
                ),
                const SizedBox(width: 5),
                const Text(
                  "Disponível",
                ),
                const SizedBox(width: 20),
                Icon(
                  Icons.circle,
                  size: 12,
                  color:
                      Colors.red.shade700,
                ),
                const SizedBox(width: 5),
                const Text(
                  "Ocupado",
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}