import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class RekapSumbanganPage extends StatefulWidget {
  final String beritaId;
  final String? judulBerita;

  const RekapSumbanganPage({
    super.key,
    required this.beritaId,
    this.judulBerita,
  });

  @override
  State<RekapSumbanganPage> createState() => _RekapSumbanganPageState();
}

class _RekapSumbanganPageState extends State<RekapSumbanganPage> {
  bool isLoading = true;
  String? statusBerita;

  final List<Map<String, dynamic>> kategoriList = [];

  final _kategoriController = TextEditingController();
  final _hargaController = TextEditingController();
  final _beratController = TextEditingController();

  final currencyFormatter = NumberFormat("#,##0", "id_ID");

  @override
  void initState() {
    super.initState();
    _loadStatusBerita();
  }

  Future<void> _loadStatusBerita() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('berita')
            .doc(widget.beritaId)
            .get();
    statusBerita = doc['status'];
    setState(() {
      isLoading = false;
    });
  }

  double get totalPemasukan {
    double total = 0;
    for (var item in kategoriList) {
      final berat = item['berat'] as double?;
      final harga = item['harga'] as double?;
      if (berat != null && harga != null) {
        total += berat * harga;
      }
    }
    return total;
  }

  void _tambahKategori() {
    final nama = _kategoriController.text.trim();
    final harga = double.tryParse(_hargaController.text.trim());
    final berat = double.tryParse(_beratController.text.trim());

    if (nama.isEmpty || harga == null || berat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi nama, berat, dan harga dengan benar.'),
        ),
      );
      return;
    }

    setState(() {
      kategoriList.add({'nama': nama, 'harga': harga, 'berat': berat});
      _kategoriController.clear();
      _hargaController.clear();
      _beratController.clear();
    });
  }

  Future<void> _simpanKeuangan() async {
    if (totalPemasukan <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal satu kategori.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid') ?? 'pengurus';

    await FirebaseFirestore.instance.collection('keuangan').add({
      'tanggal': Timestamp.now(),
      'jumlah': totalPemasukan.toInt(),
      'kategori': 'Pemasukan',
      'keterangan': 'Hasil penjualan dari kegiatan barang bekas',
      'berita_id': widget.beritaId,
      'created_by': uid,
      'created_at': Timestamp.now(),
    });

    await FirebaseFirestore.instance
        .collection('berita')
        .doc(widget.beritaId)
        .update({
          'status': 'selesai',
          'total_pemasukan': totalPemasukan.toInt(),
        });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pemasukan berhasil dicatat!')),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildKategoriCard(Map<String, dynamic> item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(item['nama']),
        subtitle: Text(
          'Berat: ${item['berat']} kg, Harga: Rp ${currencyFormatter.format(item['harga'])}/kg',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              kategoriList.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.judulBerita ?? 'Input Hasil Sumbangan'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    ...kategoriList.asMap().entries.map(
                      (e) => _buildKategoriCard(e.value, e.key),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '+ Tambah Kategori Baru',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _kategoriController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kategori',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _beratController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Berat (kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _hargaController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Harga (Rp/kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _tambahKategori,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Total Pemasukan: Rp ${currencyFormatter.format(totalPemasukan)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _simpanKeuangan,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Keuangan & Tandai Selesai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
