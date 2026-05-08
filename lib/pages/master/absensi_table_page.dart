import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AbsensiTablePage extends StatelessWidget {
  const AbsensiTablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabel Absensi'),
        backgroundColor: Colors.brown,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('absensi')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final absensiDocs = snapshot.data!.docs;

          if (absensiDocs.isEmpty) {
            return const Center(child: Text('Belum ada data absensi.'));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Nama Warga')),
                DataColumn(label: Text('Jadwal Ibadah')),
                DataColumn(label: Text('Hadir')),
                DataColumn(label: Text('Otomatis Gaptek')),
              ],
              rows:
                  absensiDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final hadir = data['hadir'] ?? false;
                    final otomatisGaptek = data['otomatis_gaptek'] ?? false;

                    return DataRow(
                      cells: [
                        DataCell(Text(data['nama'] ?? '-')),
                        DataCell(Text(data['jadwal'] ?? '-')),
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                hadir ? Icons.check_circle : Icons.cancel,
                                color: hadir ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(hadir.toString()),
                            ],
                          ),
                        ),
                        DataCell(
                          otomatisGaptek
                              ? const Text(
                                'Ya',
                                style: TextStyle(color: Colors.orange),
                              )
                              : const Text('Tidak'),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          );
        },
      ),
    );
  }
}
