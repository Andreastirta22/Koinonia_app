import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:koinonia/dashboard/warga_dashboard.dart';

class OnboardingProfil extends StatefulWidget {
  const OnboardingProfil({super.key});

  @override
  State<OnboardingProfil> createState() => _OnboardingProfilState();
}

class _OnboardingProfilState extends State<OnboardingProfil> {
  String? _jenisKelamin;

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'jenis_kelamin': _jenisKelamin,
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WargaMainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lengkapi Profil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Pilih Jenis Kelamin Anda:"),
            DropdownButton<String>(
              value: _jenisKelamin,
              items: const [
                DropdownMenuItem(value: "L", child: Text("Laki-laki")),
                DropdownMenuItem(value: "P", child: Text("Perempuan")),
              ],
              onChanged: (val) {
                setState(() => _jenisKelamin = val);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _jenisKelamin == null ? null : _saveProfile,
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }
}
