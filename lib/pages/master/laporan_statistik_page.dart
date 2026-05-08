import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LaporanStatistikPage extends StatefulWidget {
  const LaporanStatistikPage({super.key});

  @override
  State<LaporanStatistikPage> createState() => _LaporanStatistikPageState();
}

class _LaporanStatistikPageState extends State<LaporanStatistikPage> {
  int totalWarga = 0;
  int totalHadir = 0;
  Map<String, int> kehadiranPerHari = {};
  Map<String, int> loginPerHari = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cekRoleDanMuatData();
  }

  Future<void> _cekRoleDanMuatData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid == null) return;

    final userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final role = userSnapshot['role'];

    if (role != 'master') {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akses ditolak. Hanya untuk master.')),
      );
      return;
    }

    await _muatStatistik();
  }

  Future<void> _muatStatistik() async {
    final userSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'warga')
            .get();

    totalWarga = userSnapshot.docs.length;

    final absensiSnapshot =
        await FirebaseFirestore.instance.collection('absensi').get();

    totalHadir = absensiSnapshot.docs.length;

    final Map<String, int> tempKehadiran = {};
    final Map<String, int> tempLogin = {};

    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = DateFormat('dd MMM').format(date);
      tempKehadiran[key] = 0;
      tempLogin[key] = 0;
    }

    for (var doc in absensiSnapshot.docs) {
      final waktu = (doc['waktu'] as Timestamp).toDate();
      final key = DateFormat('dd MMM').format(waktu);
      if (tempKehadiran.containsKey(key)) {
        tempKehadiran[key] = tempKehadiran[key]! + 1;
      }
    }

    final loginSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    for (var doc in loginSnapshot.docs) {
      if (doc.data().containsKey('last_login')) {
        final waktu = (doc['last_login'] as Timestamp).toDate();
        final key = DateFormat('dd MMM').format(waktu);
        if (tempLogin.containsKey(key)) {
          tempLogin[key] = tempLogin[key]! + 1;
        }
      }
    }

    setState(() {
      kehadiranPerHari = tempKehadiran;
      loginPerHari = tempLogin;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tidakHadir = totalWarga - totalHadir;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Statistik'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _muatStatistik,
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Widget untuk Perbandingan Hadir & Tidak Hadir
                      _buildChartContainer(
                        title: '1. Perbandingan Hadir & Tidak Hadir',
                        child: SizedBox(
                          height: 220,
                          child: PieChart(
                            PieChartData(
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  value: totalHadir.toDouble(),
                                  title: 'Hadir\n(${totalHadir})',
                                  color: Colors.green,
                                  radius: 60,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                PieChartSectionData(
                                  value:
                                      tidakHadir < 0
                                          ? 0
                                          : tidakHadir.toDouble(),
                                  title:
                                      'Tidak Hadir\n(${tidakHadir < 0 ? 0 : tidakHadir})',
                                  color: Colors.red,
                                  radius: 60,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Widget untuk Kehadiran per Hari
                      _buildChartContainer(
                        title: '2. Kehadiran per Hari (7 Hari Terakhir)',
                        child: SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      final key =
                                          kehadiranPerHari.keys.toList()[index];
                                      return Text(
                                        key,
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                    reservedSize: 32,
                                  ),
                                ),
                                rightTitles: const AxisTitles(),
                                topTitles: const AxisTitles(),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups:
                                  kehadiranPerHari.entries
                                      .toList()
                                      .asMap()
                                      .entries
                                      .map(
                                        (e) => BarChartGroupData(
                                          x: e.key,
                                          barRods: [
                                            BarChartRodData(
                                              toY: e.value.value.toDouble(),
                                              width: 14,
                                              color: Colors.blue,
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Widget untuk Login Pengguna per Hari
                      _buildChartContainer(
                        title: '3. Login Pengguna per Hari (7 Hari Terakhir)',
                        child: SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      final key =
                                          loginPerHari.keys.toList()[index];
                                      return Text(
                                        key,
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                    reservedSize: 32,
                                  ),
                                ),
                                rightTitles: const AxisTitles(),
                                topTitles: const AxisTitles(),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups:
                                  loginPerHari.entries
                                      .toList()
                                      .asMap()
                                      .entries
                                      .map(
                                        (e) => BarChartGroupData(
                                          x: e.key,
                                          barRods: [
                                            BarChartRodData(
                                              toY: e.value.value.toDouble(),
                                              width: 14,
                                              color: Colors.orange,
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildChartContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
