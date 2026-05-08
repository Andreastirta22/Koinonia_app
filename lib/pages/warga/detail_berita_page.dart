import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:koinonia/pages/warga/daftar_penyumbang_page.dart';

class DetailBeritaPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const DetailBeritaPage({super.key, required this.data, required this.docId});

  @override
  State<DetailBeritaPage> createState() => _DetailBeritaPageState();
}

class _DetailBeritaPageState extends State<DetailBeritaPage> {
  String? uid;
  String? namaWarga;
  bool isSubmitting = false;
  bool sudahDaftar = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Menggabungkan getUserData dan cekSudahDaftar menjadi satu method
  Future<void> _initializeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      uid = prefs.getString('uid');
      namaWarga = prefs.getString('nama');

      if (uid != null) {
        await _cekSudahDaftar();
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
      if (mounted) {
        _showErrorMessage('Gagal memuat data. Silakan coba lagi.');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _cekSudahDaftar() async {
    if (uid == null) return;

    try {
      final existing =
          await FirebaseFirestore.instance
              .collection('sumbangan_berita')
              .where('berita_id', isEqualTo: widget.docId)
              .where('user_id', isEqualTo: uid)
              .limit(1) // Optimasi query
              .get();

      if (mounted) {
        setState(() {
          sudahDaftar = existing.docs.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error checking registration: $e');
    }
  }

  Future<void> _submitDaftar() async {
    // Validasi yang lebih comprehensive
    if (!_validateUserData()) return;

    setState(() => isSubmitting = true);

    try {
      // Cek lagi apakah sudah terdaftar (double check)
      await _cekSudahDaftar();
      if (sudahDaftar) {
        _showErrorMessage('Anda sudah terdaftar sebelumnya.');
        return;
      }

      await FirebaseFirestore.instance.collection('sumbangan_berita').add({
        'user_id': uid,
        'nama_warga': namaWarga,
        'berita_id': widget.docId,
        'tanggal_daftar': FieldValue.serverTimestamp(),
        'status': 'menunggu_penjualan',
      });

      if (mounted) {
        setState(() {
          sudahDaftar = true;
        });
        _showSuccessMessage('Pendaftaran berhasil!');
      }
    } catch (e) {
      debugPrint('Error submitting registration: $e');
      if (mounted) {
        _showErrorMessage('Gagal mendaftar. Silakan coba lagi.');
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  bool _validateUserData() {
    if (uid == null || uid!.isEmpty) {
      _showErrorMessage('Session tidak valid. Silakan login ulang.');
      return false;
    }

    if (namaWarga == null || namaWarga!.trim().isEmpty) {
      _showErrorMessage('Lengkapi profil Anda sebelum mendaftar.');
      return false;
    }

    return true;
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTanggal(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    try {
      final date = timestamp.toDate();
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return '-';
    }
  }

  void _showConfirmationDialog() {
    final tanggalKegiatan = _formatTanggal(
      widget.data['tanggal'] as Timestamp?,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Pendaftaran'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apakah Anda yakin ingin mendaftar untuk kegiatan ini?'),
                const SizedBox(height: 8),
                Text('Tanggal: $tanggalKegiatan'),
                Text('Nama: ${namaWarga ?? '-'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _submitDaftar();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ya, Daftar'),
              ),
            ],
          ),
    );
  }

  Widget _buildStatusInfo() {
    final status = widget.data['status'] ?? 'aktif';

    switch (status) {
      case 'tutup':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pendaftaran telah ditutup. ${widget.data['estimasi_selesai'] != null ? "Hasil akan diumumkan pada ${widget.data['estimasi_selesai']}." : "Pengurus sedang memproses data."}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        );

      case 'selesai':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kegiatan ini telah selesai. Terima kasih atas partisipasi Anda.',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDaftarButton() {
    final status = widget.data['status'] ?? 'aktif';
    if (status != 'aktif') return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Menyumbang',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (isSubmitting || sudahDaftar)
                        ? null
                        : _showConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: sudahDaftar ? Colors.grey : Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              sudahDaftar ? Icons.check : Icons.add,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              sudahDaftar
                                  ? 'Sudah Terdaftar'
                                  : 'Daftar Sumbangan',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Berita Kegiatan'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.brown),
              )
              : RefreshIndicator(
                onRefresh: _initializeData,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      // Header berita
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['judul'] ?? 'Judul tidak tersedia',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              if (data['tanggal'] != null) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatTanggal(
                                        data['tanggal'] as Timestamp,
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                              Text(
                                data['isi'] ?? 'Konten tidak tersedia',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status info
                      _buildStatusInfo(),
                      const SizedBox(height: 16),

                      // Form daftar
                      _buildDaftarButton(),
                      const SizedBox(height: 16),

                      // Tombol lihat daftar
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => DaftarPenyumbangPage(
                                    beritaId: widget.docId,
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.people, color: Colors.brown),
                        label: const Text(
                          'Lihat Daftar Penyumbang',
                          style: TextStyle(color: Colors.brown),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.brown),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
