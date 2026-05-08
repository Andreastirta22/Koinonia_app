import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Kelas ini diimpor dari file kelola_absensi_warga_page.dart
// Pastikan struktur kelas ini sudah sesuai
class DetailAbsensiPage extends StatefulWidget {
  final String jadwalId;
  final String tempat;
  final DateTime tanggal;
  final String waktuMulai;
  final String waktuSelesai;

  const DetailAbsensiPage({
    super.key,
    required this.jadwalId,
    required this.tempat,
    required this.tanggal,
    required this.waktuMulai,
    required this.waktuSelesai,
  });

  @override
  State<DetailAbsensiPage> createState() => _DetailAbsensiPageState();
}

class _DetailAbsensiPageState extends State<DetailAbsensiPage> {
  final formatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

  // Fungsi untuk menandai kehadiran. Sekarang tidak lagi membutuhkan 'setState' karena menggunakan StreamBuilder
  Future<void> tandaiHadir(String userId, String nama) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('absensi')
              .where('jadwal_id', isEqualTo: widget.jadwalId)
              .where('user_id', isEqualTo: userId)
              .get();

      if (snapshot.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('absensi').add({
          'user_id': userId,
          'nama': nama,
          'jadwal_id': widget.jadwalId,
          'waktu': Timestamp.now(),
        });
      }
    } catch (e) {
      // Tangani error, misal dengan menampilkan pesan di konsol
      debugPrint('Error menandai hadir: $e');
    }
  }

  // Fungsi untuk menghapus status absen
  Future<void> hapusAbsen(String userId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('absensi')
              .where('jadwal_id', isEqualTo: widget.jadwalId)
              .where('user_id', isEqualTo: userId)
              .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error menghapus absen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Absensi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown.shade800,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header informasi jadwal
            Text(
              'Ibadah di: ${widget.tempat}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text('Tanggal: ${formatter.format(widget.tanggal)}'),
            Text('Jam: ${widget.waktuMulai} - ${widget.waktuSelesai}'),
            const Divider(height: 24, thickness: 1.5),
            const Text(
              'Daftar Absensi Warga:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 16),
            // Menggunakan StreamBuilder untuk semua data absensi
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'warga')
                        .snapshots(),
                builder: (context, snapshotUsers) {
                  if (snapshotUsers.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshotUsers.hasData ||
                      snapshotUsers.data!.docs.isEmpty) {
                    return const Center(child: Text('Tidak ada data warga.'));
                  }

                  final users = snapshotUsers.data!.docs;

                  return StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('absensi')
                            .where('jadwal_id', isEqualTo: widget.jadwalId)
                            .snapshots(),
                    builder: (context, snapshotAbsen) {
                      if (snapshotAbsen.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final hadirIds =
                          snapshotAbsen.data?.docs
                              .map((e) => e['user_id'])
                              .toSet() ??
                          {};

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final nama = user['nama'];
                          final userId = user.id;
                          final hadir = hadirIds.contains(userId);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color:
                                    hadir
                                        ? Colors.green.shade400
                                        : Colors.red.shade400,
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 16.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        hadir
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color:
                                            hadir ? Colors.green : Colors.red,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nama,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            hadir ? 'Hadir' : 'Tidak Hadir',
                                            style: TextStyle(
                                              color:
                                                  hadir
                                                      ? Colors.green.shade700
                                                      : Colors.red.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: hadir,
                                    activeColor: Colors.green,
                                    inactiveThumbColor: Colors.red,
                                    onChanged: (val) async {
                                      if (val) {
                                        await tandaiHadir(userId, nama);
                                      } else {
                                        await hapusAbsen(userId);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
