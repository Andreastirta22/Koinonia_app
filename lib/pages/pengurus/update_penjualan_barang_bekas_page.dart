import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UpdatePenjualanBarangBekasPage extends StatefulWidget {
  const UpdatePenjualanBarangBekasPage({super.key});

  @override
  State<UpdatePenjualanBarangBekasPage> createState() =>
      _UpdatePenjualanBarangBekasPageState();
}

class _UpdatePenjualanBarangBekasPageState
    extends State<UpdatePenjualanBarangBekasPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jumlahController = TextEditingController();

  String? selectedDocId;
  int? nominal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Hasil Penjualan Barang Bekas'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pilih Data Sumbangan yang Belum Terjual',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('barang_bekas')
                      .where('status', isEqualTo: 'menunggu_penjualan')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text(
                    'Tidak ada sumbangan yang menunggu hasil penjualan.',
                  );
                }

                return DropdownButtonFormField<String>(
                  value: selectedDocId,
                  hint: const Text('Pilih Sumbangan'),
                  items:
                      docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final jenis = data['jenis_barang'] ?? 'Barang';
                        final jumlah = data['jumlah'] ?? '';
                        final tanggal = (data['tanggal'] as Timestamp).toDate();
                        final formatted = DateFormat(
                          'dd MMM yyyy',
                        ).format(tanggal);
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text('$jenis - $jumlah ($formatted)'),
                        );
                      }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedDocId = val;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Penjualan (Rp)',
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(),
                ),
                validator:
                    (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                if (!_formKey.currentState!.validate() ||
                    selectedDocId == null) {
                  return;
                }

                final jumlah = int.parse(_jumlahController.text);
                final docRef = FirebaseFirestore.instance
                    .collection('barang_bekas')
                    .doc(selectedDocId);
                final snapshot = await docRef.get();
                final data = snapshot.data() as Map<String, dynamic>;

                // Simpan ke koleksi keuangan
                await FirebaseFirestore.instance.collection('keuangan').add({
                  'kategori': 'Pemasukan',
                  'jumlah': jumlah,
                  'keterangan':
                      'Penjualan ${data['jenis_barang']} dari kegiatan ${data['tanggal']}',
                  'tanggal': Timestamp.now(),
                  'tipe': 'pemasukan',
                });

                // Update status barang bekas
                await docRef.update({'status': 'sudah_terjual'});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data penjualan berhasil diupdate'),
                  ),
                );

                setState(() {
                  selectedDocId = null;
                  _jumlahController.clear();
                });
              },
              icon: const Icon(Icons.check),
              label: const Text('Simpan Hasil Penjualan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
