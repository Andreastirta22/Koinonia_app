import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DaftarKeuanganPage extends StatefulWidget {
  const DaftarKeuanganPage({super.key});

  @override
  State<DaftarKeuanganPage> createState() => _DaftarKeuanganPageState();
}

class _DaftarKeuanganPageState extends State<DaftarKeuanganPage>
    with TickerProviderStateMixin {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final dateFormatter = DateFormat('dd MMMM yyyy', 'id_ID');

  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  bool _showSummary = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Keuangan'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showSummary ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showSummary = !_showSummary),
            tooltip: 'Toggle Summary',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 8),
                        Text('Export Laporan'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Pemasukan'),
            Tab(text: 'Pengeluaran'),
          ],
        ),
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
                hintText: 'Cari transaksi...',
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
          if (_dateRange != null || _selectedFilter != 'Semua')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_dateRange != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(
                            '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}',
                          ),
                          onDeleted: () => setState(() => _dateRange = null),
                          deleteIcon: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    if (_selectedFilter != 'Semua')
                      Chip(
                        label: Text(_selectedFilter),
                        onDeleted:
                            () => setState(() => _selectedFilter = 'Semua'),
                        deleteIcon: const Icon(Icons.close, size: 18),
                      ),
                  ],
                ),
              ),
            ),

          // Summary Cards
          if (_showSummary) _buildSummarySection(),

          // Transaction List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList('Semua'),
                _buildTransactionList('Pemasukan'),
                _buildTransactionList('Pengeluaran'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('keuangan').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data!.docs;
        final filteredData = _filterTransactions(data);

        double totalPemasukan = 0;
        double totalPengeluaran = 0;

        for (var doc in filteredData) {
          final jumlah = doc['jumlah'] ?? 0;
          final kategori = doc['kategori'];

          if (kategori == 'Pemasukan') {
            totalPemasukan += jumlah;
          } else {
            totalPengeluaran += jumlah;
          }
        }

        final saldo = totalPemasukan - totalPengeluaran;

        return Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Main Balance Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.brown, Colors.brown.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Saldo Saat Ini',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormatter.format(saldo),
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
                            child: _buildQuickStat(
                              'Total Transaksi',
                              filteredData.length.toString(),
                              Icons.receipt_long,
                              Colors.white70,
                            ),
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.white30,
                          ),
                          Expanded(
                            child: _buildQuickStat(
                              'Rata-rata/Hari',
                              currencyFormatter.format(
                                filteredData.isNotEmpty
                                    ? (totalPemasukan + totalPengeluaran) / 30
                                    : 0,
                              ),
                              Icons.trending_up,
                              Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Income/Expense Cards
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_downward,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Pemasukan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currencyFormatter.format(totalPemasukan),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Pengeluaran',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currencyFormatter.format(totalPengeluaran),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionList(String filterType) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('keuangan')
              .orderBy('tanggal', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Terjadi kesalahan'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allData = snapshot.data?.docs ?? [];
        final filteredData = _filterTransactions(allData, filterType);

        if (filteredData.isEmpty) {
          return _buildEmptyState(filterType);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredData.length,
            itemBuilder: (context, index) {
              final item = filteredData[index];
              final data = item.data() as Map<String, dynamic>;

              final tanggal =
                  data['tanggal'] != null
                      ? (data['tanggal'] as Timestamp).toDate()
                      : DateTime.now();
              final jumlah = data['jumlah'] ?? 0;
              final kategori = data['kategori'] ?? '';
              final keterangan = data['keterangan'] ?? '';
              final isPemasukan = kategori == 'Pemasukan';

              return _buildTransactionCard(
                tanggal,
                jumlah,
                kategori,
                keterangan,
                isPemasukan,
                item.id,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionCard(
    DateTime tanggal,
    num jumlah,
    String kategori,
    String keterangan,
    bool isPemasukan,
    String docId,
  ) {
    final isToday =
        DateFormat('yyyy-MM-dd').format(tanggal) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap:
            () => _showTransactionDetail(
              docId,
              tanggal,
              jumlah,
              kategori,
              keterangan,
            ),
        onLongPress: () => _showTransactionOptions(docId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isPemasukan
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPemasukan ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isPemasukan ? Colors.green : Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            keterangan.isNotEmpty
                                ? keterangan
                                : 'Tidak ada keterangan',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isPemasukan
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            kategori,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isPemasukan ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormatter.format(tanggal),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Hari ini',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          currencyFormatter.format(jumlah),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isPemasukan ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String filterType) {
    String message;
    IconData icon;

    switch (filterType) {
      case 'Pemasukan':
        message = 'Belum ada pemasukan';
        icon = Icons.arrow_downward;
        break;
      case 'Pengeluaran':
        message = 'Belum ada pengeluaran';
        icon = Icons.arrow_upward;
        break;
      default:
        message = 'Belum ada data keuangan';
        icon = Icons.account_balance_wallet;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambah transaksi pertama Anda',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterTransactions(
    List<QueryDocumentSnapshot> data, [
    String? tabFilter,
  ]) {
    return data.where((doc) {
      final docData = doc.data() as Map<String, dynamic>;
      final kategori = docData['kategori'] ?? '';
      final keterangan = docData['keterangan'] ?? '';
      final tanggal =
          docData['tanggal'] != null
              ? (docData['tanggal'] as Timestamp).toDate()
              : DateTime.now();

      // Tab filter
      if (tabFilter != null && tabFilter != 'Semua' && kategori != tabFilter) {
        return false;
      }

      // Date range filter
      if (_dateRange != null) {
        if (tanggal.isBefore(_dateRange!.start) ||
            tanggal.isAfter(_dateRange!.end)) {
          return false;
        }
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        return keterangan.toLowerCase().contains(_searchQuery) ||
            kategori.toLowerCase().contains(_searchQuery);
      }

      return true;
    }).toList();
  }

  void _showFilterDialog() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _showTransactionDetail(
    String docId,
    DateTime tanggal,
    num jumlah,
    String kategori,
    String keterangan,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detail Transaksi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Kategori', kategori),
                _buildDetailRow('Jumlah', currencyFormatter.format(jumlah)),
                _buildDetailRow('Tanggal', dateFormatter.format(tanggal)),
                _buildDetailRow(
                  'Keterangan',
                  keterangan.isNotEmpty ? keterangan : 'Tidak ada keterangan',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _editTransaction(docId);
                },
                child: const Text('Edit'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showTransactionOptions(String docId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Aksi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit Transaksi'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _editTransaction(docId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Hapus Transaksi'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteTransaction(docId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.green),
                  title: const Text('Bagikan'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareTransaction(docId);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportData();
        break;
    }
  }

  void _editTransaction(String docId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('keuangan')
            .doc(docId)
            .get();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormKeuanganPage(docId: docId, data: doc),
      ),
    );
  }

  void _deleteTransaction(String docId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Transaksi'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus transaksi ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('keuangan')
                        .doc(docId)
                        .delete();

                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaksi berhasil dihapus'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal hapus: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }

  void _shareTransaction(String docId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur berbagi akan segera tersedia'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportData() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('keuangan')
            .orderBy('tanggal', descending: true)
            .get();

    final data =
        snapshot.docs
            .map((doc) => doc.data())
            .toList(); // Hapus 'as Map<String, dynamic>'

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Laporan Keuangan',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  headers: ['Tanggal', 'Kategori', 'Keterangan', 'Jumlah'],
                  data:
                      data.map((item) {
                        final tanggal = (item['tanggal'] as Timestamp).toDate();
                        final kategori = item['kategori'] ?? '';
                        final keterangan = item['keterangan'] ?? '';
                        final jumlah = item['jumlah'] ?? 0;
                        return [
                          DateFormat('dd/MM/yyyy').format(tanggal),
                          kategori,
                          keterangan,
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(jumlah),
                        ];
                      }).toList(),
                ),
              ],
            ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}

class FormKeuanganPage extends StatefulWidget {
  final String? docId; // null kalau tambah
  final DocumentSnapshot? data;

  const FormKeuanganPage({Key? key, this.docId, this.data}) : super(key: key);

  @override
  _FormKeuanganPageState createState() => _FormKeuanganPageState();
}

class _FormKeuanganPageState extends State<FormKeuanganPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  String _kategori = "Pemasukan"; // default
  DateTime _tanggal = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      final data = widget.data!.data() as Map<String, dynamic>;
      _judulController.text = data['judul'] ?? '';
      _jumlahController.text = data['jumlah'].toString();
      _kategori = data['kategori'] ?? 'Pemasukan';
      _tanggal = (data['tanggal'] as Timestamp).toDate();
    }
  }

  Future<void> _simpanData() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      "judul": _judulController.text,
      "jumlah": int.tryParse(_jumlahController.text) ?? 0,
      "kategori": _kategori,
      "tanggal": Timestamp.fromDate(_tanggal),
    };

    if (widget.docId == null) {
      // Tambah transaksi baru
      await FirebaseFirestore.instance.collection("keuangan").add(data);
    } else {
      // Update transaksi lama
      await FirebaseFirestore.instance
          .collection("keuangan")
          .doc(widget.docId)
          .update(data);
    }

    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _tanggal = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Transaksi" : "Tambah Transaksi"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _judulController,
                    decoration: InputDecoration(
                      labelText: "Judul",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? "Wajib diisi"
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _jumlahController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Jumlah",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.money),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? "Wajib diisi"
                                : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _kategori,
                    items:
                        ["Pemasukan", "Pengeluaran"]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => _kategori = val!),
                    decoration: InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Tanggal",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.date_range),
                      ),
                      child: Text(DateFormat("dd MMM yyyy").format(_tanggal)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEdit ? Colors.orange : Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _simpanData,
                      icon: Icon(isEdit ? Icons.update : Icons.save),
                      label: Text(
                        isEdit ? "Update Transaksi" : "Simpan Transaksi",
                        style: const TextStyle(fontSize: 16),
                      ),
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
