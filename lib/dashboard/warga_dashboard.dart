import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../widgets/for_you_section.dart';
import '../pages/warga/riwayat_absensi_warga_page.dart';
import '../widgets/gallery_section.dart';
import 'package:koinonia/pages/warga/edit_profile_page.dart';
import '../pages/warga/jadwal_ibadah_page.dart';
import 'package:koinonia/pages/warga/DaftarKeuanganWarga.dart';

// Font google
import 'package:google_fonts/google_fonts.dart';

class UserData {
  final String nama;
  final String jenisKelamin;
  final String uid;
  final String? email;
  final String? noTelp;
  final DateTime? lastLogin;
  final DateTime? tanggalLahir;

  UserData({
    required this.nama,
    required this.jenisKelamin,
    required this.uid,
    this.email,
    this.noTelp,
    this.lastLogin,
    this.tanggalLahir,
  });

  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserData(
      nama: data['nama'] ?? '',
      jenisKelamin: data['jenis_kelamin'] ?? '',
      uid: doc.id,
      email: data['email'],
      noTelp: data['no_telp'],
      lastLogin:
          data['last_login'] != null
              ? (data['last_login'] as Timestamp).toDate()
              : null,
      tanggalLahir: (data['tanggal_lahir'] as Timestamp?)?.toDate(),
    );
  }
}

class KeuanganData {
  final int totalPemasukan;
  final int totalPengeluaran;
  final int thisMonthIncome;
  final int thisMonthExpense;

  KeuanganData({
    required this.totalPemasukan,
    required this.totalPengeluaran,
    this.thisMonthIncome = 0,
    this.thisMonthExpense = 0,
  });

  int get saldoAkhir => totalPemasukan - totalPengeluaran;
  int get thisMonthBalance => thisMonthIncome - thisMonthExpense;
}

// Model untuk attendance data
class AttendanceData {
  final int totalAttendance;
  final int thisMonthAttendance;
  final double attendancePercentage;
  final int thisMonthSchedules;

  AttendanceData({
    required this.totalAttendance,
    required this.thisMonthAttendance,
    required this.attendancePercentage,
    required this.thisMonthSchedules,
  });

  factory AttendanceData.fromMap(Map<String, dynamic> map) {
    return AttendanceData(
      totalAttendance: map['total_attendance'] ?? 0,
      thisMonthAttendance: map['this_month_attendance'] ?? 0,
      attendancePercentage: (map['attendance_percentage'] ?? 0).toDouble(),
      thisMonthSchedules: map['this_month_schedules'] ?? 0,
    );
  }

  get thisMonthSchedulesPast => null;
}

class WargaMainPage extends StatefulWidget {
  const WargaMainPage({super.key});

  @override
  State<WargaMainPage> createState() => _WargaMainPageState();
}

class _WargaMainPageState extends State<WargaMainPage> {
  UserData? userData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _loadUserData();
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  StreamSubscription<DocumentSnapshot>? _userSub;

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');

    if (uid == null) {
      throw Exception('User tidak terautentikasi');
    }

    // 🔥 Listen ke perubahan user doc (realtime sync)
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            setState(() {
              userData = UserData.fromFirestore(snapshot);
              isLoading = false;
            });
          }
        });

    // update last_login sekali aja
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'last_login': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _userSub?.cancel(); // jangan lupa biar gak leak
    super.dispose();
  }

  String _getSalam() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return "Selamat pagi";
    if (hour >= 11 && hour < 15) return "Selamat siang";
    if (hour >= 15 && hour < 18) return "Selamat sore";
    return "Selamat malam";
  }

  Widget _buildErrorWidget() {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFBF7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Ada yang salah',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Terjadi kesalahan',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                _initializeData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFBF7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.brown.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Memuat data...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.brown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingWidget();
    }

    if (errorMessage != null) {
      return _buildErrorWidget();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEFBF7),
      body: SafeArea(
        child: HomeSection(userData: userData!, salam: _getSalam()),
      ),
    );
  }
}

class HomeSection extends StatefulWidget {
  final UserData userData;
  final String salam;
  final VoidCallback? onRefresh;

  const HomeSection({
    super.key,
    required this.userData,
    required this.salam,
    this.onRefresh, // Tambahkan di constructor
  });

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection>
    with TickerProviderStateMixin {
  KeuanganData? keuanganData;
  AttendanceData? attendanceData;
  bool showSaldo = false;
  bool isLoadingKeuangan = true;
  bool isLoadingAttendance = true;
  int totalJadwal = 0;
  int hadir = 0;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  GlobalKey editProfileKey = GlobalKey();
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    _loadAllData();
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([_loadKeuangan(), _loadAttendanceData()]);
  }

  Future<void> _loadKeuangan() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('keuangan').get();
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);

      int pemasukan = 0;
      int pengeluaran = 0;
      int thisMonthIncome = 0;
      int thisMonthExpense = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final jumlah = data['jumlah'];
        final kategori = data['kategori'] ?? '';
        final tanggal =
            data['tanggal'] != null
                ? (data['tanggal'] as Timestamp).toDate()
                : DateTime.now();

        if (jumlah is int) {
          if (kategori == 'Pemasukan') {
            pemasukan += jumlah;
            if (tanggal.isAfter(currentMonth) ||
                (tanggal.year == currentMonth.year &&
                    tanggal.month == currentMonth.month)) {
              thisMonthIncome += jumlah;
            }
          } else if (kategori == 'Pengeluaran') {
            pengeluaran += jumlah;
            if (tanggal.isAfter(currentMonth) ||
                (tanggal.year == currentMonth.year &&
                    tanggal.month == currentMonth.month)) {
              thisMonthExpense += jumlah;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          keuanganData = KeuanganData(
            totalPemasukan: pemasukan,
            totalPengeluaran: pengeluaran,
            thisMonthIncome: thisMonthIncome,
            thisMonthExpense: thisMonthExpense,
          );
          isLoadingKeuangan = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingKeuangan = false;
        });
      }
    }
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      isLoadingAttendance = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('uid');
    if (userId == null) {
      setState(() => isLoadingAttendance = false);
      return;
    }

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    // ✅ Total semua absensi user
    final totalAbsensiSnap =
        await FirebaseFirestore.instance
            .collection('absensi')
            .where('user_id', isEqualTo: userId)
            .get();
    final totalAttendance = totalAbsensiSnap.docs.length;

    // ✅ Absensi bulan ini
    final thisMonthSnap =
        await FirebaseFirestore.instance
            .collection('absensi')
            .where('user_id', isEqualTo: userId)
            .where('waktu', isGreaterThanOrEqualTo: firstDay)
            .where('waktu', isLessThanOrEqualTo: lastDay)
            .get();
    final hadirCount = thisMonthSnap.docs.length;

    // ✅ Total jadwal bulan ini
    final jadwalSnap =
        await FirebaseFirestore.instance
            .collection('jadwal_ibadah')
            .where('tanggal', isGreaterThanOrEqualTo: firstDay)
            .where('tanggal', isLessThanOrEqualTo: lastDay)
            .get();
    final totalJadwalBulanIni = jadwalSnap.docs.length;

    if (mounted) {
      setState(() {
        attendanceData = AttendanceData(
          totalAttendance: totalAttendance,
          thisMonthAttendance: hadirCount,
          attendancePercentage:
              totalJadwalBulanIni == 0
                  ? 0
                  : (hadirCount / totalJadwalBulanIni) * 100,
          thisMonthSchedules: totalJadwalBulanIni,
        );
        isLoadingAttendance = false;
      });
    }
  }

  Future<int> _getUnreadNotifCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');
      if (uid == null) return 0;

      final futures = await Future.wait([
        FirebaseFirestore.instance
            .collection('berita')
            .where('status', whereIn: ['aktif', 'selesai'])
            .get(),
        FirebaseFirestore.instance.collection('keuangan').get(),
      ]);

      final beritaSnapshot = futures[0];
      final keuanganSnapshot = futures[1];

      int count = 0;

      for (var doc in beritaSnapshot.docs) {
        final dibacaOleh = List<String>.from(doc['dibaca_oleh'] ?? []);
        if (!dibacaOleh.contains(uid)) count++;
      }

      for (var doc in keuanganSnapshot.docs) {
        final dibacaOleh = List<String>.from(doc['dibaca_oleh'] ?? []);
        if (!dibacaOleh.contains(uid)) count++;
      }

      return count;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildNotifikasiIcon() {
    return FutureBuilder<int>(
      future: _getUnreadNotifCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.brown),
                tooltip: 'Notifikasi',
                onPressed: () async {
                  await Navigator.pushNamed(context, '/notifikasi');
                  if (mounted) setState(() {});
                },
              ),
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.logout, color: Colors.red.shade400),
                const SizedBox(width: 12),
                const Text('Konfirmasi Logout'),
              ],
            ),
            content: const Text(
              'Apakah Anda yakin ingin keluar dari aplikasi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (shouldLogout == true && context.mounted) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('uid');

        if (context.mounted) {
          Navigator.pop(context); // Menutup dialog loading
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal logout: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildSaldoCard() {
    if (isLoadingKeuangan) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: const Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Memuat data keuangan...'),
          ],
        ),
      );
    }

    if (keuanganData == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 16),
            Text('Gagal memuat data keuangan'),
          ],
        ),
      );
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DaftarKeuanganWargaPage()),
        );
      },

      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),

          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              offset: const Offset(0, 8),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => setState(() => showSaldo = !showSaldo),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      showSaldo ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Saldo Kas Lingkungan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              showSaldo
                  ? formatter.format(keuanganData!.saldoAkhir)
                  : '••••••••••',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bulan Ini',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          showSaldo
                              ? formatter.format(keuanganData!.thisMonthBalance)
                              : '•••••••',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    // Ambil data dengan null-safety
    final int totalAttendance = attendanceData?.totalAttendance ?? 0;
    final int thisMonthAttendance = attendanceData?.thisMonthAttendance ?? 0;
    final int thisMonthSchedules = attendanceData?.thisMonthSchedules ?? 0;

    // Hitung jadwal yang sudah lewat (misal attendanceData udah punya field ini)
    final int pastSchedules =
        attendanceData?.thisMonthSchedulesPast ?? thisMonthSchedules;

    // Hitung persentase kehadiran
    double percentage = 0;
    final bool hasSchedulesThisMonth = pastSchedules > 0;

    if (hasSchedulesThisMonth) {
      percentage =
          ((thisMonthAttendance / pastSchedules) * 100)
              .clamp(0, 100)
              .toDouble();
    }

    return Column(
      children: [
        // Peringatan kalau < 70% DAN ada jadwal lewat bulan ini
        if (percentage < 70 && !isLoadingAttendance && hasSchedulesThisMonth)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Persentase kehadiran bulan ini kurang dari 70%. Mari lebih rajin beribadah 🙏',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Kehadiran',
                isLoadingAttendance
                    ? '...'
                    : '${percentage.toStringAsFixed(0)}%',
                Icons.check_circle_outline,
                Colors.blue,
                'Total $totalAttendance kali',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Bulan Ini',
                isLoadingAttendance ? '...' : '${thisMonthAttendance}x',
                Icons.calendar_today,
                Colors.orange,
                'Dari $pastSchedules jadwal',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(2, 4),
                ),
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 6,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Icon(icon, size: 36, color: Colors.blue),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // List<MenuItemData> _getMenuItems() {
  //   return [
  //     MenuItemData(
  //       icon: Icons.calendar_month,
  //       title: '   Ibadah',
  //       subtitle: 'Lihat jadwal ibadah lingkungan terkini',
  //       color: Colors.blue,
  //       onTap: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (_) => const JadwalIbadahPage()),
  //         );
  //       },
  //     ),
  //     MenuItemData(
  //       icon: Icons.check_circle_outline,
  //       title: 'Riwayat Absensi',
  //       subtitle: 'Lihat daftar kehadiran Anda',
  //       color: Colors.green,
  //       onTap: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (_) => const RiwayatAbsensiWargaPage()),
  //         );
  //       },
  //     ),
  //     MenuItemData(
  //       icon: Icons.photo_library,
  //       title: 'Galeri',
  //       subtitle: 'Lihat foto-foto kegiatan lingkungan',
  //       color: Colors.purple,
  //       onTap: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (_) => const GallerySection()),
  //         );
  //       },
  //     ),
  //   ];
  // }

  void _showProfileDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle for the bottom sheet
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Profile Header with Avatar
              Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.brown.shade100,
                    child: Text(
                      widget.userData.nama.isNotEmpty
                          ? widget.userData.nama[0].toUpperCase()
                          : 'W',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.userData.nama,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    widget.userData.email ?? '-',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile Details using ListTiles
              _buildProfileListTile(
                Icons.male,
                'Jenis Kelamin',
                widget.userData.jenisKelamin == 'laki-laki'
                    ? 'Laki-laki'
                    : 'Perempuan',
              ),
              _buildProfileListTile(
                Icons.phone,
                'No. Telepon',
                widget.userData.noTelp ?? '-',
              ),
              _buildProfileListTile(
                Icons.calendar_today, // Ikon kalender
                'Tanggal Lahir',
                widget.userData.tanggalLahir != null
                    ? DateFormat(
                      'dd MMMM yyyy',
                    ).format(widget.userData.tanggalLahir!)
                    : '-',
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),

              // Optional Edit Profile button
              // Optional Edit Profile button
              ElevatedButton(
                key: editProfileKey, // <<< DISINI pasang key untuk highlight
                onPressed: () {
                  // Tutup bottom sheet (dialog profil)
                  Navigator.pop(context);

                  // Navigasi ke halaman edit profil dan kirim data pengguna
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              EditProfilePage(userData: widget.userData),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Profil', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Widget pembantu untuk item daftar profil
  Widget _buildProfileListTile(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade100,
        child: Icon(icon, color: Colors.brown.shade600),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16)),
    );
  }

  // Widget _buildProfileRow(String label, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 12),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         SizedBox(
  //           width: 100,
  //           child: Text(
  //             '$label:',
  //             style: const TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //         ),
  //         Expanded(child: Text(value)),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final sapaan = widget.userData.jenisKelamin == 'laki-laki' ? 'Pak' : 'Bu';

    final screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = screenWidth < 360 ? 16 : 18;
    final double subtitleFontSize = screenWidth < 360 ? 12 : 14;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child:
            _fadeAnimation != null
                ? FadeTransition(
                  opacity: _fadeAnimation!,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildHeader(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                _showProfileDialog();
                              },
                              child: CircleAvatar(
                                backgroundColor: Colors.brown.shade100,
                                child: Text(
                                  widget.userData.nama.isNotEmpty
                                      ? widget.userData.nama[0].toUpperCase()
                                      : 'W',
                                  style: const TextStyle(
                                    color: Colors.brown,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.salam}, $sapaan ${widget.userData.nama}',
                                    style: TextStyle(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Semoga hari Anda diberkati 🙏',
                                    style: TextStyle(
                                      fontSize: subtitleFontSize,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSaldoCard(),
                        const SizedBox(height: 20),
                        _buildStatsCards(),
                        const SizedBox(height: 24),
                        // Letakkan di dalam SingleChildScrollView
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSimpleMenuItem(
                              icon: Icons.calendar_month,
                              title: 'Jadwal Ibadah',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const JadwalIbadahPage(),
                                  ),
                                );
                              },
                            ),
                            _buildSimpleMenuItem(
                              icon: Icons.check_circle_outline,
                              title: 'Riwayat Presensi',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const RiwayatAbsensiWargaPage(),
                                  ),
                                );
                              },
                            ),
                            _buildSimpleMenuItem(
                              icon: Icons.photo_library,
                              title: 'Galeri',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const GallerySection(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        // ..._getMenuItems()
                        //     .map(
                        //       (item) => Padding(
                        //         padding: const EdgeInsets.only(bottom: 12),
                        //         child: MenuCard(
                        //           icon: item.icon,
                        //           title: item.title,
                        //           subtitle: item.subtitle,
                        //           color: item.color,
                        //           onTap: item.onTap,
                        //         ),
                        //       ),
                        //     )
                        //     .toList(),
                        const SizedBox(height: 24),
                        const ForYouSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                )
                : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Logo teks
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====== Teks Utama: SIPAKAR ======
            Text(
              'SIPAKAR',
              style: GoogleFonts.bebasNeue(
                fontSize: 40,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
                height: 1.0,
                foreground:
                    Paint()
                      ..shader = const LinearGradient(
                        colors: [
                          Color(0xFF6B3E1E), // coklat tua elegan
                          Color(0xFFD2B48C), // beige lembut
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                shadows: const [
                  Shadow(
                    blurRadius: 6,
                    color: Colors.black26,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),

            // ====== Subjudul: Sistem Pantauan Karya Warga ======
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Sistem Pantauan Karya Warga',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: const Color(0xFF4B2E05),
                  height: 1.3,
                  shadows: [
                    Shadow(
                      blurRadius: 3,
                      color: Colors.brown.withOpacity(0.25),
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const Spacer(),

        // ====== Notifikasi ======
        _buildNotifikasiIcon(),
        const SizedBox(width: 10),

        // ====== Tombol Logout ======
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF5DEB3), Color(0xFFD2B48C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withOpacity(0.25),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF5D4037)),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
        ),
      ],
    );
  }
}

class MenuItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class SimpleMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const SimpleMenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 3,
          shadowColor: widget.color.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.white, widget.color.withOpacity(0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
