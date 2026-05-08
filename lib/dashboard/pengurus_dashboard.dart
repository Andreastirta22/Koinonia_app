import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:koinonia/pages/pengurus/tambah_keuangan_page.dart';
import 'package:koinonia/pages/pengurus/daftar_keuangan_page.dart';
import 'package:koinonia/pages/pengurus/pengurus_jadwal_ibadah_page.dart';
import 'package:koinonia/login_page.dart';
import 'package:koinonia/pages/pengurus/form_trivia_pengurus.dart';
import 'package:koinonia/pages/pengurus/upload_dokumentasi_pengurus.dart';
import 'package:intl/intl.dart';
import 'package:koinonia/data/LaporanPage.dart';

class PengurusDashboard extends StatefulWidget {
  const PengurusDashboard({super.key});

  @override
  State<PengurusDashboard> createState() => _PengurusDashboardState();
}

class _PengurusDashboardState extends State<PengurusDashboard>
    with SingleTickerProviderStateMixin {
  String? nama;
  String? jenisKelamin;
  late TabController _tabController;

  int totalWarga = 0;
  double totalPemasukan = 0.0;
  double totalPengeluaran = 0.0;
  int kegiatanBulanIni = 0;
  int absensiHariIni = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadUserData();
    loadDashboardStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');

    if (uid != null) {
      try {
        final snapshot =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (snapshot.exists) {
          setState(() {
            nama = snapshot['nama'];
            jenisKelamin = snapshot['jenis_kelamin'];
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> loadDashboardStats() async {
    try {
      final wargaQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'warga')
              .get();

      // Hitung saldo keuangan
      final keuanganQuery =
          await FirebaseFirestore.instance.collection('keuangan').get();
      double pemasukan = 0, pengeluaran = 0;
      for (var doc in keuanganQuery.docs) {
        final data = doc.data();
        // Cek apakah 'jumlah' adalah null, jika ya, beri nilai default 0
        final jumlah = (data['jumlah'] as num?)?.toDouble() ?? 0.0;
        if (data['jenis'] == 'pemasukan') {
          pemasukan += jumlah;
        } else {
          pengeluaran += jumlah;
        }
      }

      // Hitung kegiatan bulan ini
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final kegiatanQuery =
          await FirebaseFirestore.instance
              .collection('jadwal_ibadah')
              .where('tanggal', isGreaterThanOrEqualTo: startOfMonth)
              .get();

      setState(() {
        totalWarga = wargaQuery.docs.length;
        // Simpan total pemasukan dan pengeluaran
        totalPemasukan = pemasukan;
        totalPengeluaran = pengeluaran;
        kegiatanBulanIni = kegiatanQuery.docs.length;
        // Absensi hari ini masih hardcode, perlu diimplementasikan
        absensiHariIni = 0;
      });
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  String getSalam() {
    final hour = DateTime.now().hour;
    if (hour < 11) return "Selamat pagi";
    if (hour < 15) return "Selamat siang";
    if (hour < 18) return "Selamat sore";
    return "Selamat malam";
  }

  @override
  Widget build(BuildContext context) {
    final sapaan = (jenisKelamin == 'laki-laki') ? 'Pak' : 'Bu';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${getSalam()}, $sapaan ${nama ?? ''}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Dashboard Pengurus',
              style: TextStyle(fontSize: 12, color: Colors.brown.shade200),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF8D6E63),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Tombol notifikasi
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(fontSize: 8, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => _showNotifications(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('uid');
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.brown.shade200,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            // Fixed the error by wrapping Icons.manage_accounts in an Icon widget
            Tab(icon: Icon(Icons.manage_accounts), text: 'Kelola'),
            Tab(icon: Icon(Icons.analytics), text: 'Laporan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildKelolaTab(),
          _buildLaporanTab(context),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistik Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildStatsCard(
                title: 'Total Warga',
                value: '$totalWarga',
                icon: Icons.people,
                color: Colors.blue,
              ),
              _buildStatsCard(
                title: 'Total Pemasukan', // Mengganti Saldo Keuangan
                // Ubah ikon dari Icons.attach_money ke Icons.payments
                value: _formatCurrency(totalPemasukan),
                icon: Icons.payments,
                color: Colors.green,
              ),
              _buildStatsCard(
                title: 'Kegiatan Bulan Ini',
                value: '$kegiatanBulanIni',
                icon: Icons.event,
                color: Colors.orange,
              ),
              _buildStatsCard(
                title: 'Absensi Hari Ini',
                value: '$absensiHariIni',
                icon: Icons.how_to_reg,
                color: Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Aksi Cepat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickAction(
                icon: Icons.add_chart,
                label: 'Tambah Keuangan',
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TambahKeuanganPage(),
                      ),
                    ),
              ),
              _buildQuickAction(
                icon: Icons.event_note,
                label: 'Jadwal Ibadah',
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PengurusJadwalIbadahPage(),
                      ),
                    ),
              ),
              _buildQuickAction(
                icon: Icons.photo_camera,
                label: 'Upload Foto',
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UploadDokumentasiPengurusPage(),
                      ),
                    ),
              ),
              _buildQuickAction(
                icon: Icons.announcement,
                label: 'Pengumuman',
                onTap: () => _showCreateAnnouncement(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Aktivitas Terbaru
          const Text(
            'Aktivitas Terbaru',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRecentActivities(),

          const SizedBox(height: 24),

          // Dokumentasi Terbaru
          const Text(
            'Dokumentasi Kegiatan Terbaru',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDocumentationCarousel(),
        ],
      ),
    );
  }

  Widget _buildKelolaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          buildCategorySection('Keuangan', Icons.account_balance, [
            MenuItemData(
              icon: Icons.add_chart_rounded,
              title: 'Tambah Data Keuangan',
              subtitle: 'Catat pemasukan atau pengeluaran',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TambahKeuanganPage(),
                    ),
                  ),
            ),
            MenuItemData(
              icon: Icons.list_alt_rounded,
              title: 'Lihat Daftar Keuangan',
              subtitle: 'Pantau semua data pemasukan dan pengeluaran',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DaftarKeuanganPage(),
                    ),
                  ),
            ),
          ]),
          buildCategorySection('Kegiatan & Ibadah', Icons.church, [
            MenuItemData(
              icon: Icons.event_note,
              title: 'Kelola Jadwal Ibadah',
              subtitle: 'Tambah dan lihat jadwal ibadah lingkungan',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PengurusJadwalIbadahPage(),
                    ),
                  ),
            ),
            MenuItemData(
              icon: Icons.lightbulb_outline,
              title: 'Kelola Trivia Gereja',
              subtitle:
                  'Tambahkan atau edit trivia menarik seputar iman Katolik',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TriviaPengurusPage(),
                    ),
                  ),
            ),
          ]),
          buildCategorySection('Warga & Komunitas', Icons.groups, [
            MenuItemData(
              icon: Icons.fact_check_rounded,
              title: 'Rekap Absensi Warga',
              subtitle: 'Lihat kehadiran seluruh warga',
              onTap: () => Navigator.pushNamed(context, '/rekap-absensi'),
            ),
            // MenuItemData(
            //   icon: Icons.person_add,
            //   title: 'Kelola Data Warga',
            //   subtitle: 'Tambah, edit, atau hapus data warga',
            //   onTap: () => _showComingSoon(),
            // ),
            // MenuItemData(
            //   icon: Icons.message,
            //   title: 'Kirim Pesan Massal',
            //   subtitle: 'Kirim pengumuman ke semua warga',
            //   onTap: () => _showComingSoon(),
            // ),
          ]),
          buildCategorySection('Konten & Media', Icons.content_paste, [
            MenuItemData(
              icon: Icons.newspaper,
              title: 'Kelola Berita Kegiatan',
              subtitle: 'Tambahkan informasi kegiatan terbaru',
              onTap: () => Navigator.pushNamed(context, '/kelola-berita'),
            ),
            MenuItemData(
              icon: Icons.photo_library,
              title: 'Upload Dokumentasi',
              subtitle: 'Unggah gambar kegiatan lingkungan',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UploadDokumentasiPengurusPage(),
                    ),
                  ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildLaporanTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Laporan & Analisis',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            mainAxisSpacing: 16,
            children: [
              _buildReportCard(
                title: 'Laporan Keuangan Bulanan',
                subtitle: 'Ringkasan pemasukan dan pengeluaran',
                icon: Icons.trending_up,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LaporanPage(initialIndex: 0),
                    ),
                  );
                },
              ),
              _buildReportCard(
                title: 'Statistik Kehadiran Warga',
                subtitle: 'Analisis kehadiran dalam ibadah',
                icon: Icons.bar_chart,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LaporanPage(initialIndex: 1),
                    ),
                  );
                },
              ),
              _buildReportCard(
                title: 'Laporan Kegiatan',
                subtitle: 'Dokumentasi dan evaluasi kegiatan',
                icon: Icons.assessment,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LaporanPage(initialIndex: 2),
                    ),
                  );
                },
              ),
              _buildReportCard(
                title: 'Export Data',
                subtitle: 'Unduh data dalam format Excel/PDF',
                icon: Icons.download,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LaporanPage(initialIndex: 3),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF8D6E63),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildCategorySection(
    String title,
    IconData categoryIcon,
    List<MenuItemData> items,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(categoryIcon, color: const Color(0xFF8D6E63)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => buildEnhancedCardMenu(
                icon: item.icon,
                title: item.title,
                subtitle: item.subtitle,
                onTap: item.onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEnhancedCardMenu({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF1EC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.brown.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(3, (index) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.brown.withOpacity(0.1),
                child: const Icon(Icons.history, color: Colors.brown),
              ),
              title: Text('Aktivitas ${index + 1}'),
              subtitle: const Text('Deskripsi aktivitas terbaru'),
              trailing: const Text(
                '2 jam lalu',
                style: TextStyle(fontSize: 12),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDocumentationCarousel() {
    return SizedBox(
      height: 120,
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('dokumentasi')
                .orderBy('created_at', descending: true)
                .limit(10)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada dokumentasi.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final imageUrl = data['url'];

              return Container(
                margin: const EdgeInsets.only(right: 12),
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Fungsi yang diperbaiki menggunakan NumberFormat untuk format mata uang
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Notifikasi'),
            content: const Text('Fitur notifikasi akan segera hadir!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showCreateAnnouncement() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Buat Pengumuman'),
            content: const Text('Fitur pengumuman akan segera hadir!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // void _showComingSoon(BuildContext context) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('Fitur ini akan segera hadir!'),
  //       backgroundColor: Colors.brown,
  //     ),
  //   );
  // }
}

class MenuItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
