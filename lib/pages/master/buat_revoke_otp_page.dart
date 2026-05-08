import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:koinonia/services/absen_gaptek_auto.dart';

class BuatRevokeOtpPage extends StatefulWidget {
  const BuatRevokeOtpPage({super.key});

  @override
  State<BuatRevokeOtpPage> createState() => _BuatRevokeOtpPageState();
}

class _BuatRevokeOtpPageState extends State<BuatRevokeOtpPage> {
  final formatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

  /// Generate OTP 4 digit
  String _generateOtp() {
    final random = Random();
    return List.generate(4, (_) => random.nextInt(10)).join();
  }

  /// Revoke kode OTP lama dan generate OTP baru
  Future<void> _revokeDanGenerateOtp(String docId) async {
    try {
      // 1️⃣ Hapus kode OTP lama
      await FirebaseFirestore.instance
          .collection('jadwal_ibadah')
          .doc(docId)
          .update({'kode_otp': FieldValue.delete()});

      // 2️⃣ Generate OTP baru 4 digit
      final otp = _generateOtp();
      print('Generated OTP: $otp'); // debug untuk memastikan 4 digit

      // 3️⃣ Simpan OTP baru ke Firestore
      await FirebaseFirestore.instance
          .collection('jadwal_ibadah')
          .doc(docId)
          .update({
            'kode_otp': otp,
            'updated_at': FieldValue.serverTimestamp(),
          });

      // 4️⃣ Jalankan fungsi tambahan tanpa menimpa OTP
      await tandaiHadirOtomatisUntukWargaGaptek(docId);

      // 5️⃣ Notifikasi ke pengguna
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP baru $otp berhasil disimpan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan OTP: $e')));
    }
  }

  /// Hapus kode OTP lama saja
  Future<void> _hapusOtp(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('jadwal_ibadah')
          .doc(docId)
          .update({'kode_otp': FieldValue.delete()});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode OTP berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus OTP: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kode OTP Ibadah'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('jadwal_ibadah')
                .where('tanggal', isGreaterThanOrEqualTo: today)
                .where('tanggal', isLessThan: tomorrow)
                .orderBy('tanggal')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Tidak ada jadwal ibadah hari ini.'),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final tanggal = (data['tanggal'] as Timestamp).toDate();
              final tempat = data['tempat'] ?? '-';
              final otp = data['kode_otp'];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatter.format(tanggal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tempat: $tempat',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      if (otp != null) ...[
                        Text(
                          'Kode OTP: $otp',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _hapusOtp(doc.id),
                              icon: const Icon(Icons.delete),
                              label: const Text('Hapus OTP'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () => _revokeDanGenerateOtp(doc.id),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Generate Baru'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Text(
                          'Belum ada kode OTP',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _revokeDanGenerateOtp(doc.id),
                          icon: const Icon(Icons.key),
                          label: const Text('Generate & Simpan OTP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
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
