import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:koinonia/login_page.dart';

class PengaturanMasterPage extends StatefulWidget {
  const PengaturanMasterPage({super.key});

  @override
  State<PengaturanMasterPage> createState() => _PengaturanMasterPageState();
}

class _PengaturanMasterPageState extends State<PengaturanMasterPage> {
  String? masterName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMasterInfo();
  }

  Future<void> _loadMasterInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        masterName = doc['nama'] ?? 'Master';
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Master'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Halo, $masterName 👋',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Pengaturan Akun',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock_reset),
                    title: const Text('Ganti Password'),
                    onTap: () {
                      // TODO: navigasi ke halaman ganti password
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Backup Data'),
                    onTap: () {
                      // TODO: fitur backup ke cloud
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Sinkronisasi Data'),
                    onTap: () {
                      // TODO: fitur sync data
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Lainnya',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: _logout,
                  ),
                ],
              ),
    );
  }
}
