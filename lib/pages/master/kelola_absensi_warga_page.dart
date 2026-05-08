import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'detail_absensi_page.dart';

class KelolaAbsensiWargaPage extends StatefulWidget {
  const KelolaAbsensiWargaPage({super.key});

  @override
  State<KelolaAbsensiWargaPage> createState() => _KelolaAbsensiWargaPageState();
}

class _KelolaAbsensiWargaPageState extends State<KelolaAbsensiWargaPage> {
  final formatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

  // Fungsi untuk menampilkan dialog konfirmasi penghapusan
  Future<void> _confirmDelete(String jadwalId, String judulJadwal) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Pengguna harus menekan tombol
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Rekap Absensi?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Apakah Anda yakin ingin menghapus rekap absensi untuk jadwal ibadah pada tanggal $judulJadwal?',
                ),
                const Text('Tindakan ini tidak dapat dibatalkan.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteAbsensi(jadwalId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menghapus dokumen jadwal dari Firestore
  Future<void> _deleteAbsensi(String jadwalId) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    try {
      // Hapus semua absensi dengan jadwal_id ini
      final absensiSnapshot =
          await firestore
              .collection('absensi')
              .where('jadwal_id', isEqualTo: jadwalId)
              .get();

      for (var doc in absensiSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Terakhir, hapus dokumen jadwal
      final jadwalRef = firestore.collection('jadwal_ibadah').doc(jadwalId);
      batch.delete(jadwalRef);

      // Jalankan semua penghapusan sekaligus
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal dan absensi terkait berhasil dihapus!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus rekap absensi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Absensi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF5D4037),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('jadwal_ibadah')
                .orderBy('tanggal', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF5D4037)),
                  SizedBox(height: 16),
                  Text(
                    'Memuat jadwal...',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Terjadi kesalahan saat memuat data.',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada jadwal ibadah.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final jadwalList = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jadwalList.length,
            itemBuilder: (context, index) {
              final jadwal = jadwalList[index];
              final data = jadwal.data() as Map<String, dynamic>;
              final idJadwal = jadwal.id;
              final tanggal = (data['tanggal'] as Timestamp).toDate();
              final tempat = data['tempat'] ?? 'Tidak ada tempat';
              final waktuMulai = data['waktu_mulai'] ?? '-';
              final waktuSelesai = data['waktu_selesai'] ?? '-';
              final formattedDate = formatter.format(tanggal);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => DetailAbsensiPage(
                              jadwalId: idJadwal,
                              tempat: tempat,
                              tanggal: tanggal,
                              waktuMulai: waktuMulai,
                              waktuSelesai: waktuSelesai,
                            ),
                      ),
                    );
                  },
                  // Fitur baru: Menghapus item dengan long-press
                  onLongPress: () => _confirmDelete(idJadwal, formattedDate),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.event_note,
                              color: Color(0xFF795548),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5D4037),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: Colors.brown.shade200, height: 1),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Tempat',
                          tempat,
                          Icons.location_on_outlined,
                        ),
                        _buildInfoRow(
                          'Waktu',
                          '$waktuMulai - $waktuSelesai',
                          Icons.access_time,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Widget pembantu untuk menampilkan baris informasi dengan label
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.brown.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
