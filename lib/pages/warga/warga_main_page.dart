import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WargaReminderSection extends StatefulWidget {
  const WargaReminderSection({super.key});

  @override
  State<WargaReminderSection> createState() => _WargaReminderSectionState();
}

class _WargaReminderSectionState extends State<WargaReminderSection> {
  Map<String, dynamic>? jadwalBerikutnya;
  List<Map<String, dynamic>> ulangTahunHariIni = [];

  @override
  void initState() {
    super.initState();
    fetchReminderData();
  }

  Future<void> fetchReminderData() async {
    final now = DateTime.now();

    // Jadwal Ibadah berikutnya
    final jadwalSnapshot =
        await FirebaseFirestore.instance
            .collection('jadwal_ibadah')
            .where('tanggal', isGreaterThan: Timestamp.fromDate(now))
            .orderBy('tanggal')
            .limit(1)
            .get();

    if (jadwalSnapshot.docs.isNotEmpty) {
      setState(() {
        jadwalBerikutnya = jadwalSnapshot.docs.first.data();
      });
    }

    // Ulang tahun hari ini
    final userSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'warga')
            .get();

    final today = DateTime.now();
    final List<Map<String, dynamic>> ultahList = [];

    for (var doc in userSnapshot.docs) {
      final data = doc.data();
      final tglLahir = (data['tanggal_lahir'] as Timestamp?)?.toDate();
      if (tglLahir != null &&
          tglLahir.day == today.day &&
          tglLahir.month == today.month) {
        ultahList.add(data);
      }
    }

    setState(() {
      ulangTahunHariIni = ultahList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tanggalFormatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (jadwalBerikutnya != null) ...[
          const Text(
            'Ibadah Selanjutnya',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.brown.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.brown.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 Tempat: ${jadwalBerikutnya!['tempat'] ?? '-'}'),
                const SizedBox(height: 4),
                Text(
                  '🗓️ Tanggal: ${tanggalFormatter.format((jadwalBerikutnya!['tanggal'] as Timestamp).toDate())}',
                ),
                if (jadwalBerikutnya!['waktu_mulai'] != null)
                  Text('🕒 Jam: ${jadwalBerikutnya!['waktu_mulai']}'),
              ],
            ),
          ),
        ],
        if (ulangTahunHariIni.isNotEmpty) ...[
          const Text(
            'Ulang Tahun Hari Ini',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.pink.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  ulangTahunHariIni
                      .map(
                        (user) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '🎉 Selamat ulang tahun ${user['nama']}!',
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ],
    );
  }
}
