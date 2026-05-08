import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:koinonia/pages/warga/detail_berita_page.dart';

class BeritaWargaPage extends StatelessWidget {
  const BeritaWargaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Berita Terbaru',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF5D4037) : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('berita')
                  .orderBy('dibuat_pada', descending: true)
                  .limit(10)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text(
                'Terjadi kesalahan memuat berita.',
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text(
                'Belum ada berita terupdate.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
              );
            }

            final docs =
                snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'];

                  // Hanya tampilkan berita status aktif
                  if (status != 'aktif') return false;

                  // Cek tanggal selesai
                  final tglSelesai = data['tanggal_selesai'];
                  DateTime? tanggalSelesaiDate;

                  if (tglSelesai is Timestamp) {
                    tanggalSelesaiDate = tglSelesai.toDate();
                  } else if (tglSelesai is String && tglSelesai.isNotEmpty) {
                    tanggalSelesaiDate = DateTime.tryParse(tglSelesai);
                  }

                  // Kalau tanggal selesai sudah lewat, jangan tampilkan
                  if (tanggalSelesaiDate != null &&
                      tanggalSelesaiDate.isBefore(DateTime.now())) {
                    return false;
                  }

                  return true;
                }).toList();

            if (docs.isEmpty) {
              return Text(
                'Belum ada berita terupdate.',
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }

            return Column(
              children:
                  docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'aktif';

                    final subtitle =
                        status == 'aktif'
                            ? 'Klik untuk detail & sumbangan'
                            : 'Terima kasih atas partisipasinya';

                    final icon =
                        status == 'aktif' ? Icons.campaign : Icons.lock;

                    final badge = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white70 : Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                    );

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    DetailBeritaPage(data: data, docId: doc.id),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 28, color: Colors.brown),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          data['judul'] ?? 'Tanpa Judul',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ),
                                      badge,
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Theme.of(context).iconTheme.color,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }
}
