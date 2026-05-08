import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DaftarKeuanganWargaPage extends StatefulWidget {
  const DaftarKeuanganWargaPage({super.key});

  @override
  State<DaftarKeuanganWargaPage> createState() =>
      _DaftarKeuanganWargaPageState();
}

class _DaftarKeuanganWargaPageState extends State<DaftarKeuanganWargaPage>
    with TickerProviderStateMixin {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final dateFormatter = DateFormat('dd MMMM yyyy', 'id_ID');

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
        title: const Text('Keuangan Lingkungan'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showSummary ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showSummary = !_showSummary),
            tooltip: 'Tampilkan Ringkasan',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
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
              ),
            ),
          ),

          // Filter Chips
          if (_dateRange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Chip(
                label: Text(
                  '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}',
                ),
                onDeleted: () => setState(() => _dateRange = null),
                deleteIcon: const Icon(Icons.close, size: 18),
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
          final kategori = doc['kategori'] ?? '';
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Pemasukan',
                              style: TextStyle(color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyFormatter.format(totalPemasukan),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Pengeluaran',
                              style: TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyFormatter.format(totalPengeluaran),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
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

  Widget _buildTransactionList(String filterType) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('keuangan')
              .orderBy('tanggal', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allData = snapshot.data?.docs ?? [];
        final filteredData = _filterTransactions(allData, filterType);

        if (filteredData.isEmpty) {
          return _buildEmptyState(filterType);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredData.length,
          itemBuilder: (context, index) {
            final data = filteredData[index].data() as Map<String, dynamic>;

            final tanggal =
                data['tanggal'] != null
                    ? (data['tanggal'] as Timestamp).toDate()
                    : DateTime.now();
            final jumlah = data['jumlah'] ?? 0;
            final kategori = data['kategori'] ?? '';
            final keterangan = data['keterangan'] ?? '';
            final isPemasukan = kategori == 'Pemasukan';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      keterangan.isNotEmpty
                          ? keterangan
                          : 'Tidak ada keterangan',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormatter.format(tanggal),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          kategori,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPemasukan ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          currencyFormatter.format(jumlah),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPemasukan ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
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

  Widget _buildEmptyState(String filterType) {
    String message;
    switch (filterType) {
      case 'Pemasukan':
        message = 'Belum ada pemasukan';
        break;
      case 'Pengeluaran':
        message = 'Belum ada pengeluaran';
        break;
      default:
        message = 'Belum ada data keuangan';
    }
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
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

      if (tabFilter != null && tabFilter != 'Semua' && kategori != tabFilter) {
        return false;
      }

      if (_dateRange != null) {
        if (tanggal.isBefore(_dateRange!.start) ||
            tanggal.isAfter(_dateRange!.end)) {
          return false;
        }
      }

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
      setState(() => _dateRange = picked);
    }
  }
}
