import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class JadwalIbadahWidget extends StatefulWidget {
  final String userId; // user login wajib dikirim
  const JadwalIbadahWidget({super.key, required this.userId});

  @override
  State<JadwalIbadahWidget> createState() => _JadwalIbadahWidgetState();
}

class _JadwalIbadahWidgetState extends State<JadwalIbadahWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown(DateTime target) {
    final difference = target.difference(DateTime.now());
    if (difference.isNegative) return "Sedang berlangsung / lewat";
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;
    return "${days}d ${hours}h ${minutes}m ${seconds}s";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('jadwal_ibadah')
              .orderBy('tanggal', descending: false)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            'Tidak ada jadwal ibadah.',
            style: TextStyle(color: Colors.grey),
          );
        }

        final now = DateTime.now();
        final docs = snapshot.data!.docs;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final namaIbadah = data['nama'] ?? '-';
            final tanggal = data['tanggal'] as Timestamp?;
            final jam = data['jam'] ?? '-';
            final kategori = data['kategori'] ?? '-';
            final tempat = data['tempat'] ?? '-';

            if (tanggal == null) return const SizedBox();
            final tanggalIbadah = tanggal.toDate();

            final isToday =
                tanggalIbadah.year == now.year &&
                tanggalIbadah.month == now.month &&
                tanggalIbadah.day == now.day;

            return StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('absensi')
                      .doc('${docs[index].id}_${widget.userId}')
                      .snapshots(),
              builder: (context, absenSnap) {
                final sudahAbsen = absenSnap.hasData && absenSnap.data!.exists;

                return GestureDetector(
                  onTap:
                      isToday && !sudahAbsen
                          ? () async {
                            // Simpan absen ke koleksi global "absensi"
                            await FirebaseFirestore.instance
                                .collection('absensi')
                                .doc('${docs[index].id}_${widget.userId}')
                                .set({
                                  'userId': widget.userId,
                                  'jadwalId': docs[index].id,
                                  'timestamp': DateTime.now(),
                                });
                          }
                          : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          sudahAbsen
                              ? Colors.grey.shade300
                              : (isToday
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isToday
                                ? Colors.green.shade200
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          sudahAbsen
                              ? Icons.check_circle
                              : (isToday
                                  ? Icons.event_available
                                  : Icons.lock_clock),
                          color:
                              sudahAbsen
                                  ? Colors.green
                                  : (isToday ? Colors.blue : Colors.grey),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaIbadah,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kategori: $kategori',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              Text(
                                'Tempat: $tempat',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(tanggalIbadah)}, $jam',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              if (!sudahAbsen)
                                Text(
                                  'Countdown: ${_formatCountdown(tanggalIbadah)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                const Text(
                                  '✅ Anda sudah absen',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
