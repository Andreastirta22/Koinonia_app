import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TambahKeuanganPage extends StatefulWidget {
  const TambahKeuanganPage({super.key});

  @override
  State<TambahKeuanganPage> createState() => _TambahKeuanganPageState();
}

class _TambahKeuanganPageState extends State<TambahKeuanganPage> {
  final TextEditingController jumlahController = TextEditingController();
  final TextEditingController manualKeteranganController =
      TextEditingController();

  String kategori = 'Pemasukan';
  String jenisPemasukan = 'Kolekte';
  String sumberDana = 'Kas Lingkungan';
  DateTime tanggalDipilih = DateTime.now();

  final jenisIkon = {
    'Kolekte': Icons.church,
    'Barang Bekas': Icons.recycling,
    'Penjualan Hasil Bumi': Icons.local_florist,
    'Lainnya': Icons.notes,
  };

  @override
  void initState() {
    super.initState();
    jumlahController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    jumlahController.dispose();
    manualKeteranganController.dispose();
    super.dispose();
  }

  Future<void> simpanKeuangan() async {
    final jumlahText = jumlahController.text.trim().replaceAll('.', '');
    final isManual = jenisPemasukan == 'Lainnya';
    final keterangan =
        isManual ? manualKeteranganController.text.trim() : jenisPemasukan;

    if (jumlahText.isEmpty || keterangan.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua field wajib diisi')),
        );
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');

    try {
      await FirebaseFirestore.instance.collection('keuangan').add({
        'tanggal': Timestamp.fromDate(tanggalDipilih),
        'kategori': kategori,
        'jumlah': int.parse(jumlahText),
        'keterangan': keterangan,
        'sumber_dana': sumberDana,
        'created_by': uid,
        'created_at': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data keuangan berhasil disimpan')),
        );
      }

      jumlahController.clear();
      manualKeteranganController.clear();
      setState(() {
        kategori = 'Pemasukan';
        jenisPemasukan = 'Kolekte';
        sumberDana = 'Kas Lingkungan';
        tanggalDipilih = DateTime.now();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  Future<void> pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: tanggalDipilih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.brown,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => tanggalDipilih = picked);
    }
  }

  String formatRupiah(String text) {
    if (text.isEmpty) return '';
    final number = int.tryParse(text.replaceAll('.', ''));
    if (number == null) return text;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(number).trim();
  }

  @override
  Widget build(BuildContext context) {
    final isPemasukan = kategori == 'Pemasukan';
    final isLainnya = jenisPemasukan == 'Lainnya';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Data Keuangan'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Form Keuangan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1.5,
                      color: Colors.brown,
                    ),

                    // Tanggal
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.brown,
                      ),
                      title: Text(
                        'Tanggal: ${DateFormat('dd MMMM yyyy', 'id_ID').format(tanggalDipilih)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: TextButton(
                        onPressed: pilihTanggal,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.brown,
                        ),
                        child: const Text('Ubah'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kategori
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.category,
                          color: Colors.brown,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: kategori,
                          items: const [
                            DropdownMenuItem(
                              value: 'Pemasukan',
                              child: Text('Pemasukan'),
                            ),
                            DropdownMenuItem(
                              value: 'Pengeluaran',
                              child: Text('Pengeluaran'),
                            ),
                          ],
                          onChanged:
                              (value) => setState(() {
                                kategori = value!;
                                if (kategori == 'Pengeluaran') {
                                  jenisPemasukan = 'Lainnya';
                                }
                              }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Jumlah (Tanpa Ikon, Hanya Teks 'Rp')
                    TextField(
                      controller: jumlahController,
                      keyboardType: TextInputType.number,
                      onChanged: (text) {
                        final formattedText = formatRupiah(text);
                        jumlahController.value = jumlahController.value
                            .copyWith(
                              text: formattedText,
                              selection: TextSelection.collapsed(
                                offset: formattedText.length,
                              ),
                            );
                      },
                      decoration: InputDecoration(
                        labelText: 'Jumlah',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.money,
                          color: Colors.brown,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Keterangan
                    if (isPemasukan) ...[
                      DropdownButtonFormField<String>(
                        value: jenisPemasukan,
                        items:
                            jenisIkon.keys.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Icon(jenisIkon[value], color: Colors.brown),
                                    const SizedBox(width: 10),
                                    Text(value),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged:
                            (value) => setState(() => jenisPemasukan = value!),
                        decoration: InputDecoration(
                          labelText: 'Jenis Pemasukan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(
                            Icons.notes,
                            color: Colors.brown,
                          ),
                        ),
                      ),
                      if (isLainnya) const SizedBox(height: 16),
                      if (isLainnya)
                        TextField(
                          controller: manualKeteranganController,
                          decoration: InputDecoration(
                            labelText: 'Keterangan Lainnya',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(
                              Icons.notes,
                              color: Colors.brown,
                            ),
                          ),
                        ),
                    ] else ...[
                      TextField(
                        controller: manualKeteranganController,
                        decoration: InputDecoration(
                          labelText: 'Keterangan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(
                            Icons.notes,
                            color: Colors.brown,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Sumber Dana
                    DropdownButtonFormField<String>(
                      value: sumberDana,
                      items: const [
                        DropdownMenuItem(
                          value: 'Kas Lingkungan',
                          child: Text('Kas Lingkungan'),
                        ),
                        DropdownMenuItem(
                          value: 'Donasi Luar',
                          child: Text('Donasi Luar'),
                        ),
                        DropdownMenuItem(
                          value: 'Subsidi Gereja',
                          child: Text('Subsidi Gereja'),
                        ),
                      ],
                      onChanged: (value) => setState(() => sumberDana = value!),
                      decoration: InputDecoration(
                        labelText: 'Sumber Dana',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.brown,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Simpan
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: simpanKeuangan,
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
