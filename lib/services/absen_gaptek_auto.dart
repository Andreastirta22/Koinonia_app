import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> tandaiHadirOtomatisUntukWargaGaptek(String jadwalId) async {
  final firestore = FirebaseFirestore.instance;

  final snapshot =
      await firestore
          .collection('users')
          .where('role', isEqualTo: 'warga')
          .where('gaptek', isEqualTo: true)
          .get();

  for (final doc in snapshot.docs) {
    final user = doc.data();
    final userId = doc.id;
    final nama = user['nama'];

    final existing =
        await firestore
            .collection('absensi')
            .where('jadwal_id', isEqualTo: jadwalId)
            .where('user_id', isEqualTo: userId)
            .get();

    if (existing.docs.isEmpty) {
      await firestore.collection('absensi').add({
        'jadwal_id': jadwalId,
        'user_id': userId,
        'nama': nama,
        'hadir': true,
        'otomatis_gaptek': true,
        'waktu': DateTime.now(),
      });
    }
  }
}
