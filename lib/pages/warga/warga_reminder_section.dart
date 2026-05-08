import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WargaReminderSection extends StatelessWidget {
  const WargaReminderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final formattedDate = formatter.format(now);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.notifications_active, color: Colors.orange),
        title: const Text(
          'Pengingat Hari Ini',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(formattedDate),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: () {
          // Navigasi ke halaman pengingat jika ada
        },
      ),
    );
  }
}
