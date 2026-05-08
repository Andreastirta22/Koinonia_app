// check_profile.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'onboarding_profil.dart';
import 'package:koinonia/dashboard/warga_dashboard.dart';

class CheckProfilePage extends StatelessWidget {
  const CheckProfilePage({super.key});

  Future<bool> _isProfileComplete() async {
    final user = FirebaseAuth.instance.currentUser;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

    final data = doc.data();
    if (data == null) return false;

    // Periksa apakah field 'jenis_kelamin' sudah terisi
    return data['jenis_kelamin'] != null &&
        data['jenis_kelamin'].toString().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isProfileComplete(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return const WargaMainPage(); // Arahkan ke halaman utama jika profil lengkap
        } else {
          return const OnboardingProfil(); // Arahkan ke onboarding jika profil belum lengkap
        }
      },
    );
  }
}
