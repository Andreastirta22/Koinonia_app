import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetailKeuanganPage extends StatelessWidget {
  const DetailKeuanganPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Keuangan'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('keuangan')
                .orderBy('tanggal', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada data keuangan.'));
          }

          final data = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index].data() as Map<String, dynamic>;
              final tanggal = (item['tanggal'] as Timestamp).toDate();
              final jumlah = item['jumlah'] ?? 0;
              final tipe = item['tipe'] ?? 'pemasukan';
              final keterangan = item['keterangan'] ?? '-';
              final warna = tipe == 'pemasukan' ? Colors.green : Colors.red;
              final simbol = tipe == 'pemasukan' ? '+' : '-';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: warna.withOpacity(0.1),
                    child: Icon(
                      tipe == 'pemasukan' ? Icons.download : Icons.upload,
                      color: warna,
                    ),
                  ),
                  title: Text(
                    '$simbol ${formatter.format(jumlah)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: warna),
                  ),
                  subtitle: Text(
                    '$keterangan\n${DateFormat('d MMM y', 'id_ID').format(tanggal)}',
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
