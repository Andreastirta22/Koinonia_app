import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firestore = FirebaseFirestore.instance;

  final usersSnapshot = await firestore.collection('users').get();

  for (final doc in usersSnapshot.docs) {
    final data = doc.data();
    final password = data['password'] ?? '';
    if (password.isEmpty) continue;

    final hashed = sha256.convert(utf8.encode(password)).toString();
    await doc.reference.update({'password': hashed});
    print('Updated user ${doc.id}');
  }

  print('Migration selesai!');
}
