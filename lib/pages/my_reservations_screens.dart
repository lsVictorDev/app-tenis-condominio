import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyReservationsPage extends StatelessWidget {
  const MyReservationsPage({super.key});

  Future<void> _cancelarReserva(BuildContext context, String reservaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancelar reserva"),
        content: const Text("Deseja realmente cancelar esta reserva?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Não"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Sim, cancelar"),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await FirebaseFirestore.instance
          .collection("reservas")
          .doc(reservaId)
          .update({"status": "cancelada", "canceladaEm": Timestamp.now()});

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reserva cancelada com sucesso!")),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao cancelar reserva: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Minhas Reservas"),
          backgroundColor: Colors.green.shade900,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text("Usuário não autenticado.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Reservas"),
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("reservas")
            .where("usuarioId", isEqualTo: usuario.uid)
            .where("status", isEqualTo: "ativa")
            .orderBy("data", descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Erro ao carregar reservas:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final reservas = snapshot.data?.docs ?? [];

          if (reservas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 70, color: Colors.grey),
                    SizedBox(height: 20),
                    Text(
                      "Você ainda não possui reservas.",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Faça uma reserva para que ela apareça aqui.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservas.length,
            itemBuilder: (context, index) {
              final reserva = reservas[index];

              final dados = reserva.data() as Map<String, dynamic>;

              final data = dados["data"] ?? "";
              final quadra = dados["quadra"] ?? "";
              final horaInicio = dados["horaInicio"] ?? "";
              final horaFim = dados["horaFim"] ?? "";
              final status = dados["status"] ?? "ativa";

              String dataFormatada = data;

              try {
                final dataConvertida = DateTime.parse(data);

                dataFormatada = DateFormat("dd/MM/yyyy").format(dataConvertida);
              } catch (_) {}

              final reservaAtiva = status == "ativa";

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: reservaAtiva
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            child: Icon(
                              Icons.sports_tennis,
                              color: reservaAtiva
                                  ? Colors.green.shade900
                                  : Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: Text(
                              quadra,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: reservaAtiva
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              reservaAtiva ? "Ativa" : "Cancelada",
                              style: TextStyle(
                                color: reservaAtiva
                                    ? Colors.green.shade900
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 25),

                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            dataFormatada,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            "$horaInicio às $horaFim",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),

                      if (reservaAtiva) ...[
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _cancelarReserva(context, reserva.id);
                            },
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text("Cancelar reserva"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
