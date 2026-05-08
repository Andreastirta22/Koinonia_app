import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'rekap_sumbangan_page.dart';

class BeritaDariSumbanganPage extends StatelessWidget {
  const BeritaDariSumbanganPage({super.key});

  Future<List<Map<String, dynamic>>> _getBeritaDariSumbangan() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('sumbangan_berita').get();

    final Set<String> beritaIds =
        snapshot.docs.map((doc) => doc['berita_id'] as String).toSet();
    final List<Map<String, dynamic>> daftarBerita = [];

    for (final id in beritaIds) {
      final beritaDoc =
          await FirebaseFirestore.instance.collection('berita').doc(id).get();

      if (beritaDoc.exists) {
        final data = beritaDoc.data()!;
        data['id'] = id;
        daftarBerita.add(data);
      }
    }

    return daftarBerita;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Sumbangan'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getBeritaDariSumbangan(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada data sumbangan.'));
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final berita = list[index];
              final judul = berita['judul'] ?? '-';
              final tanggal = (berita['tanggal_mulai'] as Timestamp?)?.toDate();
              final formatter = DateFormat('dd MMM yyyy', 'id_ID');

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    judul,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle:
                      tanggal != null
                          ? Text('Mulai: ${formatter.format(tanggal)}')
                          : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => RekapSumbanganPage(beritaId: berita['id']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
