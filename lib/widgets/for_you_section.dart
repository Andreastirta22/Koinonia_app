import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:koinonia/pages/warga/berita_acara_page.dart';
import 'package:koinonia/widgets/trivia_gereja_widget.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:async';

class ForYouSection extends StatelessWidget {
  const ForYouSection({super.key});

  // ====== Birthday Stream ======
  Stream<List<String>> getBirthdayMessages() {
    final today = DateFormat('MM-dd').format(DateTime.now());

    return FirebaseFirestore.instance.collection('users').snapshots().map((
      snapshot,
    ) {
      final List<String> birthdayList = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final nama = data['nama'];
        final tanggalLahir = data['tanggal_lahir'];

        if (tanggalLahir is Timestamp) {
          final dob = tanggalLahir.toDate();
          if (DateFormat('MM-dd').format(dob) == today) {
            birthdayList.add(nama);
          }
        } else if (tanggalLahir is String) {
          final dob = DateTime.tryParse(tanggalLahir);
          if (dob != null && DateFormat('MM-dd').format(dob) == today) {
            birthdayList.add(nama);
          }
        }
      }
      return birthdayList;
    });
  }

  // ====== Upcoming Jadwal Ibadah Stream ======
  Stream<QuerySnapshot<Map<String, dynamic>>> getUpcomingJadwalIbadah() {
    final now = DateTime.now();
    return FirebaseFirestore.instance
        .collection('jadwal_ibadah')
        .where('tanggal', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('tanggal')
        .snapshots();
  }

  // ====== Header ======
  Widget _buildSimpleHeaderWithDate() {
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agenda & Informasi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('EEEE, d MMMM', 'id_ID').format(DateTime.now()),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ====== Birthday Card ======
  Widget _buildBirthdayCard(List<String> birthdays) {
    if (birthdays.isEmpty) return const SizedBox.shrink();

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // Sudut lebih membulat
          boxShadow: [
            BoxShadow(
              color: Colors.pink.shade100.withOpacity(
                0.5,
              ), // Bayangan lebih cerah dan berwarna
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header dengan gradient subtle yang lebih menarik
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20), // Padding lebih besar
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.shade50,
                    Colors.pink.shade100.withOpacity(
                      0.7,
                    ), // Gradient yang lebih jelas
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(
                      10,
                    ), // Padding icon lebih besar
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        0.8,
                      ), // Warna latar belakang icon
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Sudut icon membulat
                    ),
                    child: Icon(
                      Icons.cake_outlined,
                      color:
                          Colors.pink.shade600, // Warna icon yang lebih gelap
                      size: 28, // Ukuran icon lebih besar
                    ),
                  ),
                  const SizedBox(width: 16), // Spasi lebih besar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, // Padding badge lebih besar
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    Colors
                                        .pink
                                        .shade200, // Warna badge yang lebih gelap
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ULANG TAHUN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w700, // Font lebih tebal
                                  color: Colors.pink.shade800,
                                  letterSpacing: 0.8, // Spasi huruf lebih lebar
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6), // Spasi lebih besar
                        Text(
                          birthdays.length > 1
                              ? '${birthdays.length} orang berulang tahun hari ini!' // Pesan lebih spesifik
                              : 'Selamat ulang tahun untukmu!', // Pesan lebih personal
                          style: const TextStyle(
                            fontSize: 16, // Ukuran font lebih besar
                            fontWeight: FontWeight.bold, // Font lebih tebal
                            color: Colors.black, // Warna teks lebih gelap
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content area
            Padding(
              padding: const EdgeInsets.all(20), // Padding lebih besar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Names section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16), // Padding lebih besar
                    decoration: BoxDecoration(
                      color:
                          Colors
                              .purple
                              .shade50, // Latar belakang yang berbeda untuk bagian nama
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 18, // Ukuran icon lebih besar
                              color: Colors.purple.shade700, // Warna icon
                            ),
                            const SizedBox(width: 8),
                            Text(
                              birthdays.length > 1
                                  ? 'Yang merayakan hari spesial ini:'
                                  : 'Nama yang berbahagia:',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10), // Spasi lebih besar
                        Wrap(
                          spacing: 8, // Spasi antar chip
                          runSpacing: 6, // Spasi antar baris chip
                          children:
                              birthdays
                                  .map(
                                    (name) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            12, // Padding chip lebih besar
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors
                                                .purple
                                                .shade100, // Warna chip yang cerah
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.purple.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight
                                                  .w700, // Font lebih tebal
                                          color: Colors.purple.shade800,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16), // Spasi lebih besar
                  // Blessing message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16), // Padding lebih besar
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.celebration_rounded, // Icon yang lebih meriah
                          size: 20,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Semoga Tuhan memberkati Anda dengan sukacita dan damai sejahtera di hari istimewa ini!', // Pesan yang lebih hangat
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== Jadwal Ibadah ======
  Widget _buildJadwalIbadahCard(
    String title,
    DateTime tanggal,
    String kategori,
    String tempat,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        Duration remaining = tanggal.difference(DateTime.now());
        bool isActive = remaining > Duration.zero;

        Timer? timer;
        if (isActive) {
          timer = Timer.periodic(const Duration(seconds: 1), (_) {
            final diff = tanggal.difference(DateTime.now());
            if (diff.isNegative) {
              timer?.cancel();
            }
            setState(() {
              remaining = diff.isNegative ? Duration.zero : diff;
            });
          });
        }

        // Helper method untuk menentukan warna berdasarkan kategori
        Color _getCategoryColor(String kategori) {
          switch (kategori.toLowerCase()) {
            case 'shalat':
              return Colors.green;
            case 'kajian':
              return Colors.blue;
            case 'khutbah':
              return Colors.purple;
            case 'doa':
              return Colors.orange;
            default:
              return Colors.grey;
          }
        }

        IconData _getCategoryIcon(String kategori) {
          switch (kategori.toLowerCase()) {
            case 'shalat':
              return Icons.mosque;
            case 'kajian':
              return Icons.menu_book_rounded;
            case 'khutbah':
              return Icons.campaign_rounded;
            case 'doa':
              return Icons.volunteer_activism_rounded;
            default:
              return Icons.event_rounded;
          }
        }

        Widget _buildTimeUnit(String value, String unit) {
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        int days = remaining.inDays;
        int hours = remaining.inHours % 24;
        int minutes = remaining.inMinutes % 60;
        int seconds = remaining.inSeconds % 60;

        final categoryColor = _getCategoryColor(kategori);
        final categoryIcon = _getCategoryIcon(kategori);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan kategori badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(categoryIcon, color: categoryColor, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  kategori.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: categoryColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content area
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date & Time Info
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat(
                            'EEEE, d MMM yyyy',
                            'id_ID',
                          ).format(tanggal),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            DateFormat('HH:mm').format(tanggal),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Location Info
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tempat,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Countdown Section
                    if (isActive) ...[
                      Text(
                        'Menuju waktu ibadah',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTimeUnit(
                            days.toString().padLeft(2, '0'),
                            'HARI',
                          ),
                          const SizedBox(width: 6),
                          _buildTimeUnit(
                            hours.toString().padLeft(2, '0'),
                            'JAM',
                          ),
                          const SizedBox(width: 6),
                          _buildTimeUnit(
                            minutes.toString().padLeft(2, '0'),
                            'MENIT',
                          ),
                          const SizedBox(width: 6),
                          _buildTimeUnit(
                            seconds.toString().padLeft(2, '0'),
                            'DETIK',
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.green.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sudah berlangsung',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ====== Section Header ======
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (color ?? Colors.deepPurple).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color ?? Colors.deepPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSimpleHeaderWithDate(),
            const SizedBox(height: 12),

            // Birthday Section
            StreamBuilder<List<String>>(
              stream: getBirthdayMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }
                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    _buildBirthdayCard(snapshot.data!),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),

            // Jadwal Ibadah Section
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: getUpcomingJadwalIbadah(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      snapshot.data!.docs.map((doc) {
                        final data = doc.data();
                        final title = data['title'] ?? '-';
                        final kategori = data['kategori'] ?? '-';
                        final tanggalIbadah =
                            (data['tanggal'] as Timestamp).toDate();
                        final tempat = data['tempat'] ?? '-';

                        return _buildJadwalIbadahCard(
                          title,
                          tanggalIbadah,
                          kategori,
                          tempat,
                        );
                      }).toList(),
                );
              },
            ),

            const SizedBox(height: 16),

            // Berita Section
            _buildSectionHeader(
              title: 'Berita & Pengumuman',
              icon: Icons.newspaper_rounded,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 16),
            const BeritaWargaPage(),

            const SizedBox(height: 16),

            // Trivia Section
            _buildSectionHeader(
              title: 'Trivia Gereja Katolik',
              icon: Icons.quiz_rounded,
              color: Colors.amber.shade600,
            ),
            const SizedBox(height: 12),
            const TriviaGerejaWidget(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
