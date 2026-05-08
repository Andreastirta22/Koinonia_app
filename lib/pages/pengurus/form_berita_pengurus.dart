import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:koinonia/pages/pengurus/rekap_sumbangan_page.dart';

class FormBeritaPengurus extends StatefulWidget {
  const FormBeritaPengurus({super.key});

  @override
  State<FormBeritaPengurus> createState() => _FormBeritaPengurusState();
}

class _FormBeritaPengurusState extends State<FormBeritaPengurus> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController judulController = TextEditingController();
  final TextEditingController isiController = TextEditingController();
  final TextEditingController lokasiController = TextEditingController();

  DateTime? tanggalMulai;
  DateTime? tanggalSelesai;
  TimeOfDay? jamSelesai;
  bool lihatKegiatanAktif = true;

  final Map<String, String> templateIsi = {
    'Barang Bekas': '''
♻️ *Ayo Beres-Beres dan Berbagi!*

Kami mengundang seluruh warga untuk ikut serta dalam kegiatan *pengumpulan barang bekas* demi mendukung kas lingkungan.

💡 *Yang bisa disumbangkan:*  
• Kardus  
• Kaleng  
• Plastik  
• Kertas, dll.

🤝 Mari kumpulkan barang bekasmu dan salurkan untuk kebaikan bersama!
''',
    'Penjualan Hasil Bumi': '''
🌾 *Panen Berkah Bersama!*

Warga akan mengadakan kegiatan *penjualan hasil bumi* lingkungan kita. Hasil dari penjualan ini akan masuk langsung ke kas lingkungan sebagai bentuk gotong royong kita!

🥬 *Hasil bumi yang dijual:*  
Sayur, buah, rempah-rempah, dan hasil tani warga lainnya.

💚 Ayo dukung dan beli hasil panen kita bersama!
''',
  };

  String? selectedTemplate;

  void applyTemplate(String? key) {
    if (key != null && templateIsi.containsKey(key)) {
      setState(() {
        selectedTemplate = key;
        judulController.text = key;
        isiController.text = templateIsi[key]!;
      });
    }
  }

  Future<void> simpanBerita() async {
    if (!_formKey.currentState!.validate() ||
        tanggalMulai == null ||
        tanggalSelesai == null ||
        jamSelesai == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');

    // gabungkan tanggal/jam/lokasi ke isi
    final formatter = DateFormat('EEEE, dd MMM yyyy', 'id_ID');
    final isiFinal =
        '${isiController.text}\n\n📆 Hari/Tanggal: ${formatter.format(tanggalMulai!)} - ${formatter.format(tanggalSelesai!)}\n🕙 Waktu: ${jamSelesai!.format(context)}\n📍 Lokasi: ${lokasiController.text}';

    try {
      await FirebaseFirestore.instance.collection('berita').add({
        'judul': judulController.text.trim(),
        'isi': isiFinal,
        'status': 'aktif',
        'dibuat_oleh': uid,
        'dibuat_pada': Timestamp.now(),
        'tanggal_mulai': tanggalMulai,
        'tanggal_selesai': tanggalSelesai,
        'jam_selesai': '${jamSelesai!.hour}:${jamSelesai!.minute}',
        'lokasi': lokasiController.text,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berita berhasil ditambahkan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan berita: $e')));
    }
  }

  Future<void> pickDate({required bool isMulai}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          tanggalMulai = picked;
        } else {
          tanggalSelesai = picked;
        }
      });
    }
  }

  Future<void> pickTimeSelesai() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        jamSelesai = picked;
      });
    }
  }

  Widget buildDatePicker({
    required String label,
    DateTime? date,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      readOnly: true,
      onTap: onTap,
      controller: TextEditingController(
        text: date != null ? DateFormat('dd MMM yyyy').format(date) : '',
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Berita Kegiatan'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedTemplate,
                  hint: const Text('Pilih Template Kegiatan'),
                  items:
                      templateIsi.keys
                          .map(
                            (key) =>
                                DropdownMenuItem(value: key, child: Text(key)),
                          )
                          .toList(),
                  onChanged: applyTemplate,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.auto_awesome),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: judulController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Berita',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Judul tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: isiController,
                  decoration: const InputDecoration(
                    labelText: 'Isi Berita',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? 'Isi berita tidak boleh kosong'
                              : null,
                ),
                const SizedBox(height: 16),
                buildDatePicker(
                  label: 'Tanggal Mulai',
                  date: tanggalMulai,
                  onTap: () => pickDate(isMulai: true),
                ),
                const SizedBox(height: 12),
                buildDatePicker(
                  label: 'Tanggal Selesai',
                  date: tanggalSelesai,
                  onTap: () => pickDate(isMulai: false),
                ),
                const SizedBox(height: 12),
                const Text('Jam Selesai'),
                const SizedBox(height: 6),
                TextFormField(
                  readOnly: true,
                  onTap: pickTimeSelesai,
                  controller: TextEditingController(
                    text: jamSelesai != null ? jamSelesai!.format(context) : '',
                  ),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (val) =>
                          val == null || val.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: lokasiController,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Lokasi tidak boleh kosong' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: simpanBerita,
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // ================= Daftar Kegiatan =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Kegiatan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    DropdownButton<bool>(
                      value: lihatKegiatanAktif,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: true,
                          child: Text('Sedang Berlangsung'),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text('Sudah Ditutup'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null)
                          setState(() => lihatKegiatanAktif = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('berita')
                          .orderBy('tanggal_mulai', descending: false)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final now = DateTime.now();

                    final filteredDocs =
                        docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'] ?? 'aktif';

                          // auto update status jika sudah lewat
                          final tanggalSelesai =
                              (data['tanggal_selesai'] as Timestamp).toDate();
                          final jamSelesai = data['jam_selesai'] ?? "23:59";
                          final parts = jamSelesai.split(":");
                          final endDateTime = DateTime(
                            tanggalSelesai.year,
                            tanggalSelesai.month,
                            tanggalSelesai.day,
                            int.parse(parts[0]),
                            int.parse(parts[1]),
                          );
                          if (endDateTime.isBefore(now) && status == 'aktif') {
                            FirebaseFirestore.instance
                                .collection('berita')
                                .doc(doc.id)
                                .update({'status': 'tutup'});
                          }

                          if (lihatKegiatanAktif) return status == 'aktif';
                          return status == 'tutup' || status == 'selesai';
                        }).toList();

                    if (filteredDocs.isEmpty) {
                      return Text(
                        lihatKegiatanAktif
                            ? 'Tidak ada kegiatan aktif saat ini.'
                            : 'Belum ada kegiatan yang ditutup.',
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final judul = data['judul'] ?? 'Tanpa Judul';
                        final status = data['status'] ?? 'aktif';
                        final tanggalMulai =
                            (data['tanggal_mulai'] as Timestamp).toDate();
                        final tanggalSelesai =
                            (data['tanggal_selesai'] as Timestamp).toDate();
                        final jamSelesai = data['jam_selesai'] ?? "23:59";
                        final formatter = DateFormat('dd MMM yyyy', 'id_ID');

                        // badge status
                        Color badgeColor;
                        String badgeText;
                        switch (status) {
                          case 'aktif':
                            badgeColor = Colors.green;
                            badgeText = 'Aktif';
                            break;
                          case 'tutup':
                            badgeColor = Colors.orange;
                            badgeText = 'Tutup';
                            break;
                          default:
                            badgeColor = Colors.grey;
                            badgeText = 'Selesai';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          RekapSumbanganPage(beritaId: doc.id),
                                ),
                              );
                            },
                            title: Text(
                              judul,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Mulai: ${formatter.format(tanggalMulai)}\n'
                              'Selesai: ${formatter.format(tanggalSelesai)} $jamSelesai',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
