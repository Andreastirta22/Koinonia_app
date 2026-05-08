import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class RiwayatAbsensiWargaPage extends StatefulWidget {
  const RiwayatAbsensiWargaPage({super.key});

  @override
  State<RiwayatAbsensiWargaPage> createState() =>
      _RiwayatAbsensiWargaPageState();
}

class _RiwayatAbsensiWargaPageState extends State<RiwayatAbsensiWargaPage> {
  String? uid;
  List<Map<String, dynamic>> absensiList = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    uid = prefs.getString('uid');

    if (uid == null) return;

    final List<Map<String, dynamic>> hasil = [];

    final jadwalSnapshot =
        await FirebaseFirestore.instance
            .collection('jadwal_ibadah')
            .orderBy('tanggal', descending: true)
            .get();

    for (var jadwalDoc in jadwalSnapshot.docs) {
      final jadwalData = jadwalDoc.data();
      final tanggal = (jadwalData['tanggal'] as Timestamp).toDate();
      final validUntil = (jadwalData['valid_until'] as Timestamp).toDate();
      final tempat = jadwalData['tempat'] ?? '-';
      final jadwalId = jadwalDoc.id;

      final now = DateTime.now();

      final absensiSnapshot =
          await FirebaseFirestore.instance
              .collection('absensi')
              .where('jadwal_id', isEqualTo: jadwalId)
              .where('user_id', isEqualTo: uid)
              .get();

      String status;
      if (tanggal.isAfter(now)) {
        status = 'Ibadah belum dimulai';
      } else {
        status = absensiSnapshot.docs.isNotEmpty ? 'Hadir' : 'Tidak Hadir';
      }

      hasil.add({
        'tanggal': tanggal,
        'tempat': tempat,
        'status': status,
        'jam_mulai': tanggal,
        'jam_selesai': validUntil,
      });
    }

    setState(() {
      absensiList = hasil;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi Saya'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : absensiList.isEmpty
              ? const Center(child: Text("Belum ada riwayat absensi."))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: absensiList.length,
                itemBuilder: (context, index) {
                  final item = absensiList[index];
                  final tanggalFormatted = DateFormat(
                    'EEEE, dd MMMM yyyy',
                    'id_ID',
                  ).format(item['tanggal']);

                  final jamMulai = DateFormat.Hm().format(item['jam_mulai']);
                  final jamSelesai = DateFormat.Hm().format(
                    item['jam_selesai'],
                  );
                  final status = item['status'];
                  final isHadir = status == 'Hadir';
                  final belumMulai = status == 'Ibadah belum dimulai';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color:
                        isHadir
                            ? const Color(0xFFE8F5E9) // hijau muda
                            : belumMulai
                            ? const Color(0xFFE0E0E0) // abu muda
                            : const Color(0xFFFFEBEE), // merah muda
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isHadir
                                    ? Icons.check_circle
                                    : belumMulai
                                    ? Icons.hourglass_top
                                    : Icons.cancel,
                                color:
                                    isHadir
                                        ? Colors.green
                                        : belumMulai
                                        ? Colors.grey
                                        : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tanggalFormatted,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 18,
                                color: Colors.brown,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Waktu: $jamMulai - $jamSelesai',
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.brown,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tempat: ${item['tempat']}',
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.brown,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Status: $status',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isHadir
                                          ? Colors.green
                                          : belumMulai
                                          ? Colors.grey
                                          : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
