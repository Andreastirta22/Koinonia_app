import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InputKodeAbsenPage extends StatefulWidget {
  const InputKodeAbsenPage({super.key});

  @override
  State<InputKodeAbsenPage> createState() => _InputKodeAbsenPageState();
}

class _InputKodeAbsenPageState extends State<InputKodeAbsenPage> {
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  bool absenSelesai = false;
  bool isLoading = false;
  bool sudahLewat = false;
  String? nama;
  String? jenisKelamin;
  String? userId;
  String? pesan;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (snapshot.exists) {
      setState(() {
        userId = uid;
        nama = snapshot['nama'];
        jenisKelamin = snapshot['jenis_kelamin'];
      });
    }
  }

  /// 🔥 Fungsi update kehadiran_user (rekap bulanan)
  Future<void> updateRekapKehadiran(String userId) async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstDayNextMonth = DateTime(now.year, now.month + 1, 1);
    final yearMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    // Hitung total jadwal bulan ini
    final jadwalSnapshot =
        await FirebaseFirestore.instance
            .collection('jadwal_ibadah')
            .where('tanggal', isGreaterThanOrEqualTo: firstDayOfMonth)
            .where('tanggal', isLessThan: firstDayNextMonth)
            .get();
    final totalJadwal = jadwalSnapshot.size;

    // Hitung jumlah hadir user bulan ini
    final absensiSnapshot =
        await FirebaseFirestore.instance
            .collection('absensi')
            .where('user_id', isEqualTo: userId)
            .where('Waktu', isGreaterThanOrEqualTo: firstDayOfMonth)
            .where('Waktu', isLessThan: firstDayNextMonth)
            .get();
    final hadir = absensiSnapshot.size;

    final persentase =
        totalJadwal == 0 ? 0 : (hadir / totalJadwal * 100).round();

    // Update atau buat dokumen kehadiran_user
    await FirebaseFirestore.instance
        .collection('kehadiran_user')
        .doc("${userId}_$yearMonth")
        .set({
          'user_id': userId,
          'nama': nama,
          'bulan': yearMonth,
          'total_jadwal': totalJadwal,
          'hadir': hadir,
          'persentase': persentase,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _submitKodeAbsensi() async {
    final kodeInput = _controllers.map((e) => e.text.trim()).join();
    if (kodeInput.length < 4 || userId == null) return;

    setState(() {
      isLoading = true;
      pesan = null;
    });

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final besok = today.add(const Duration(days: 1));

      final jadwalSnapshot =
          await FirebaseFirestore.instance
              .collection('jadwal_ibadah')
              .where('tanggal', isGreaterThanOrEqualTo: today)
              .where('tanggal', isLessThan: besok)
              .where('kode_otp', isEqualTo: kodeInput)
              .get();

      if (jadwalSnapshot.docs.isEmpty) {
        setState(() {
          pesan = 'Kode tidak valid atau bukan untuk hari ini.';
        });
        return;
      }

      final jadwalId = jadwalSnapshot.docs.first.id;
      final data = jadwalSnapshot.docs.first.data();
      final validUntil = (data['valid_until'] as Timestamp?)?.toDate();

      if (validUntil != null && DateTime.now().isAfter(validUntil)) {
        setState(() {
          pesan = 'Waktu absensi sudah berakhir.';
          sudahLewat = true;
        });
        return;
      }

      final absenSnapshot =
          await FirebaseFirestore.instance
              .collection('absensi')
              .where('jadwal_id', isEqualTo: jadwalId)
              .where('user_id', isEqualTo: userId)
              .get();

      if (absenSnapshot.docs.isNotEmpty) {
        setState(() {
          pesan = 'Kamu sudah absen hari ini.';
        });
        return;
      }

      // ✅ Simpan absensi
      await FirebaseFirestore.instance.collection('absensi').add({
        'user_id': userId,
        'jadwal_id': jadwalId,
        'nama': nama,
        'Waktu': FieldValue.serverTimestamp(),
        'status_kehadiran': 'Hadir',
      });

      // ✅ Update rekap otomatis
      await updateRekapKehadiran(userId!);

      setState(() {
        absenSelesai = true;
        final sapaan = jenisKelamin == 'laki-laki' ? 'Pak' : 'Bu';
        pesan = 'Anda sudah berhasil absen, $sapaan $nama';
      });
    } catch (e) {
      setState(() {
        pesan = 'Terjadi kesalahan. Silakan coba lagi.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          width: 50,
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              maxLength: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                if (val.isNotEmpty) {
                  if (index < 3) {
                    _focusNodes[index + 1].requestFocus();
                  } else {
                    _focusNodes[index].unfocus();
                  }
                } else if (val.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }
              },
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi dengan Kode'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!absenSelesai && !sudahLewat) ...[
                  const Text(
                    'Masukkan Kode OTP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  buildOtpInput(),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submitKodeAbsensi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Absen Sekarang',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                ] else if (sudahLewat) ...[
                  const Icon(Icons.schedule, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Waktu absensi sudah berakhir.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (pesan != null) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        absenSelesai ? Icons.check_circle : Icons.error,
                        color: absenSelesai ? Colors.green : Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pesan!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: absenSelesai ? Colors.green : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
