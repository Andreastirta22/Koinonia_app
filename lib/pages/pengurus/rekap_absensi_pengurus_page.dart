import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RekapAbsensiPengurusPage extends StatefulWidget {
  const RekapAbsensiPengurusPage({super.key});

  @override
  State<RekapAbsensiPengurusPage> createState() =>
      _RekapAbsensiPengurusPageState();
}

class _RekapAbsensiPengurusPageState extends State<RekapAbsensiPengurusPage> {
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  bool _showStats = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Absensi per Jadwal'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showStats = !_showStats),
            tooltip: 'Toggle Statistics',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.brown,
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged:
                  (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari jadwal...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Filter Chips
          if (_selectedDateRange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}',
                    ),
                    onDeleted: () => setState(() => _selectedDateRange = null),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),

          // Statistics Card
          if (_showStats) _buildStatisticsCard(),

          // Schedule List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('jadwal_ibadah')
                      .orderBy('tanggal', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final jadwalList =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final tanggal = (data['tanggal'] as Timestamp).toDate();

                      // Filter by date range
                      if (_selectedDateRange != null) {
                        if (tanggal.isBefore(_selectedDateRange!.start) ||
                            tanggal.isAfter(_selectedDateRange!.end)) {
                          return false;
                        }
                      }

                      // Filter by search query
                      if (_searchQuery.isNotEmpty) {
                        final formattedDate = DateFormat(
                          'EEEE, dd MMMM yyyy',
                          'id_ID',
                        ).format(tanggal);
                        return formattedDate.toLowerCase().contains(
                          _searchQuery,
                        );
                      }

                      return true;
                    }).toList();

                if (jadwalList.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: jadwalList.length,
                    itemBuilder: (context, index) {
                      final jadwal = jadwalList[index];
                      final data = jadwal.data() as Map<String, dynamic>;
                      final tanggal = (data['tanggal'] as Timestamp).toDate();
                      final idJadwal = jadwal.id;
                      final formattedDate = DateFormat(
                        'EEEE, dd MMMM yyyy',
                        'id_ID',
                      ).format(tanggal);

                      return FutureBuilder<QuerySnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('absensi')
                                .where('jadwal_id', isEqualTo: idJadwal)
                                .get(),
                        builder: (context, snapshotAbsen) {
                          if (!snapshotAbsen.hasData) {
                            return _buildLoadingCard();
                          }

                          final hadirUserIds =
                              snapshotAbsen.data!.docs
                                  .map((doc) => doc['user_id'])
                                  .toSet();

                          return FutureBuilder<QuerySnapshot>(
                            future:
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .where('role', isEqualTo: 'warga')
                                    .get(),
                            builder: (context, snapshotUsers) {
                              if (!snapshotUsers.hasData) {
                                return _buildLoadingCard();
                              }

                              final users = snapshotUsers.data!.docs;
                              final totalHadir =
                                  users
                                      .where((u) => hadirUserIds.contains(u.id))
                                      .length;
                              final totalTidakHadir = users.length - totalHadir;
                              final attendancePercentage =
                                  users.isNotEmpty
                                      ? (totalHadir / users.length)
                                      : 0.0;

                              return _buildScheduleCard(
                                formattedDate,
                                totalHadir,
                                totalTidakHadir,
                                attendancePercentage,
                                tanggal,
                                () =>
                                    _navigateToDetail(idJadwal, formattedDate),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('jadwal_ibadah').snapshots(),
      builder: (context, jadwalSnapshot) {
        if (!jadwalSnapshot.hasData) return const SizedBox.shrink();

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'warga')
                  .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const SizedBox.shrink();

            final totalSchedules = jadwalSnapshot.data!.docs.length;
            final totalMembers = userSnapshot.data!.docs.length;

            return Container(
              margin: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics, color: Colors.brown),
                          const SizedBox(width: 8),
                          Text(
                            'Statistik Keseluruhan',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Total Jadwal',
                              totalSchedules.toString(),
                              Icons.event,
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Total Warga',
                              totalMembers.toString(),
                              Icons.people,
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Bulan Ini',
                              _getThisMonthSchedules(
                                jadwalSnapshot.data!.docs,
                              ).toString(),
                              Icons.calendar_today,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScheduleCard(
    String formattedDate,
    int totalHadir,
    int totalTidakHadir,
    double attendancePercentage,
    DateTime tanggal,
    VoidCallback onTap,
  ) {
    final isRecent = DateTime.now().difference(tanggal).inDays <= 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.brown.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.event_note, color: Colors.brown),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isRecent)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Terbaru',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text('Hadir: $totalHadir'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.cancel, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Text('Tidak Hadir: $totalTidakHadir'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tingkat Kehadiran:',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${(attendancePercentage * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getAttendanceColor(attendancePercentage),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: attendancePercentage,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getAttendanceColor(attendancePercentage),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 16),
              Text('Memuat data...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada jadwal ibadah',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jadwal yang ditambahkan akan muncul di sini',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.6) return Colors.orange;
    return Colors.red;
  }

  int _getThisMonthSchedules(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final tanggal = (data['tanggal'] as Timestamp).toDate();
      return tanggal.month == now.month && tanggal.year == now.year;
    }).length;
  }

  void _navigateToDetail(String jadwalId, String tanggal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => DetailRekapJadwalPage(jadwalId: jadwalId, tanggal: tanggal),
      ),
    );
  }

  void _showFilterDialog() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  // void _exportAllData() {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('Fitur export semua data akan segera tersedia'),
  //       backgroundColor: Colors.brown,
  //     ),
  //   );
  // }
}

class DetailRekapJadwalPage extends StatefulWidget {
  final String jadwalId;
  final String tanggal;

  const DetailRekapJadwalPage({
    super.key,
    required this.jadwalId,
    required this.tanggal,
  });

  @override
  State<DetailRekapJadwalPage> createState() => _DetailRekapJadwalPageState();
}

class _DetailRekapJadwalPageState extends State<DetailRekapJadwalPage> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, hadir, tidak_hadir

  Future<void> exportPDF(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    // Calculate statistics
    final hadirCount = data.where((item) => item['hadir']).length;
    final totalCount = data.length;
    final percentage = totalCount > 0 ? (hadirCount / totalCount * 100) : 0.0;

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 2)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'REKAP ABSENSI IBADAH',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Tanggal: ${widget.tanggal}'),
                    pw.Text('Total Warga: $totalCount'),
                    pw.Text(
                      'Hadir: $hadirCount (${percentage.toStringAsFixed(1)}%)',
                    ),
                    pw.Text('Tidak Hadir: ${totalCount - hadirCount}'),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Table
              pw.Table.fromTextArray(
                headers: ['No', 'Nama Warga', 'Status Kehadiran'],
                data:
                    data
                        .asMap()
                        .entries
                        .map(
                          (e) => [
                            '${e.key + 1}',
                            e.value['nama'],
                            e.value['hadir'] ? 'Hadir' : 'Tidak Hadir',
                          ],
                        )
                        .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                },
              ),

              pw.SizedBox(height: 30),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Pengurus,'),
                      pw.SizedBox(height: 50),
                      pw.Text('_________________'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Tanggal: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text('Dicetak oleh sistem absensi gereja'),
                    ],
                  ),
                ],
              ),
            ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rekap: ${widget.tanggal}'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () async {
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) =>
                          const Center(child: CircularProgressIndicator()),
                );

                final users =
                    await FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'warga')
                        .get();

                final absensi =
                    await FirebaseFirestore.instance
                        .collection('absensi')
                        .where('jadwal_id', isEqualTo: widget.jadwalId)
                        .get();

                final hadirIds =
                    absensi.docs.map((e) => e['user_id'].toString()).toSet();

                final data =
                    users.docs.map((user) {
                      return {
                        'nama': user['nama'],
                        'hadir': hadirIds.contains(user.id),
                      };
                    }).toList();

                Navigator.of(context).pop(); // Close loading dialog
                await exportPDF(data);
              } catch (e) {
                Navigator.of(context).pop(); // Close loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            color: Colors.brown,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged:
                      (value) =>
                          setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari nama warga...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('Semua')),
                          ButtonSegment(value: 'hadir', label: Text('Hadir')),
                          ButtonSegment(
                            value: 'tidak_hadir',
                            label: Text('Tidak Hadir'),
                          ),
                        ],
                        selected: {_statusFilter},
                        onSelectionChanged: (Set<String> selection) {
                          setState(() {
                            _statusFilter = selection.first;
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.brown,
                          selectedBackgroundColor: Colors.brown.shade100,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'warga')
                      .get(),
              builder: (context, snapshotUsers) {
                if (!snapshotUsers.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshotUsers.data!.docs;

                return FutureBuilder<QuerySnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('absensi')
                          .where('jadwal_id', isEqualTo: widget.jadwalId)
                          .get(),
                  builder: (context, snapshotAbsen) {
                    if (!snapshotAbsen.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final absensiDocs = snapshotAbsen.data!.docs;
                    final hadirUserIds =
                        absensiDocs
                            .map((doc) => doc['user_id'].toString())
                            .toSet();

                    // Filter users based on search and status
                    final filteredUsers =
                        users.where((user) {
                          final nama = user['nama'].toString().toLowerCase();
                          final userId = user.id;
                          final hadir = hadirUserIds.contains(userId);

                          // Search filter
                          if (_searchQuery.isNotEmpty &&
                              !nama.contains(_searchQuery)) {
                            return false;
                          }

                          // Status filter
                          if (_statusFilter == 'hadir' && !hadir) return false;
                          if (_statusFilter == 'tidak_hadir' && hadir)
                            return false;

                          return true;
                        }).toList();

                    if (users.isEmpty) {
                      return const Center(
                        child: Text('Belum ada warga terdaftar.'),
                      );
                    }

                    if (filteredUsers.isEmpty) {
                      return const Center(
                        child: Text('Tidak ada data sesuai filter.'),
                      );
                    }

                    // Statistics
                    final totalHadir =
                        users.where((u) => hadirUserIds.contains(u.id)).length;
                    final totalTidakHadir = users.length - totalHadir;

                    return Column(
                      children: [
                        // Statistics Card
                        Container(
                          margin: const EdgeInsets.all(16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.people,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          users.length.toString(),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text('Total Warga'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          totalHadir.toString(),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text('Hadir'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          totalTidakHadir.toString(),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text('Tidak Hadir'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.analytics,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${users.isNotEmpty ? (totalHadir / users.length * 100).toStringAsFixed(1) : '0'}%',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text('Kehadiran'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // User List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final nama = user['nama'];
                              final userId = user.id;
                              final hadir = hadirUserIds.contains(userId);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        hadir
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                    child: Icon(
                                      hadir ? Icons.check_circle : Icons.cancel,
                                      color: hadir ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              hadir
                                                  ? Colors.green.withOpacity(
                                                    0.1,
                                                  )
                                                  : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          hadir ? 'Hadir' : 'Tidak Hadir',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                hadir
                                                    ? Colors.green
                                                    : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing:
                                      hadir
                                          ? const Icon(
                                            Icons.verified,
                                            color: Colors.green,
                                            size: 20,
                                          )
                                          : const Icon(
                                            Icons.error_outline,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: () => setState(() {}),
            backgroundColor: Colors.brown,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: "share",
            onPressed: _shareReport,
            backgroundColor: Colors.brown,
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text('Bagikan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur berbagi laporan akan segera tersedia'),
        backgroundColor: Colors.brown,
      ),
    );
  }
}
