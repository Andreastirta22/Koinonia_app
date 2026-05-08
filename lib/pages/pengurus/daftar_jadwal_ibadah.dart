import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class DaftarJadwalIbadahPage extends StatefulWidget {
  const DaftarJadwalIbadahPage({super.key});

  @override
  State<DaftarJadwalIbadahPage> createState() => _DaftarJadwalIbadahPageState();
}

class _DaftarJadwalIbadahPageState extends State<DaftarJadwalIbadahPage> {
  String? userRole;
  String? selectedKategori = '-'; // default semua
  List<String> kategoriList = []; // daftar kategori unik

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadKategoriList();
  }

  // ================== LOAD USER ROLE ==================
  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid != null) {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        setState(() {
          userRole = snapshot['role'];
        });
      }
    }
  }

  // ================== LOAD KATEGORI UNIK ==================
  Future<void> _loadKategoriList() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('jadwal_ibadah')
            .orderBy('created_at', descending: true)
            .get();

    // saat load kategori
    final categories =
        snapshot.docs
            .map((doc) => (doc.data()['kategori'] ?? '').toString())
            .toSet() // unik
            .where((e) => e.isNotEmpty) // hapus string kosong
            .toList();

    setState(() {
      kategoriList = categories;
      selectedKategori ??= '-'; // default pilih semua
    });
  }

  // ================== HAPUS JADWAL ==================
  // ================== HAPUS JADWAL + ABSENSI ==================
  Future<void> _hapusJadwal(BuildContext context, String docId) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text(
              'Yakin ingin menghapus jadwal ini? Semua data absensi terkait juga akan dihapus.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (konfirmasi == true) {
      final firestore = FirebaseFirestore.instance;

      // Hapus semua absensi_warga terkait jadwal ini
      final absensiSnapshot =
          await firestore
              .collection('absensi')
              .where('jadwal_id', isEqualTo: docId)
              .get();

      for (var doc in absensiSnapshot.docs) {
        await firestore.collection('absensi').doc(doc.id).delete();
      }

      // Hapus dokumen jadwal
      await firestore.collection('jadwal_ibadah').doc(docId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jadwal & absensi terkait berhasil dihapus'),
          ),
        );
      }
    }
  }

  // ================== GENERATE OTP ==================
  Future<void> _generateOtp(String docId) async {
    final otp = List.generate(4, (_) => Random().nextInt(10)).join();
    await FirebaseFirestore.instance
        .collection('jadwal_ibadah')
        .doc(docId)
        .update({'kode_otp': otp, 'updated_at': FieldValue.serverTimestamp()});

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kode OTP berhasil: $otp')));
    }
  }

  // ================== HAPUS OTP ==================
  Future<void> _hapusOtp(String docId) async {
    await FirebaseFirestore.instance
        .collection('jadwal_ibadah')
        .doc(docId)
        .update({'kode_otp': FieldValue.delete()});

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP berhasil dihapus')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    // ================== QUERY FIRESTORE ==================
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('jadwal_ibadah')
        .orderBy('tanggal');

    if (selectedKategori != null && selectedKategori != '-') {
      query = query.where('kategori', isEqualTo: selectedKategori);
    }

    Stream<QuerySnapshot<Map<String, dynamic>>> jadwalStream =
        query.snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Jadwal Ibadah',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8D6E63),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ===== DROPDOWN FILTER =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: selectedKategori,
              decoration: const InputDecoration(
                labelText: 'Filter Kategori',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items:
                  ['-'] // default semua
                      .followedBy(kategoriList) // kategori unik dari Firestore
                      .map(
                        (kategori) => DropdownMenuItem(
                          value: kategori,
                          child: Text(kategori),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  selectedKategori = value;
                });
              },
            ),
          ),

          // ===== LIST JADWAL =====
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: jadwalStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Belum ada jadwal ibadah.'));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final tanggal = (data['tanggal'] as Timestamp).toDate();
                    final tempat = data['tempat'] ?? '-';
                    final kategori = data['kategori'] ?? '-';
                    final otp = data['kode_otp'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tanggal & Kategori sejajar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatter.format(tanggal),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5D4037),
                                ),
                              ),
                              Text(
                                kategori,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF795548),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tempat: $tempat',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF795548),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey.shade300, height: 1),
                          const SizedBox(height: 16),

                          // OTP dan tombol
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (userRole == 'master' ||
                                  userRole == 'pengurus')
                                if (otp != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.vpn_key_outlined,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'OTP: $otp',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  )
                                else if (userRole == 'master')
                                  ElevatedButton.icon(
                                    onPressed: () => _generateOtp(doc.id),
                                    icon: const Icon(Icons.key, size: 16),
                                    label: const Text(
                                      'Generate OTP',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF795548),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                              const Spacer(),
                              Row(
                                children: [
                                  if (userRole == 'master' && otp != null)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_forever,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _hapusOtp(doc.id),
                                      tooltip: 'Hapus Kode OTP',
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed:
                                        () => _hapusJadwal(context, doc.id),
                                    tooltip: 'Hapus Jadwal',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
