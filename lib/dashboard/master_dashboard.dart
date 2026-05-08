import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:koinonia/login_page.dart';
import 'package:koinonia/pages/master/tambah_akun_page.dart';
import 'package:koinonia/pages/master/kelola_akun_user.dart';
import 'package:koinonia/components/KelolaRolePage.dart';
import 'package:koinonia/components/AuditLog.dart';

class MasterDashboard extends StatefulWidget {
  const MasterDashboard({super.key});

  @override
  State<MasterDashboard> createState() => _MasterDashboardState();
}

class _MasterDashboardState extends State<MasterDashboard>
    with TickerProviderStateMixin {
  String? nama;
  String? jenisKelamin;
  late TabController _tabController;

  // System statistics
  int totalUsers = 0;
  int totalWarga = 0;
  int totalPengurus = 0;
  int activeToday = 0;
  int totalTransactions = 0;
  int totalEvents = 0;
  double systemHealth = 98.5;

  late AnimationController _statsAnimationController;
  late Animation<double> _statsAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _statsAnimation = CurvedAnimation(
      parent: _statsAnimationController,
      curve: Curves.easeOutBack,
    );

    loadUserData();
    loadSystemStats();
    _statsAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid != null) {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        setState(() {
          nama = snapshot['nama'];
          jenisKelamin = snapshot['jenis_kelamin'];
        });
      }
    }
  }

  Future<void> loadSystemStats() async {
    try {
      // Hitung total user
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final totalUsersCount = usersSnapshot.size;

      // Hitung warga
      final wargaSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'warga')
              .get();
      final totalWargaCount = wargaSnapshot.size;

      // Hitung pengurus
      final pengurusSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'pengurus')
              .get();
      final totalPengurusCount = pengurusSnapshot.size;

      // Hitung transaksi
      final transaksiSnapshot =
          await FirebaseFirestore.instance.collection('keuangan').get();
      final totalTransaksiCount = transaksiSnapshot.size;

      // Hitung event
      final eventsSnapshot =
          await FirebaseFirestore.instance.collection('jadwal_ibadah').get();
      final totalEventsCount = eventsSnapshot.size;

      // Hitung active today (last_login = hari ini)
      final today = DateTime.now();
      final activeTodaySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where(
                'last_login',
                isGreaterThanOrEqualTo:
                    DateTime(
                      today.year,
                      today.month,
                      today.day,
                    ).toIso8601String(),
              )
              .get();
      final activeTodayCount = activeTodaySnapshot.size;

      // Update state
      setState(() {
        totalUsers = totalUsersCount;
        totalWarga = totalWargaCount;
        totalPengurus = totalPengurusCount;
        totalTransactions = totalTransaksiCount;
        totalEvents = totalEventsCount;
        activeToday = activeTodayCount;
      });
    } catch (e) {
      debugPrint('Error loading system stats: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat statistik sistem')));
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${getSalam()}, $sapaan ${nama ?? ''}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Master Administrator',
              style: TextStyle(fontSize: 12, color: Colors.brown.shade200),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF5D4037),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // System health indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        systemHealth > 95
                            ? Colors.green
                            : systemHealth > 80
                            ? Colors.orange
                            : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${systemHealth.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          // Notifications
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
                    child: const Text('5', style: TextStyle(fontSize: 8)),
                  ),
                ),
              ],
            ),
            onPressed: () => _showSystemAlerts(),
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/pengaturan-master'),
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.brown.shade200,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.settings), text: 'System'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildUsersTab(),
          _buildSystemTab(),
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TambahAkunPage()),
            ),
        backgroundColor: const Color(0xFF5D4037),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Tambah User', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: loadSystemStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System Health Card
            _buildSystemHealthCard(),
            const SizedBox(height: 16),

            // Statistics Grid
            AnimatedBuilder(
              animation: _statsAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _statsAnimation.value,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatsCard(
                        'Total Users',
                        '$totalUsers',
                        Icons.people,
                        Colors.blue,
                      ),
                      _buildStatsCard(
                        'Active Today',
                        '$activeToday',
                        Icons.online_prediction,
                        Colors.green,
                      ),
                      _buildStatsCard(
                        'Transactions',
                        '$totalTransactions',
                        Icons.attach_money,
                        Colors.orange,
                      ),
                      _buildStatsCard(
                        'Events',
                        '$totalEvents',
                        Icons.event,
                        Colors.purple,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(),

            const SizedBox(height: 24),

            // Recent Activities
            const Text(
              'Recent System Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Statistics
          Row(
            children: [
              Expanded(
                child: _buildUserStatsCard('Warga', totalWarga, Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUserStatsCard(
                  'Pengurus',
                  totalPengurus,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // User Management Cards
          _buildEnhancedCard(
            icon: Icons.person_add_alt_1,
            title: 'Tambah Akun Baru',
            subtitle: 'Buat akun untuk warga atau pengurus',
            color: Colors.blue,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TambahAkunPage()),
                ),
          ),

          _buildEnhancedCard(
            icon: Icons.people_outline,
            title: 'Kelola Akun User',
            subtitle: 'Edit, nonaktifkan, atau hapus akun pengguna',
            color: Colors.green,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KelolaAkunUserPage()),
                ),
          ),

          _buildEnhancedCard(
            icon: Icons.admin_panel_settings,
            title: 'Kelola Role & Permission',
            subtitle: 'Atur hak akses dan peran pengguna',
            color: Colors.orange,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KelolaRolePage()),
                ),
          ),

          _buildEnhancedCard(
            icon: Icons.group_add,
            title: 'Import/Export Users',
            subtitle: 'Bulk import dari Excel atau export data',
            color: Colors.purple,
            onTap: () => _showComingSoon('Import/Export'),
          ),

          _buildEnhancedCard(
            icon: Icons.security,
            title: 'Audit Log Pengguna',
            subtitle: 'Lihat aktivitas dan riwayat login user',
            color: Colors.red,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuditLogPage()),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnhancedCard(
            icon: Icons.manage_accounts,
            title: 'Kelola Absensi Warga',
            subtitle: 'Atur kehadiran setiap warga secara manual',
            color: Colors.indigo,
            onTap: () => Navigator.pushNamed(context, '/kelola-absensi-warga'),
          ),

          _buildEnhancedCard(
            icon: Icons.attach_money,
            title: 'Kelola Keuangan',
            subtitle: 'Pantau dan atur pemasukan/pengeluaran',
            color: Colors.teal,
            onTap: () => Navigator.pushNamed(context, '/daftar-keuangan'),
          ),

          _buildEnhancedCard(
            icon: Icons.event_note,
            title: 'Kelola Jadwal Ibadah',
            subtitle: 'Lihat dan tambahkan jadwal ibadah',
            color: Colors.brown,
            onTap:
                () => Navigator.pushNamed(context, '/jadwal-ibadah-pengurus'),
          ),

          _buildEnhancedCard(
            icon: Icons.backup,
            title: 'Backup & Restore',
            subtitle: 'Backup data sistem dan restore jika diperlukan',
            color: Colors.deepOrange,
            onTap: () => _showComingSoon('Backup System'),
          ),

          _buildEnhancedCard(
            icon: Icons.notification_important,
            title: 'Push Notification',
            subtitle: 'Kirim notifikasi ke semua atau grup tertentu',
            color: Colors.pink,
            onTap: () => _showComingSoon('Push Notifications'),
          ),

          _buildEnhancedCard(
            icon: Icons.update,
            title: 'Update Sistem',
            subtitle: 'Cek dan install update aplikasi',
            color: Colors.cyan,
            onTap: () => _showSystemUpdate(),
          ),

          _buildEnhancedCard(
            icon: Icons.bug_report,
            title: 'System Logs',
            subtitle: 'Lihat error log dan debugging info',
            color: Colors.red,
            onTap: () => _showComingSoon('System Logs'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Analytics & Reports',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildAnalyticsCard(
            title: 'User Engagement Report',
            subtitle: 'Analisis aktivitas dan engagement pengguna',
            icon: Icons.trending_up,
            onTap: () => _showComingSoon('User Analytics'),
          ),

          _buildAnalyticsCard(
            title: 'Financial Dashboard',
            subtitle: 'Grafik dan laporan keuangan lengkap',
            icon: Icons.pie_chart,
            onTap: () => Navigator.pushNamed(context, '/laporan-statistik'),
          ),

          _buildAnalyticsCard(
            title: 'Attendance Analytics',
            subtitle: 'Statistik kehadiran ibadah dan kegiatan',
            icon: Icons.bar_chart,
            onTap: () => _showComingSoon('Attendance Analytics'),
          ),

          _buildAnalyticsCard(
            title: 'System Performance',
            subtitle: 'Monitoring performa dan resource usage',
            icon: Icons.speed,
            onTap: () => _showComingSoon('Performance Monitor'),
          ),

          _buildAnalyticsCard(
            title: 'Export All Data',
            subtitle: 'Download laporan komprehensif (Excel/PDF)',
            icon: Icons.download,
            onTap: () => _showComingSoon('Data Export'),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.green.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Health: ${systemHealth.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'All systems operational',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: systemHealth / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(
                      systemHealth > 95
                          ? Colors.green
                          : systemHealth > 80
                          ? Colors.orange
                          : Colors.red,
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

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
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
                fontSize: 24,
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

  Widget _buildUserStatsCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickActionButton(
          Icons.person_add,
          'Add User',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahAkunPage()),
          ),
        ),
        _buildQuickActionButton(
          Icons.backup,
          'Backup',
          () => _showComingSoon('Backup'),
        ),
        _buildQuickActionButton(
          Icons.notifications,
          'Broadcast',
          () => _showComingSoon('Broadcast'),
        ),
        _buildQuickActionButton(
          Icons.analytics,
          'Reports',
          () => Navigator.pushNamed(context, '/laporan-statistik'),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF5D4037),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
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
          children: List.generate(4, (index) {
            final activities = [
              {
                'title': 'New user registered',
                'time': '5 min ago',
                'icon': Icons.person_add,
              },
              {
                'title': 'Backup completed',
                'time': '1 hour ago',
                'icon': Icons.backup,
              },
              {
                'title': 'System update available',
                'time': '2 hours ago',
                'icon': Icons.system_update,
              },
              {
                'title': 'Database optimized',
                'time': '4 hours ago',
                'icon': Icons.data_usage,
              },
            ];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.brown.withOpacity(0.1),
                child: Icon(
                  activities[index]['icon'] as IconData,
                  color: Colors.brown,
                  size: 20,
                ),
              ),
              title: Text(
                activities[index]['title'] as String,
                style: const TextStyle(fontSize: 14),
              ),
              trailing: Text(
                activities[index]['time'] as String,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              dense: true,
            );
          }),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Apakah Anda yakin ingin keluar dari sistem?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showSystemAlerts() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('System Alerts'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                ListTile(
                  leading: Icon(Icons.warning, color: Colors.orange),
                  title: Text('Backup reminder'),
                  subtitle: Text('Last backup: 2 days ago'),
                ),
                ListTile(
                  leading: Icon(Icons.update, color: Colors.blue),
                  title: Text('Update available'),
                  subtitle: Text('Version 2.1.0 is ready'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showSystemUpdate() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('System Update'),
            content: const Text(
              'Current version: 2.0.1\nLatest version: 2.1.0\n\nNew features:\n• Enhanced security\n• Performance improvements\n• Bug fixes',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Update will be installed during maintenance window',
                      ),
                    ),
                  );
                },
                child: const Text('Schedule Update'),
              ),
            ],
          ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature akan segera hadir!'),
        backgroundColor: const Color(0xFF5D4037),
      ),
    );
  }
}
