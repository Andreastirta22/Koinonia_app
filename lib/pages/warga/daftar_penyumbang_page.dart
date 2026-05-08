import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DaftarPenyumbangPage extends StatelessWidget {
  final String beritaId;
  const DaftarPenyumbangPage({super.key, required this.beritaId});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd MMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Penyumbang'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('sumbangan_berita')
                .where('berita_id', isEqualTo: beritaId)
                .orderBy('tanggal_daftar', descending: false)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Belum ada warga yang menyumbang.'),
            );
          }

          final penyumbangList = snapshot.data!.docs;

          // 🔹 DEBUG LOG
          debugPrint("🔥 Data penyumbang untuk beritaId: $beritaId");
          for (var doc in penyumbangList) {
            debugPrint(doc.data().toString());
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: penyumbangList.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final data = penyumbangList[index].data() as Map<String, dynamic>;
              final nama = data['nama_warga'] ?? 'Warga';
              final tanggal = (data['tanggal_daftar'] as Timestamp?)?.toDate();

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.brown.shade300,
                  child: Text('${index + 1}'),
                ),
                title: Text(
                  nama,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  tanggal != null
                      ? '${dateFormat.format(tanggal)} • ${DateFormat.Hm('id_ID').format(tanggal)}'
                      : '-',
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.brown.shade50,
              );
            },
          );
        },
      ),
    );
  }
}
