import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class TambahJadwalIbadahPage extends StatefulWidget {
  const TambahJadwalIbadahPage({super.key});

  @override
  State<TambahJadwalIbadahPage> createState() => _TambahJadwalIbadahPageState();
}

class _TambahJadwalIbadahPageState extends State<TambahJadwalIbadahPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _tanggal;
  TimeOfDay? _waktuMulai;
  TimeOfDay? _waktuSelesai;
  String? _selectedTempat;
  String? _selectedKategori;

  final List<String> _listKategori = [
    'Ibadah Rutin',
    'Misa Lingkungan',
    'Misa Arwah',
  ];

  List<String> _listTempat = [];

  @override
  void initState() {
    super.initState();
    _fetchTempatKepalaKeluarga();
  }

  void _fetchTempatKepalaKeluarga() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'warga')
            .where('is_kepala_keluarga', isEqualTo: true)
            .get();

    final tempat = snapshot.docs.map((doc) => doc['nama'] as String).toList();
    setState(() => _listTempat = tempat);
  }

  String _generateOtp() {
    final random = Random.secure();
    return List.generate(4, (index) => random.nextInt(10)).join();
  }

  Future<void> _simpanJadwal() async {
    if (!_formKey.currentState!.validate() ||
        _tanggal == null ||
        _waktuMulai == null ||
        _waktuSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field terlebih dahulu')),
      );
      return;
    }

    final mulai = DateTime(
      _tanggal!.year,
      _tanggal!.month,
      _tanggal!.day,
      _waktuMulai!.hour,
      _waktuMulai!.minute,
    );

    final selesai = DateTime(
      _tanggal!.year,
      _tanggal!.month,
      _tanggal!.day,
      _waktuSelesai!.hour,
      _waktuSelesai!.minute,
    );

    if (selesai.isBefore(mulai)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu selesai tidak boleh sebelum waktu mulai'),
        ),
      );
      return;
    }

    final kodeOtp = _generateOtp();

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('jadwal_ibadah')
          .add({
            'tanggal': Timestamp.fromDate(mulai),
            'valid_until': Timestamp.fromDate(selesai),
            'tempat': _selectedTempat ?? '',
            'kategori': _selectedKategori ?? '',
            'kode_otp': kodeOtp,
            'created_at': FieldValue.serverTimestamp(),
          });

      final jadwalId = docRef.id;

      // Absensi otomatis untuk warga gaptek
      final wargaGaptekSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'warga')
              .where('gaptek', isEqualTo: true)
              .get();

      for (var doc in wargaGaptekSnapshot.docs) {
        await FirebaseFirestore.instance.collection('absensi').add({
          'jadwal_id': jadwalId,
          'user_id': doc.id,
          'waktu': Timestamp.now(),
          'metode': 'gaptek_otomatis',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil ditambahkan')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menambahkan jadwal: $e')));
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime:
          isStart ? TimeOfDay.now() : const TimeOfDay(hour: 21, minute: 0),
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          _waktuMulai = time;
        } else {
          _waktuSelesai = time;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Jadwal Ibadah'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Tanggal Ibadah'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 5),
                    locale: const Locale('id', 'ID'),
                  );
                  if (picked != null) {
                    setState(() => _tanggal = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _tanggal == null
                        ? 'Pilih tanggal'
                        : '${_tanggal!.day}-${_tanggal!.month}-${_tanggal!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Waktu Mulai'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectTime(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _waktuMulai == null
                        ? 'Pilih Waktu Mulai'
                        : _waktuMulai!.format(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Waktu Selesai'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectTime(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _waktuSelesai == null
                        ? 'Pilih Waktu Selesai'
                        : _waktuSelesai!.format(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTempat,
                items:
                    _listTempat
                        .map(
                          (nama) =>
                              DropdownMenuItem(value: nama, child: Text(nama)),
                        )
                        .toList(),
                decoration: const InputDecoration(
                  labelText: 'Tempat Ibadah (Kepala Keluarga)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _selectedTempat = value),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Pilih tempat ibadah'
                            : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                items:
                    _listKategori
                        .map(
                          (kategori) => DropdownMenuItem(
                            value: kategori,
                            child: Text(kategori),
                          ),
                        )
                        .toList(),
                decoration: const InputDecoration(
                  labelText: 'Kategori Ibadah',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _selectedKategori = value),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Pilih kategori ibadah'
                            : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _simpanJadwal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Simpan Jadwal',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
