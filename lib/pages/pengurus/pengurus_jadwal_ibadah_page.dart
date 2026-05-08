import 'package:flutter/material.dart';

class PengurusJadwalIbadahPage extends StatelessWidget {
  const PengurusJadwalIbadahPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Jadwal Ibadah'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildCardMenu(
                  context: context,
                  icon: Icons.add,
                  title: 'Tambah Jadwal Ibadah',
                  subtitle: 'Input jadwal ibadah baru ke lingkungan',
                  routeName: '/tambah-jadwal',
                ),
                buildCardMenu(
                  context: context,
                  icon: Icons.view_list,
                  title: 'Lihat Daftar Jadwal',
                  subtitle: 'Lihat & hapus jadwal ibadah yang sudah dibuat',
                  routeName: '/daftar-jadwal',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCardMenu({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String routeName,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, routeName),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.brown,
                radius: 24,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.brown,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
