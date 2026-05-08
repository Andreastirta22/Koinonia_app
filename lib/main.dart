import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';

// Login
import 'login_page.dart';

// Pages Warga
import 'pages/warga/detail_keuangan_page.dart';
import 'pages/warga/absensi_page.dart';
import 'pages/warga/jadwal_ibadah_page.dart';
import 'pages/warga/input_kode_absen_page.dart';
import 'pages/warga/riwayat_absensi_warga_page.dart';
import 'pages/warga/berita_acara_page.dart';
import 'package:koinonia/pages/warga/detail_berita_page.dart';
import 'package:koinonia/pages/warga/notifikasi_page.dart';

// Pages Pengurus
import 'pages/pengurus/tambah_keuangan_page.dart';
import 'pages/pengurus/daftar_keuangan_page.dart';
import 'pages/pengurus/tambah_jadwal_ibadah_page.dart';
import 'pages/pengurus/daftar_jadwal_ibadah.dart';
import 'pages/pengurus/pengurus_jadwal_ibadah_page.dart';
import 'pages/pengurus/rekap_absensi_pengurus_page.dart';
import 'pages/pengurus/form_berita_pengurus.dart';
import 'pages/pengurus/kelola_berita_pengurus_page.dart';
import 'package:koinonia/pages/pengurus/form_trivia_pengurus.dart';

// Pages Master
import 'pages/master/buat_revoke_otp_page.dart';
import 'pages/master/laporan_statistik_page.dart';
import 'pages/master/pengaturan_master_page.dart';
import 'pages/master/kelola_absensi_warga_page.dart';

import 'pages/not_found_page.dart';
import 'pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);

  runApp(const KoinoniaApp());
}

class KoinoniaApp extends StatelessWidget {
  const KoinoniaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koinonia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFFDFBF5),
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.light,
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('id', 'ID'),
      home: const SplashScreen(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/detail-keuangan':
        return MaterialPageRoute(builder: (_) => const DetailKeuanganPage());
      case '/absensi':
        return MaterialPageRoute(builder: (_) => const AbsensiPage());
      case '/jadwal-ibadah':
        return MaterialPageRoute(builder: (_) => const JadwalIbadahPage());
      case '/input-kode':
        return MaterialPageRoute(builder: (_) => const InputKodeAbsenPage());
      case '/riwayat-absensi':
        return MaterialPageRoute(
          builder: (_) => const RiwayatAbsensiWargaPage(),
        );
      case '/tambah-keuangan':
        return MaterialPageRoute(builder: (_) => const TambahKeuanganPage());
      case '/daftar-keuangan':
        return MaterialPageRoute(builder: (_) => const DaftarKeuanganPage());
      case '/tambah-jadwal':
        return MaterialPageRoute(
          builder: (_) => const TambahJadwalIbadahPage(),
        );
      case '/daftar-jadwal':
        return MaterialPageRoute(
          builder: (_) => const DaftarJadwalIbadahPage(),
        );
      case '/jadwal-ibadah-pengurus':
        return MaterialPageRoute(
          builder: (_) => const PengurusJadwalIbadahPage(),
        );
      case '/rekap-absensi':
        return MaterialPageRoute(
          builder: (_) => const RekapAbsensiPengurusPage(),
        );
      case '/kelola-otp':
        return MaterialPageRoute(builder: (_) => const BuatRevokeOtpPage());
      case '/pengaturan-master':
        return MaterialPageRoute(builder: (_) => const PengaturanMasterPage());
      case '/laporan-statistik':
        return MaterialPageRoute(builder: (_) => const LaporanStatistikPage());
      case '/kelola-absensi-warga':
        return MaterialPageRoute(
          builder: (_) => const KelolaAbsensiWargaPage(),
        );
      case '/kelola-berita':
        return MaterialPageRoute(builder: (_) => const FormBeritaPengurus());
      case '/form-trivia':
        return MaterialPageRoute(builder: (_) => const TriviaPengurusPage());
      case '/notifikasi':
        return MaterialPageRoute(builder: (_) => const NotifikasiPage());
      case '/detail-berita':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder:
              (_) => DetailBeritaPage(data: args['data'], docId: args['docId']),
        );
      case '/kelola-berita-pengurus':
        return MaterialPageRoute(
          builder: (_) => const KelolaBeritaPengurusPage(),
        );
      case '/berita-warga':
        return MaterialPageRoute(builder: (_) => const BeritaWargaPage());
      default:
        return MaterialPageRoute(builder: (_) => const NotFoundPage());
    }
  }
}
