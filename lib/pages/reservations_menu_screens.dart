import 'package:flutter/material.dart';

import 'reservation_screens.dart';
import 'my_reservations_screens.dart';

class ReservationsMenuPage extends StatelessWidget {
  const ReservationsMenuPage({super.key});

  Widget _opcao(
    BuildContext context,
    String titulo,
    String descricao,
    IconData icone,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.green.shade100,
                child: Icon(icone, color: Colors.green.shade900, size: 30),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      descricao,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservas"),
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.calendar_month, size: 80, color: Colors.green),

            const SizedBox(height: 20),

            const Text(
              "Gerenciar reservas",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              "Escolha uma opção abaixo.",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
            ),

            const SizedBox(height: 30),

            _opcao(
              context,
              "Reservar Quadra",
              "Escolha data, quadra e horário.",
              Icons.add_circle_outline,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReservationPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            _opcao(
              context,
              "Minhas Reservas",
              "Veja e gerencie suas reservas.",
              Icons.event_note,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyReservationsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
