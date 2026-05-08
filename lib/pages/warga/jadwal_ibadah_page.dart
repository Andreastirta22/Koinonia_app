import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class JadwalIbadahPage extends StatefulWidget {
  const JadwalIbadahPage({super.key});

  @override
  State<JadwalIbadahPage> createState() => _JadwalIbadahPageState();
}

class _JadwalIbadahPageState extends State<JadwalIbadahPage> {
  String? uid;
  Map<String, bool> sudahAbsenMap = {};
  Map<String, bool> expandedGroups = {};
  String? selectedMonth;
  String? selectedYear;
  bool ascending = true;

  final List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  List<String> years = [];

  final Map<String, Color> categoryColors = {
    'Ibadah Rutin': Colors.greenAccent.shade100,
    'Misa Lingkungan': Colors.blueAccent.shade100,
    'Misa Arwah': Colors.orangeAccent.shade100,
  };

  @override
  void initState() {
    super.initState();
    loadUid();
    _generateYears();
    final now = DateTime.now();
    selectedMonth = months[now.month - 1];
    selectedYear = now.year.toString();
  }

  void _generateYears() {
    int currentYear = DateTime.now().year;
    for (int i = currentYear; i >= 2020; i--) {
      years.add(i.toString());
    }
  }

  Future<void> loadUid() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      uid = prefs.getString('uid');
    });
  }

  Future<void> cekAbsensi(String jadwalId) async {
    if (uid == null || sudahAbsenMap.containsKey(jadwalId)) return;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('absensi')
            .where('jadwal_id', isEqualTo: jadwalId)
            .where('user_id', isEqualTo: uid)
            .get();
    setState(() {
      sudahAbsenMap[jadwalId] = snapshot.docs.isNotEmpty;
    });
  }

  String groupKey(DateTime date) {
    final formatter = DateFormat('MMMM yyyy', 'id_ID');
    return formatter.format(date);
  }

  bool isPastMonth(DateTime date) {
    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
    ).isBefore(DateTime(now.year, now.month));
  }

  void _showPicker(
    List<String> items,
    String title,
    void Function(String) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children:
                  items.map((item) {
                    return ListTile(
                      title: Text(item, style: GoogleFonts.poppins()),
                      onTap: () {
                        Navigator.pop(context);
                        onSelected(item);
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Ibadah'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final now = DateTime.now();
          setState(() {
            selectedMonth = months[now.month - 1];
            selectedYear = now.year.toString();
          });
        },
        label: const Text("Bulan Ini"),
        icon: const Icon(Icons.refresh),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap:
                        () => _showPicker(months, 'Pilih Bulan', (val) {
                          setState(() => selectedMonth = val);
                        }),
                    child: _buildFilterBox(selectedMonth ?? 'Pilih Bulan'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap:
                        () => _showPicker(years, 'Pilih Tahun', (val) {
                          setState(() => selectedYear = val);
                        }),
                    child: _buildFilterBox(selectedYear ?? 'Pilih Tahun'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('jadwal_ibadah')
                      .orderBy('tanggal', descending: !ascending)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final tanggal = (data['tanggal'] as Timestamp).toDate();

                      int selectedMonthIndex =
                          months.indexOf(selectedMonth!) + 1;
                      int selectedYearInt = int.parse(selectedYear!);

                      return tanggal.month == selectedMonthIndex &&
                          tanggal.year == selectedYearInt;
                    }).toList();

                final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final tanggal = (data['tanggal'] as Timestamp).toDate();
                  final key = groupKey(tanggal);
                  grouped.putIfAbsent(key, () => []).add(doc);
                }

                if (grouped.isEmpty)
                  return const Center(
                    child: Text("Tidak ada jadwal ditemukan."),
                  );

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children:
                      grouped.entries.map((entry) {
                        final title = entry.key;
                        final items = entry.value;
                        final firstDate =
                            (items.first.data() as Map)['tanggal'] as Timestamp;
                        final dateObj = firstDate.toDate();
                        final isExpanded =
                            expandedGroups[title] ?? !isPastMonth(dateObj);

                        return ExpansionTile(
                          initiallyExpanded: isExpanded,
                          onExpansionChanged:
                              (val) =>
                                  setState(() => expandedGroups[title] = val),
                          title: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          children:
                              items.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final mulai =
                                    (data['tanggal'] as Timestamp).toDate();
                                final selesai =
                                    (data['valid_until'] as Timestamp).toDate();
                                final tempat = data['tempat'] ?? '-';
                                final kategori = data['kategori'];
                                final jadwalId = doc.id;

                                // cek absensi sekali per dokumen
                                if (!sudahAbsenMap.containsKey(jadwalId)) {
                                  cekAbsensi(jadwalId);
                                }

                                final sudahAbsen =
                                    sudahAbsenMap[jadwalId] ?? false;

                                final now = DateTime.now();
                                final isToday =
                                    mulai.year == now.year &&
                                    mulai.month == now.month &&
                                    mulai.day == now.day;
                                final canAbsen = isToday && !sudahAbsen;

                                final isFuture = now.isBefore(mulai);
                                final isPast = now.isAfter(selesai);

                                final cardColor =
                                    canAbsen
                                        ? (kategori != null
                                            ? categoryColors[kategori]!
                                            : Colors.grey.shade100)
                                        : Colors.grey.shade200;

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  color: cardColor,
                                  child: ListTile(
                                    enabled: canAbsen,
                                    onTap:
                                        canAbsen
                                            ? () => Navigator.pushNamed(
                                              context,
                                              '/input-kode',
                                              arguments: {'jadwalId': jadwalId},
                                            )
                                            : (isFuture
                                                ? () =>
                                                    _showNotStartedDialog(mulai)
                                                : null),
                                    leading: const Icon(
                                      Icons.calendar_month_rounded,
                                      color: Colors.brown,
                                    ),
                                    title: Text(
                                      DateFormat(
                                        'EEEE, dd MMMM yyyy',
                                        'id_ID',
                                      ).format(mulai),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isPast ? Colors.grey : Colors.black,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),

                                        // Kategori
                                        if (kategori != null &&
                                            kategori.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            margin: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color:
                                                    categoryColors[kategori] ??
                                                    Colors.grey,
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                            child: Text(
                                              kategori,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),

                                        // Jam ibadah
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.brown,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Jam: ${DateFormat.Hm().format(mulai)} - ${DateFormat.Hm().format(selesai)}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color:
                                                    isPast
                                                        ? Colors.grey
                                                        : Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        // Tempat ibadah
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.person,
                                              size: 16,
                                              color: Colors.brown,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'Tempat: $tempat',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color:
                                                      isPast
                                                          ? Colors.grey
                                                          : Colors.black,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        // Status ibadah belum dimulai
                                        if (isFuture)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              '⏰ Ibadah belum dimulai',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange.shade900,
                                              ),
                                              softWrap: true,
                                            ),
                                          ),

                                        // Status sudah absen
                                        if (sudahAbsen)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.check_circle,
                                                  size: 16,
                                                  color: Colors.green,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Kamu sudah absen",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        );
                      }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.brown.shade50,
        border: Border.all(color: Colors.brown.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  void _showNotStartedDialog(DateTime mulai) {
    final jamMulaiStr = DateFormat.Hm().format(mulai);
    final tanggalStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(mulai);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Ibadah Belum Dimulai'),
            content: Text(
              '⏰ Ibadah akan dimulai pada:\n\n$tanggalStr\nJam $jamMulaiStr',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }
}
