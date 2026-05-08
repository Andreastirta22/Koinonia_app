import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart' as csv;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class LaporanPage extends StatefulWidget {
  final int initialIndex;
  const LaporanPage({super.key, this.initialIndex = 0});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  /// Helper untuk parsing jumlah
  int parseJumlah(Map<String, dynamic> data) {
    if (!data.containsKey('jumlah')) return 0;
    final raw = data['jumlah'];
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 0;
  }

  Future<void> exportData(List<List<dynamic>> rows) async {
    String csvData = const csv.ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      "${dir.path}/laporan_${DateTime.now().millisecondsSinceEpoch}.csv",
    );
    await file.writeAsString(csvData);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data berhasil diekspor: ${file.path}")),
    );

    await Share.shareXFiles([XFile(file.path)], text: "Laporan CSV");
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Laporan",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: "Bulanan"),
              Tab(text: "Kehadiran"),
              Tab(text: "Keuangan"),
              Tab(text: "Export"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildKeuanganBulanan(),
            _buildStatistikKehadiran(),
            _buildLaporanKeuangan(),
            _buildExportData(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeuanganBulanan() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('keuangan')
              .orderBy('tanggal', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!.docs;

        Map<String, int> pemasukan = {};
        Map<String, int> pengeluaran = {};

        for (var doc in data) {
          final map = doc.data() as Map<String, dynamic>? ?? {};
          if (!map.containsKey('tanggal') || !map.containsKey('kategori')) {
            continue;
          }

          final tgl =
              map['tanggal'] is Timestamp
                  ? (map['tanggal'] as Timestamp).toDate()
                  : DateTime.now();
          final bulan = DateFormat('MMMM yyyy', 'id_ID').format(tgl);
          final nominal = parseJumlah(map);
          final jenis = map['kategori']?.toString().toLowerCase() ?? '';

          if (jenis == 'pemasukan') {
            pemasukan[bulan] = (pemasukan[bulan] ?? 0) + nominal;
          } else if (jenis == 'pengeluaran') {
            pengeluaran[bulan] = (pengeluaran[bulan] ?? 0) + nominal;
          }
        }

        final bulanList =
            {...pemasukan.keys, ...pengeluaran.keys}.toList()..sort(
              (a, b) => DateFormat(
                'MMMM yyyy',
                'id_ID',
              ).parse(a).compareTo(DateFormat('MMMM yyyy', 'id_ID').parse(b)),
            );

        if (bulanList.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada data keuangan.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: bulanList.length,
          itemBuilder: (context, index) {
            final bulan = bulanList[index];
            final masuk = pemasukan[bulan] ?? 0;
            final keluar = pengeluaran[bulan] ?? 0;
            final saldo = masuk - keluar;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bulan,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_upward,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Masuk: ${formatter.format(masuk)}",
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_downward,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Keluar: ${formatter.format(keluar)}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Text(
                      "Saldo: ${formatter.format(saldo)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: saldo >= 0 ? Colors.blue : Colors.red,
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
  }

  Widget _buildStatistikKehadiran() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('absensi')
              .orderBy('tanggal')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!.docs;
        if (data.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada data absensi.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        Map<String, int> hadir = {};
        Map<String, int> total = {};

        for (var doc in data) {
          final map = doc.data() as Map<String, dynamic>? ?? {};
          final tgl =
              map['tanggal'] is Timestamp
                  ? (map['tanggal'] as Timestamp).toDate()
                  : DateTime.now();
          final bulan = DateFormat('MMM yyyy').format(tgl);

          total[bulan] = (total[bulan] ?? 0) + 1;
          if (map['status'] == 'hadir') {
            hadir[bulan] = (hadir[bulan] ?? 0) + 1;
          }
        }

        List<String> bulanList =
            total.keys.toList()..sort(
              (a, b) => DateFormat(
                'MMM yyyy',
              ).parse(a).compareTo(DateFormat('MMM yyyy').parse(b)),
            );

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Persentase Kehadiran",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 20),
                AspectRatio(
                  aspectRatio: 1.6,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < bulanList.length) {
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    bulanList[value.toInt()],
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  space: 10,
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine:
                            (value) => FlLine(
                              color: Colors.grey.withAlpha(50),
                              strokeWidth: 1,
                            ),
                      ),
                      barGroups: List.generate(bulanList.length, (i) {
                        final bulan = bulanList[i];
                        final totalBulan = total[bulan] ?? 0;
                        final hadirBulan = hadir[bulan] ?? 0;
                        final persentase =
                            totalBulan > 0
                                ? (hadirBulan / totalBulan * 100).toDouble()
                                : 0.0;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: persentase,
                              color:
                                  persentase > 75
                                      ? Colors.green
                                      : persentase > 50
                                      ? Colors.orange
                                      : Colors.red,
                              width: 18,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: 100,
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                          ],
                        );
                      }),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.black12, width: 1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ...bulanList.map((bulan) {
                  final totalBulan = total[bulan] ?? 0;
                  final hadirBulan = hadir[bulan] ?? 0;
                  final persentase =
                      totalBulan > 0
                          ? (hadirBulan / totalBulan * 100).toStringAsFixed(1)
                          : '0.0';
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(bulan),
                      trailing: Text(
                        "$hadirBulan dari $totalBulan (${persentase}%)",
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLaporanKeuangan() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('keuangan')
              .orderBy('tanggal', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada data keuangan.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>? ?? {};

            final nominal = parseJumlah(data);
            final keterangan = data['keterangan']?.toString() ?? '-';
            final tanggal =
                data['tanggal'] is Timestamp
                    ? (data['tanggal'] as Timestamp).toDate()
                    : null;
            final tanggalStr =
                tanggal != null
                    ? DateFormat('dd MMM yyyy').format(tanggal)
                    : '-';
            final jenis = data['kategori']?.toString() ?? '-';
            final isPemasukan = jenis.toLowerCase() == 'pemasukan';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isPemasukan ? Colors.green.shade50 : Colors.red.shade50,
                  child: Icon(
                    isPemasukan ? Icons.add : Icons.remove,
                    color: isPemasukan ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  formatter.format(nominal),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPemasukan ? Colors.green : Colors.red,
                  ),
                ),
                subtitle: Text(
                  "$keterangan\n$tanggalStr",
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  jenis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExportData() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.download_for_offline,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              "Ekspor Data Keuangan",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Anda bisa mengunduh seluruh data keuangan ke dalam format CSV dan membagikannya.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text(
                "Ekspor & Bagikan CSV",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              onPressed: () async {
                final snapshot =
                    await FirebaseFirestore.instance
                        .collection('keuangan')
                        .orderBy('tanggal')
                        .get();

                List<List<dynamic>> rows = [
                  ["Tanggal", "Kategori", "Jumlah", "Keterangan"],
                ];

                for (var doc in snapshot.docs) {
                  final data = doc.data();
                  final tgl =
                      data['tanggal'] is Timestamp
                          ? (data['tanggal'] as Timestamp).toDate()
                          : DateTime.now();
                  final nominal = parseJumlah(data);
                  final keterangan = data['keterangan'] ?? "";
                  final jenis = data['kategori'] ?? "";

                  rows.add([
                    DateFormat('dd/MM/yyyy').format(tgl),
                    jenis,
                    nominal,
                    keterangan,
                  ]);
                }
                exportData(rows);
              },
            ),
          ],
        ),
      ),
    );
  }
}
