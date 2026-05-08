// 📄 IMPROVED NOTIFIKASI PAGE
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:async/async.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:koinonia/pages/warga/daftar_penyumbang_page.dart';

class NotifikasiPage extends StatelessWidget {
  const NotifikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tandai Semua Sudah Dibaca',
            onPressed: () async {
              await _markAllAsRead(context);
            },
          ),
        ],
      ),
      body: const _GabunganNotifikasiTab(),
    );
  }
}

Future<void> _markAllAsRead(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final allNotifications = prefs.getStringList('unread_notifications') ?? [];

  if (allNotifications.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi sudah dibaca.'),
        backgroundColor: Colors.green,
      ),
    );
    return;
  }

  await prefs.setStringList('unread_notifications', []);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Semua notifikasi telah ditandai sudah dibaca.'),
      backgroundColor: Colors.green,
    ),
  );
}

class _GabunganNotifikasiTab extends StatefulWidget {
  const _GabunganNotifikasiTab();

  @override
  State<_GabunganNotifikasiTab> createState() => _GabunganNotifikasiTabState();
}

enum NotificationFilter { semua, berita, keuangan }

class _GabunganNotifikasiTabState extends State<_GabunganNotifikasiTab> {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  final dateTimeFormat = DateFormat('EEEE, dd MMM yyyy – HH:mm', 'id_ID');

  NotificationFilter _selectedFilter = NotificationFilter.semua;
  Set<String> _unreadNotifications = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnreadStatus();
  }

  Future<void> _loadUnreadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final unread = prefs.getStringList('unread_notifications') ?? [];
    setState(() {
      _unreadNotifications = unread.toSet();
      _isLoading = false;
    });
  }

  Future<void> _toggleReadStatus(String notificationId, bool isRead) async {
    final prefs = await SharedPreferences.getInstance();
    final unread = prefs.getStringList('unread_notifications') ?? [];
    final updatedUnread = unread.toSet();
    if (isRead) {
      updatedUnread.remove(notificationId);
    } else {
      updatedUnread.add(notificationId);
    }
    await prefs.setStringList('unread_notifications', updatedUnread.toList());
    setState(() {
      _unreadNotifications = updatedUnread;
    });
  }

  Future<void> _deleteNotification(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final unread = prefs.getStringList('unread_notifications') ?? [];
    final updatedUnread = unread.toSet();
    updatedUnread.remove(notificationId);
    await prefs.setStringList('unread_notifications', updatedUnread.toList());
    setState(() {
      _unreadNotifications = updatedUnread;
    });
    // In a real app, you would also delete from Firestore.
  }

  DateTime convertToDate(dynamic waktu) {
    if (waktu is Timestamp) return waktu.toDate();
    if (waktu is DateTime) return waktu;
    return DateTime(2000);
  }

  String _getGroupHeader(DateTime waktu) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final aWeekAgo = today.subtract(const Duration(days: 7));
    final aMonthAgo = today.subtract(const Duration(days: 30));

    final date = DateTime(waktu.year, waktu.month, waktu.day);

    if (date.isAtSameMomentAs(today)) return 'Hari Ini';
    if (date.isAtSameMomentAs(yesterday)) return 'Kemarin';
    if (date.isAfter(aWeekAgo)) return 'Minggu Ini';
    if (date.isAfter(aMonthAgo)) return 'Bulan Ini';
    return 'Lebih Lama';
  }

  List<Map<String, dynamic>> _filterNotifications(
    List<Map<String, dynamic>> notifications,
  ) {
    switch (_selectedFilter) {
      case NotificationFilter.semua:
        return notifications;
      case NotificationFilter.berita:
        return notifications
            .where(
              (item) =>
                  item['type'] == 'berita_baru' ||
                  item['type'] == 'berita_selesai',
            )
            .toList();
      case NotificationFilter.keuangan:
        return notifications
            .where((item) => item['type'] == 'keuangan')
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final beritaAktifStream =
        FirebaseFirestore.instance
            .collection('berita')
            .where('status', isEqualTo: 'aktif')
            .orderBy('dibuat_pada', descending: true)
            .snapshots();

    final beritaSelesaiStream =
        FirebaseFirestore.instance
            .collection('berita')
            .where('status', isEqualTo: 'selesai')
            .orderBy('tanggal_selesai', descending: true)
            .snapshots();

    final keuanganStream =
        FirebaseFirestore.instance
            .collection('keuangan')
            .orderBy('created_at', descending: true)
            .snapshots();

    return StreamBuilder<List<QuerySnapshot>>(
      stream: StreamZip([
        beritaAktifStream,
        beritaSelesaiStream,
        keuanganStream,
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (_isLoading || !snapshot.hasData) {
          return const _ShimmerLoading();
        }

        final allDocs = [
          ...snapshot.data![0].docs.map(
            (doc) => {
              'id': doc.id,
              'docId': doc.id,
              'type': 'berita_baru',
              'data': doc.data(),
              'waktu':
                  (doc.data() as Map<String, dynamic>)['dibuat_pada'] ??
                  Timestamp.now(),
            },
          ),
          ...snapshot.data![1].docs.map(
            (doc) => {
              'id': doc.id,
              'docId': doc.id,
              'type': 'berita_selesai',
              'data': doc.data(),
              'waktu':
                  (doc.data() as Map<String, dynamic>)['tanggal_selesai'] ??
                  Timestamp.now(),
            },
          ),

          ...snapshot.data![2].docs.map(
            (doc) => {
              'id': const Uuid().v4(), // Use a unique ID for each item
              'type': 'keuangan',
              'data': doc.data(),
              'waktu':
                  (doc.data() as Map<String, dynamic>)['created_at'] ??
                  Timestamp.now(),
            },
          ),
        ];

        allDocs.sort(
          (a, b) =>
              convertToDate(b['waktu']).compareTo(convertToDate(a['waktu'])),
        );

        final filteredDocs = _filterNotifications(allDocs);

        if (filteredDocs.isEmpty) {
          return const _EmptyNotificationState();
        }

        return Column(
          children: [
            _buildFilterButtons(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadUnreadStatus,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final item = filteredDocs[index];
                    final type = item['type'];
                    final waktu = convertToDate(item['waktu']);
                    final id = item['id'] as String;
                    final isRead = !_unreadNotifications.contains(id);

                    final showHeader =
                        index == 0 ||
                        _getGroupHeader(waktu) !=
                            _getGroupHeader(
                              convertToDate(filteredDocs[index - 1]['waktu']),
                            );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader)
                          _buildGroupHeader(_getGroupHeader(waktu)),
                        _buildNotifItem(context, item, type, id, isRead, waktu),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterChip('Semua', NotificationFilter.semua),
          _buildFilterChip('Berita', NotificationFilter.berita),
          _buildFilterChip('Keuangan', NotificationFilter.keuangan),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, NotificationFilter filter) {
    final isSelected = _selectedFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        }
      },
      selectedColor: Colors.brown.shade100,
      checkmarkColor: Colors.brown,
      labelStyle: TextStyle(
        color: isSelected ? Colors.brown : Colors.grey[700],
      ),
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildNotifItem(
    BuildContext context,
    Map<String, dynamic> item,
    String type,
    String id,
    bool isRead,
    DateTime waktu,
  ) {
    final waktuFormatted = dateTimeFormat.format(waktu);
    final data = item['data'] as Map<String, dynamic>;

    Widget cardContent;

    if (type == 'berita_baru' || type == 'berita_selesai') {
      final title = data['judul'] ?? '-';
      final isi = data['isi'] ?? '-';
      final docId = item['docId'] ?? ''; // This variable is now used

      cardContent = NotifikasiCard(
        icon: Icons.campaign,
        iconColor: Colors.deepOrange,
        title: title,
        subtitle: type == 'berita_baru' ? isi : 'Kegiatan telah selesai.',
        timestamp: waktuFormatted,
        isRead: isRead,
        onTap: () async {
          await _toggleReadStatus(id, true);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DaftarPenyumbangPage(beritaId: docId),
            ),
          );
        },
      );
    } else if (type == 'keuangan') {
      final jumlah = data['jumlah'] ?? 0;
      final kategori = data['kategori'] ?? '';
      final keterangan = data['keterangan'] ?? '-';
      final sumber = data['sumber_dana'] ?? '-';
      final isPemasukan = kategori == 'Pemasukan';

      cardContent = NotifikasiCard(
        icon: isPemasukan ? Icons.arrow_downward : Icons.arrow_upward,
        iconColor: isPemasukan ? Colors.green : Colors.red,
        title:
            '${isPemasukan ? 'Pemasukan' : 'Pengeluaran'}: ${formatter.format(jumlah)}',
        subtitle: '$keterangan\nSumber: $sumber',
        timestamp: waktuFormatted,
        isRead: isRead,
        onTap: () async {
          await _toggleReadStatus(id, true);
        },
      );
    } else {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: Key(id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.done, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _toggleReadStatus(id, true);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          final confirm = await showDialog(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: const Text('Konfirmasi'),
                  content: const Text(
                    'Apakah Anda yakin ingin menghapus notifikasi ini?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
          );
          if (confirm == true) {
            await _deleteNotification(id);
          }
          return confirm;
        }
        return false;
      },
      child: cardContent,
    );
  }
}

class NotifikasiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String timestamp;
  final bool isRead;
  final VoidCallback? onTap;

  const NotifikasiCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.isRead = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = isRead ? Colors.white : Colors.brown.shade50;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.brown.shade100,
            width: isRead ? 0 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot indicator for unread notifications
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(right: 8, top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timestamp,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder:
            (context, index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 40, height: 40, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Container(width: 100, height: 12, color: Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'Tidak ada notifikasi untuk saat ini.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cek kembali nanti untuk update terbaru.',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
