import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dashboard/master_dashboard.dart';
import 'dashboard/pengurus_dashboard.dart';
import 'dashboard/warga_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool isLoading = false;

  late AnimationController _logoController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );
    _logoController.forward();

    checkLoginStatus();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    final role = prefs.getString('role');

    if (uid != null && role != null) {
      Widget nextPage;
      if (role == 'master') {
        nextPage = const MasterDashboard();
      } else if (role == 'pengurus') {
        nextPage = const PengurusDashboard();
      } else {
        nextPage = const WargaMainPage();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    }
  }

  Future<String?> getPublicIp() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.ipify.org?format=json'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ip'];
      }
    } catch (_) {}
    return null;
  }

  Future<void> login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      showSnackBar('Username dan password wajib diisi.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: username)
              .where('password', isEqualTo: password)
              .limit(1)
              .get();

      if (userSnapshot.docs.isNotEmpty) {
        final user = userSnapshot.docs.first;
        final role = user['role'];
        final uid = user.id;
        final nama = user['nama'] ?? '';

        if (nama.isEmpty) {
          showSnackBar('Profil Anda belum memiliki nama.');
          setState(() => isLoading = false);
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', uid);
        await prefs.setString('nama', nama);
        await prefs.setString('role', role);

        final ip = await getPublicIp();
        await FirebaseFirestore.instance.collection('log_login').add({
          'uid': uid,
          'role': role,
          'waktu': FieldValue.serverTimestamp(),
          'ip': ip,
        });

        Widget nextPage;
        if (role == 'master') {
          nextPage = const MasterDashboard();
        } else if (role == 'pengurus') {
          nextPage = const PengurusDashboard();
        } else {
          nextPage = const WargaMainPage();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextPage),
        );
      } else {
        showSnackBar('Username atau password salah.');
      }
    } catch (e) {
      showSnackBar('Terjadi kesalahan saat login.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.brown,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 600;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 500 : double.infinity,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox(
                        width: 160,
                        height: 160,
                        child: Image.asset('assets/images/login_logo.png'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'KOINONIA',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.brown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Lingkungan Theresia Jesus Jornet',
                      style: TextStyle(fontSize: 14, color: Colors.brown),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person),
                        labelText: 'Username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.brown,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      label:
                          isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Masuk',
                                style: TextStyle(fontSize: 16),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
